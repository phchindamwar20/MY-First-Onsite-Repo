/**
 * @description       : This is the template class basis for the Bolt=>SF web service 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-15-2024
 * @last modified by  : Terri Jiles
**/
public virtual class RecordManagerTemplate {
    public enum Operation {O_INSERT, O_UPDATE, O_UPSERT, O_DELETE}
    private static Integer retry=0;
    private static String SOBJECT_TYPE = 'SObject';
    private static String LIST_SOBJECT_TYPE = 'List_SObject';

    public static void createRecord(String methodName, String apexClass) {
        send(methodName, Operation.O_INSERT, apexClass);
    }

    public static void updateRecord( String methodName, String apexClass) {
        send(methodName, Operation.O_UPDATE, apexClass);
    }

    //STAR-3314
    public static void upsertRecord(String methodName, String apexClass) {
        send(methodName, Operation.O_UPSERT, apexClass);
    }

    public static void updateRecordList( String methodName, String apexClass) {
        sendList(methodName, Operation.O_UPDATE, apexClass);
    }

    private static void send(String methodName, Operation thisOperation, String apexClass) {
        String integrationDirection = BoltConstants.BOLT_TO_SF;
        RestRequest recordRequest = RestContext.request;
        RestResponse recordResponse = RestContext.response;
        Set<Id> ids = new Set<Id>();
        SObject record = null;
        Boolean isIntegrationOff=BoltService.turnOffIntegration(integrationDirection, methodName);
        String requestBody = recordRequest.requestBody.toString();
        String objectApiName = BoltService.getObjectApiName(integrationDirection, methodName, false);

        //System.debug('~~~~ RecordManagerTemplate::send: integrationDirection - ' + integrationDirection);
        //System.debug('~~~~ RecordManagerTemplate::send: methodName - ' + methodName);
        //System.debug('~~~~ RecordManagerTemplate::send: isIntegrationOff - ' + isIntegrationOff);

        if (!isIntegrationOff) {
            try {
                //System.debug('~~~~ '+integrationDirection+'::'+methodName+': requestBody - ' + requestBody);
                record = BoltService.transformBoltResponse(integrationDirection, methodName, requestBody);
                //System.debug('~~~~ '+integrationDirection+'::'+methodName+': salesforce record - ' + Json.serializePretty(record));

                executeOperation(record, thisOperation, ids, SOBJECT_TYPE, objectApiName);
                
                //custom response back to bolt
                                ids.add(record.Id);
                List<Map<String, Object>> body = BoltService.transformSalesforceBody(ids, integrationDirection, methodName);
        
                String responseBodyJson = Json.serializePretty(body[0]);
                //System.debug('~~~~ '+integrationDirection+'::'+methodName+': responseBodyJson - ' + responseBodyJson);
                recordResponse.responseBody = Blob.valueOf(responseBodyJson);
                recordResponse.statusCode = 200;
            } catch (Exception e) {
                //System.debug('~~~~'+integrationDirection+'::'+methodName+' - e ' + String.valueOf(e) + ' ' + e.getStackTraceString());
                recordResponse.responseBody = Blob.valueOf(Json.serializePretty(e.getMessage()));
                recordResponse.statusCode=500; 
                String errorMsg = Json.serializePretty(e.getMessage());

                if (e.getMessage().contains(BoltConstants.LOCK_ERROR)) {
                    if (retry < BoltConstants.MAX_RETRIES) {
                        //try again for LOCK ERROR
                        retry++;
                        errorMsg += ' RETRYING AGAIN! retry number: ' + String.valueOf(retry);   
                        send(methodName, thisOperation, apexClass); 
                    } else {
                        //Don't try again for LOCK ERROR
                        errorMsg += ' NOT Retrying again.  Reached max tries of ' + String.valueOf(BoltConstants.MAX_RETRIES);
                    }
                    BoltLogPublisherService.publishBoltErrorEvent(recordResponse.statusCode, errorMsg,  recordRequest.requestBody.toString(), integrationDirection, methodName, ids, apexClass);  
                } else {
                    //Don't try again, just log error
                    BoltLogPublisherService.publishBoltErrorEvent(recordResponse.statusCode, errorMsg,  recordRequest.requestBody.toString(), integrationDirection, methodName, ids, apexClass);        
                }
            }
        } else {
            recordResponse.responseBody = Blob.valueOf(Json.serializePretty(System.Label.BOLT_INTEGRATION_OFF));
            recordResponse.statusCode=503;             
            BoltLogPublisherService.publishBoltIntegrationOffEvent(requestBody, integrationDirection, methodName, apexClass);
        }
    }  

    private static void sendList(String methodName, Operation thisOperation, String apexClass) {
        String integrationDirection = BoltConstants.BOLT_TO_SF;
        RestRequest recordRequest = RestContext.request;
        RestResponse recordResponse = RestContext.response;
        Set<Id> ids = new Set<Id>();
        List<SObject> recordLst = null;
        Boolean isIntegrationOff=BoltService.turnOffIntegration(integrationDirection, methodName);
        String requestBody = recordRequest.requestBody.toString();
        String objectApiName = BoltService.getObjectApiName(integrationDirection, methodName, false);

        //System.debug('~~~~ RecordManagerTemplate::sendList: integrationDirection - ' + integrationDirection);
        //System.debug('~~~~ RecordManagerTemplate::sendList: methodName - ' + methodName);
        //System.debug('~~~~ RecordManagerTemplate::sendList: isIntegrationOff - ' + isIntegrationOff);
        
        if (!isIntegrationOff) {
            try {
                //System.debug('~~~~ '+integrationDirection+'::'+methodName+': requestBody - ' + requestBody);
                recordLst = BoltService.transformBoltListResponse(integrationDirection, methodName, requestBody);
                //System.debug('~~~~ '+integrationDirection+'::'+methodName+': salesforce record - ' + Json.serializePretty(recordLst));

                executeOperation(recordLst, thisOperation, ids, LIST_SOBJECT_TYPE, objectApiName);

                //get list of ids
                for (SObject record : recordLst) {
                    ids.add(record.Id);
                }
                
                List<Map<String, Object>> body = BoltService.transformSalesforceBody(ids, integrationDirection, methodName);
        
                String responseBodyJson = Json.serializePretty(body);
                //System.debug('~~~~ '+integrationDirection+'::'+methodName+': responseBodyJson - ' + responseBodyJson);
                recordResponse.responseBody = Blob.valueOf(responseBodyJson);
                recordResponse.statusCode = 200;
            } catch (Exception e) {
                //System.debug('~~~~'+integrationDirection+'::'+methodName+' - e ' + String.valueOf(e));
                //System.debug('~~~~'+integrationDirection+'::'+methodName+' - e get static trace ' + String.valueOf(e.getStackTraceString()));
                recordResponse.responseBody = Blob.valueOf(Json.serializePretty(e.getMessage()));
                recordResponse.statusCode=500; 
                String errorMsg = Json.serializePretty(e.getMessage());

                if (e.getMessage().contains(BoltConstants.LOCK_ERROR)) {
                    if (retry < BoltConstants.MAX_RETRIES) {
                        //try again for LOCK ERROR
                        retry++;
                        errorMsg += ' RETRYING AGAIN! retry number: ' + String.valueOf(retry);   
                        send(methodName, thisOperation, apexClass); 
                    } else {
                        //Don't try again for LOCK ERROR
                        errorMsg += ' NOT Retrying again.  Reached max tries of ' + String.valueOf(BoltConstants.MAX_RETRIES);
                    }
                    BoltLogPublisherService.publishBoltErrorEvent(recordResponse.statusCode, errorMsg,  recordRequest.requestBody.toString(), integrationDirection, methodName, ids, apexClass);  
                } else {
                    //Don't try again, just log error
                    BoltLogPublisherService.publishBoltErrorEvent(recordResponse.statusCode, errorMsg,  recordRequest.requestBody.toString(), integrationDirection, methodName, ids, apexClass);        
                }
            }
        } else {
            recordResponse.responseBody = Blob.valueOf(Json.serializePretty(System.Label.BOLT_INTEGRATION_OFF));
            recordResponse.statusCode=503;            
            BoltLogPublisherService.publishBoltIntegrationOffEvent(requestBody, integrationDirection, methodName, apexClass);
        }
    } 

    private static void executeOperation(Object record, Operation thisOperation, Set<Id> ids, String type, String objectApiName) {
        switch on thisOperation {
            when O_INSERT {
                if (type == SOBJECT_TYPE) 
                    insert (SObject)record;
                else 
                    insert (List<SObject>)record;
            }
            when O_UPDATE {
                if (type == SOBJECT_TYPE) {
                    SObject thisRecord = (SObject)record;
                    if(thisRecord.get('Id') != null) {
                        ids.add((Id)thisRecord.get('Id'));
                    }
                    update thisRecord;
                } else {
                    for (SObject item : (List<SObject>)record) {
                        if (item.Id != null) {
                            ids.add((Id)item.get('Id'));
                        }
                    }
                    update (List<SObject>)record;
                }
            } 
            //STAR-3314
            when O_UPSERT {
                //Unfortunatly, there isn't an elegant workaround for dynamic upserts as of now
                //https://salesforce.stackexchange.com/questions/64988/apex-cast-sobject-list-dynamically-to-a-specific-sobject-type
                //If you don't include the external key and send a record that already has the external id value, you'll get an error.
                //I've tried other ways outside of what is mentioned in the stackexchange article to no success in developer's console
                //I don't like this solution!!  Each time we add a new object or change the api name of an object/field we are upserting, 
                //we'll have to modify this code!
                switch on objectApiName {
                    when 'Transaction__c' {
                        if (type == 'SObject')
                            upsert (Transaction__c)record Row_Id__c;
                        else 
                            upsert (List<Transaction__c>)record Row_Id__c;
                    }
                    //STAR-44447
                    when 'Invoice__c' {
                        if (type == 'SObject') 
                            upsert (Invoice__c)record Bolt_Invoice_Number__c;
                        else
                            upsert (List<Invoice__c>)record Bolt_Invoice_Number__c;
                    }
                    when 'Credit_Memo__c' {
                        if (type == 'SObject') 
                            upsert (Credit_Memo__c)record BOLT_Unique_ID__c;
                        else
                            upsert (List<Credit_Memo__c>)record BOLT_Unique_ID__c;
                    }                    
                    //STAR-3537 - can't use upsert operations for users
                    //Error received:
                    //force-app/main/default/classes/RecordManagerTemplate.cls  DML operation Upsert not allowed on User (189:29)      
                    //force-app/main/default/classes/RecordManagerTemplate.cls  DML operation Upsert not allowed on List<User> (191:29)
                    /*when 'User' {
                        if (type == 'SObject') 
                            upsert (User)record ADP_Associate_OID__c;
                        else
                            upsert (List<User>)record ADP_Associate_OID__c;
                    } */                   
                }
            }
        }
    }
}