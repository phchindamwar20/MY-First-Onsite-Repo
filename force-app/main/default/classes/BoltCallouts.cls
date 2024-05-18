/**
 * @description       : This is the class that makes callouts to Bolt as a part of the SF=>Bolt integration
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-15-2024
 * @last modified by  : Terri Jiles
**/
global class BoltCallouts {
    public static Boolean isIntegrationOff=false;
    
/**
     * @description : sendRecords -  This method is called to transform salesforce records to a bolt request and then makes a callout to bolt web service
     * @param : ids - set of ids of records to send to bolt
     * @param : boltWsAction - the bolt web service name
     * @param : the name of the apex class
     */
    public static void sendRecords(Set<ID> ids, String boltWsAction, String apexClass){ 
        String integrationDirection=BoltConstants.SF_TO_BOLT;
        isIntegrationOff=BoltService.turnOffIntegration(integrationDirection, boltWsAction);        
        
        if (!isIntegrationOff) {        
            List<Map<String, Object>> boltResultLst =  BoltService.transformSalesforceBody(ids, integrationDirection, boltWsAction);

            if (boltResultLst != null) {
                String body = JSON.serializePretty(boltResultLst);
                //System.debug('~~~~ '+apexClass+'::'+boltWsAction+': body - ' + body);
                sendToEnv(body, boltWsAction, ids, apexClass);
            }
        } else {
            BoltLogPublisherService.publishBoltIntegrationOffEvent(String.valueOf(ids), integrationDirection, boltWsAction, apexClass);
        }
    } 

/**
     * 
     */
    @TestVisible
    private static void sendToEnv(String jsonBody, String boltWsAction,  Set<Id> ids, String apexClass){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:BoltEndpoint'+Label.BOLT_ENDPOINT_ENVIRONMENT+boltWsAction);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('x-api-key', '{!$Credential.Password}');
        req.setHeader('OrgId', UserInfo.getOrganizationId());
        req.setHeader('OrgName', UserInfo.getOrganizationName());
        req.setHeader('NameOfUser', UserInfo.getName());
        req.setHeader('UserId', UserInfo.getUserId());
        req.setHeader('LoginUserName', UserInfo.getUserName());
        req.setHeader('UserEmail', UserInfo.getUserEmail());
        req.setHeader('UserTimeZone', String.valueOf(UserInfo.getTimeZone()));
        req.setHeader('UserType', UserInfo.getUserType());
        req.setHeader('UserDefaultCurrency', UserInfo.getDefaultCurrency());
        req.setHeader('UserLanguage', UserInfo.getLanguage());
        req.setHeader('CurrentDateTime', String.valueOf(DateTime.now()));
        if (ids != null) {
            req.setHeader('NumberOfRecords', String.valueOf(ids.size()));
        }
        req.setBody(jsonBody);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() > 299 || res.getStatusCode() < 200) {
            BoltLogPublisherService.publishBoltErrorEvent(res.getStatusCode(), res.getBody(),  jsonBody, BoltConstants.SF_TO_BOLT, boltWsAction, ids, apexClass);
        }

        if (!Test.isRunningTest() && !boltWsAction.contains('delete')) {
            updateRecordsWithResponseFromBolt(req, res, ids, boltWsAction);
        }
    }

    public static Boolean integrateWithBolt() {
        //if the BOLT integration user is currently inserting or updating records in salesforce, use the
        //result of this method to prevent the integration from sending updates/inserts back to BOLT
        BOLT__c bypass= BOLT__c.getInstance();
        
        return !bypass.Is_Bolt_Integration_User__c;
    } 

    @TestVisible
    private static void updateRecordsWithResponseFromBolt(HttpRequest request, HTTPResponse response, Set<Id> ids, String boltWsAction) {
        //Update the records sent to Bolt with the response back from Bolt
        //This will help with troubleshooting to determine salesforce sent records to the bolt queue successfully or not
        //As of August 2022, Bolt doesn't send a response back to Salesforce to indicate if records in the queue were saved to the bolt application successfully or not
        //Salesforce only knows if records were sent successfully or not to the Bolt Queue
                List<sObject> recordsToUpdate = new List<sObject>();
        Datetime lastBoltCalloutDate = Datetime.now();

        //storing these in variables outside loop buys a lot of performance improvments by reducing the heap space
        String bodyRequest;
        if (ids.size() <= 1) {
            bodyRequest = ((String)request.getBody()).left(131072);
        } else {
            bodyRequest = 'The requst has many records.  To reduce proceessing time and reduce the likelihood of running into a govenor limit, the request is not logged!';
        }
        Integer statusCode = response.getStatusCode();
        String endpoint = request.getEndpoint();
        String status = response.getStatus();
        String responseBody = response.getBody();

        for (Id recId : ids) {
            //SObject rec = Schema.getGlobalDescribe().get(sObjectType).newSObject();
            SObject rec = recId.getSobjectType().newSObject(recId); //this takes up less heap space than the other way, was able to shave 3380100 - 2098510 = 1281590 in one test!
            //rec.put('Id', recId);
            rec.put('Bolt_Status_Code__c', statusCode);
            rec.put('Bolt_Callout_Endpoint__c', endpoint);
            rec.put('Last_Callout_to_Bolt_Date__c', lastBoltCalloutDate);
            rec.put('Bolt_Status__c', status);
            rec.put('Bolt_Response_Body__c', responseBody);
            rec.put('Bolt_SF_To_Bolt_Request__c', bodyRequest);
            
            recordsToUpdate.add(rec);
        }
        
        if (!recordsToUpdate.isEmpty()) {
            Database.SaveResult[] resultLst = Database.update(recordsToUpdate, false);
        }
    }

    public static Boolean isChangeInRecord(SObject newRec, SObject oldRec, String methodName) {
        return BoltService.isChangeInRecord(newRec, oldRec, BoltConstants.SF_TO_BOLT, methodName);
    }
}