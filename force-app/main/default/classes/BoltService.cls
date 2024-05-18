/**
 * @description       : This is the code for the Bolt Integration Engine.  It supports the dynamic Bolt Custom REST Service (BOLT=>SF) and Callouts (SF=>Bolt)
 *                          This class is utlized by BoltCallouts for the SF=>Bolt Integration and RecordManagerTemplate class (BOLT=>SF)
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 02-03-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class BoltService {
        //This compares if the record in Salesforce is new OR if the values of integration fields on the record changed
    //if yes, returns true (so we know we need to callout to Bolt later)
    //else, no (and we won't call out to Bolt later)
    public static Boolean isChangeInRecord(SObject newRec, SObject oldRec, String integrationDirection, String methodName) {

        List<Bolt_Integration_Fields__mdt> bifLst = getBoltIntegrationFields(integrationDirection, methodName, true);
        String objectApiName = getObjectApiName(bifLst);
        Map<String, Schema.SObjectField> fieldNameByRelationshipInfoMap = DynamicApexService.getFieldNameByRelationshipInfo(objectApiName);
                
        Boolean result = false;
        if (oldRec == null) {
            result = true;
        } else if (oldRec != null) {
            for (Bolt_Integration_Fields__mdt bif : bifLst) {
                String sfApiFieldName = bif.Field_API_Name__c;

                //check if field in the mapping for the sqol query is referencing a parent of the record's field
                //i.e. BD_Account_Manager__r.Name, where BD_Account_Manager__r is the relationship name of the parent
                if (sfApiFieldName.contains('.')) {
                    //get first level parent only
                    //using above example, would return BD_Account_Manager__r as the relationship name
                    //if this was two levels deep and the mapping had BD_Account_Manager__r.Account.Name, it would still return BD_Account_Manager__r as the relationship name
                    String sfRelationshipName = sfApiFieldName.split('\\.', 2)[0];
                    //if yes, use relationship name to get the lookup field name on the object to use to detect a change in the field
                    if (fieldNameByRelationshipInfoMap.containsKey(sfRelationshipName) ) {
                        //NOTE:  Please not, if the user changed the parent referenced on the record from one parent to another, the integration will pick up this change
                        //               (i.e.  User changes the BD Account Manager referenced on a job from Bob Smith's User record to Alice Johnson's User record, 
                        //                      the integration will detect the job's change in the BD Account Manager field's reference id changed from one user id to another
                        //       HOWEVER, if the parent record itself was updated, the integration wouldn't pick that change up unless the parent record itself is integrated with bolt
                        //                (i.e.  Using the same user record examples above, let's say Alice Johnson get's married and her last name changes from her maiden name 
                        //                      from Johnson to Hamilton on her User record.  Because user records are NOT integrated with Bolt at this time, that change wouldn't
                        //                      flow to Bolt nor will it trigger a change on the job record.  This is because the user id referenced on the Job's BD Account Manager 
                        //                      field remained the same.  In Bolt, the BD Account Manager would still be Alice Johnson on the job.)
                        //This code gets the field name of the lookup field, using the example above, the field name would be BD_Account_Manager__c
                        sfApiFieldName = fieldNameByRelationshipInfoMap.get(sfRelationshipName).getDescribe().getName();
                    }
                }
                //check for change in field VALUE on the record 
                //System.debug('~~~~ BoltService::isChangeInRecord: newRec.get(sfApiFieldName)='+newRec.get(sfApiFieldName)+', oldRec.get(sfApiFieldName)='+oldRec.get(sfApiFieldName));
                if (newRec.get(sfApiFieldName) != oldRec.get(sfApiFieldName)) {
                    //System.debug('~~~~ BoltService::isChangeInRecord: has changed');

                    result=true;
                    break;
                }
            }                                        
        } 
        return result;
    }

    //takes salesforce records and translates into a Bolt json request or response
    public static List<Map<String, Object>> transformSalesforceBody(Set<Id> ids, String integrationDirection, String boltWsAction) {
        List<Bolt_Integration_Fields__mdt> bifLst = BoltService.getBoltIntegrationFields(integrationDirection, boltWsAction, true);
        List<SObject> recordLst = Database.query(BoltService.buildSqol(bifLst, ids));
        
        //This translates a list of salesforce sObjects into json array body acceptable by Bolt web services either as a request or a response
        //Please note, the field names in the JSON are case sensitive
        List<Map<String, Object>> boltResultLst = new List<Map<String, Object>>();

        //go through each Salesforce record
        for (SObject sfRecord : recordLst) {
            Map<String, Object> boltRecordByField = new Map<String, Object>();
            //go through each field in the sf record transform into a bolt record by ws field
            for (Bolt_Integration_Fields__mdt bif : bifLst) {
                String wsField=getWsFieldName(bif.Alias_Field_Name__c, bif.Field_API_Name__c);
                Object sfFieldValue=null;
                String sfApiField=bif.Field_API_Name__c;

                sfFieldValue = DynamicApexService.getFieldValue(sfApiField, sfRecord);
                boltRecordByField.put(wsField, sfFieldValue);
            }
            boltResultLst.add(boltRecordByField);
        }
        return boltResultLst;
    }

    //bolt json body => salesforce SObject
    public static SObject transformBoltResponse(String integrationDirection, String methodName, String requestBody) {
        List<Bolt_Integration_Fields__mdt> bifLst = BoltService.getBoltIntegrationFields(integrationDirection, methodName, false);

        //get object, field names, and alias
        Map<String, Bolt_Integration_Fields__mdt> bifByAliasFieldNameMap = createMapOfAliasKeyToFieldNames(bifLst);

        //parse body
        Map<String, Object> genericRecordByAliasFieldMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

        //get alternative id values
        List<Map<String, Object>> genericRecordByAliasFieldMapLst = new List<Map<String, Object>>();
        genericRecordByAliasFieldMapLst.add(genericRecordByAliasFieldMap);
        Map<String, Id> altIdById = getAltIds(bifByAliasFieldNameMap, genericRecordByAliasFieldMapLst);

        //remove field defaults if present in request, the defaults don't need to be added because bolt populated a value for these fields
        Set<String> defaultFields = getDefaultFields(bifLst);
        defaultFields.removeAll(genericRecordByAliasFieldMap.keySet());
        //add field defaults
        for (String defaultField : defaultFields) {
            genericRecordByAliasFieldMap.put(defaultField, (Object)bifByAliasFieldNameMap.get(defaultField).Default_Value__c);
        }

        SObject resultSObject = createSObjectFromBolt(bifByAliasFieldNameMap, genericRecordByAliasFieldMap, altIdById);
            
        return resultSObject;
    }


    //bolt json body with list of records => list of salesforcce SObjects
    public static List<SObject> transformBoltListResponse(String integrationDirection, String methodName, String requestBody) {
        List<Bolt_Integration_Fields__mdt> bifLst = BoltService.getBoltIntegrationFields(integrationDirection, methodName, false);
        Set<String> defaultFields = getDefaultFields(bifLst);
        List<SObject> boltRecordLst = new List<SObject>();

        //Get Map of Alias key to field names of object and default fields
        Map<String, Bolt_Integration_Fields__mdt> bifByAliasFieldNameMap = createMapOfAliasKeyToFieldNames(bifLst);

        //parse body
        List<Object> genericRecordsLst = (List<Object>)JSON.deserializeUntyped(requestBody);
        List<Map<String, Object>> genericRecordByAliasFieldMapLst = new List<Map<String, Object>>();
        for (Object record : genericRecordsLst) {
            Map<String, Object> genericRecordByAliasFieldMap = (Map<String, Object>)record;
            genericRecordByAliasFieldMapLst.add(genericRecordByAliasFieldMap);
        }

        //alt id variables
        Map<String, Id> altIdById = getAltIds(bifByAliasFieldNameMap, genericRecordByAliasFieldMapLst);

        for (Map<String, Object> genericRecordByAliasFieldMap : genericRecordByAliasFieldMapLst) {
            //remove field defaults if present in request
            defaultFields.removeAll(genericRecordByAliasFieldMap.keySet());
            //add field defaults
            for (String defaultField : defaultFields) {
                genericRecordByAliasFieldMap.put(defaultField, (Object)bifByAliasFieldNameMap.get(defaultField).Default_Value__c);
            }

            SObject sfRecord = createSObjectFromBolt(bifByAliasFieldNameMap, genericRecordByAliasFieldMap, altIdById);
            boltRecordLst.add(sfRecord);
        }

        return boltRecordLst;
    }    


    private static Map<String, Bolt_Integration_Fields__mdt> createMapOfAliasKeyToFieldNames(List<Bolt_Integration_Fields__mdt> bifLst) {
        Map<String, Bolt_Integration_Fields__mdt> bifByAliasFieldNameMap = new Map<String, Bolt_Integration_Fields__mdt>();

        //Map of Alias key to field names of object and default fields
        for (Bolt_Integration_Fields__mdt bif : bifLst) {
            String wsFieldName=getWsFieldName(bif.Alias_Field_Name__c, bif.Field_API_Name__c);
            bifByAliasFieldNameMap.put(wsFieldName, bif);
        }
        return bifByAliasFieldNameMap;
    } 

    private static Set<String> getDefaultFields(List<Bolt_Integration_Fields__mdt> bifLst) {
        Set<String> defaultFields = new Set<String>();
        for (Bolt_Integration_Fields__mdt bif : bifLst) {
            String wsFieldName=getWsFieldName(bif.Alias_Field_Name__c, bif.Field_API_Name__c);
          
            //get default fields
            if (bif.IsDefault__c && !String.isBlank(bif.Default_Value__c)) { 
                defaultFields.add(wsFieldName);
            }       
        }        
        return defaultFields;
    }

    private static String getWsFieldName(String aliasFieldName, String apiFieldName) {
        String wsFieldName = aliasFieldName;

        if (String.isEmpty(wsFieldName)) {
            wsFieldName=apiFieldName;
        }

        return wsFieldName;
    } 

    private static SObject createSObjectFromBolt(Map<String, Bolt_Integration_Fields__mdt> bifByAliasFieldNameMap, Map<String, Object> genericRecordByAliasFieldMap, Map<String, Id> altIdById) {
        String objectApiName = getObjectApiName(bifByAliasFieldNameMap.values());
        SObject resultSObject = DynamicApexService.createObject(objectApiName);
        Map<String, Schema.sObjectField> targetFieldSchemaByField = resultSObject.getSObjectType().getDescribe().fields.getMap();
        //get info on relationship fields for object to use for matching related record with External Id later

        //dynamic set field corresponding to alias attribute on request
        for(String aliasFieldName : genericRecordByAliasFieldMap.keySet()) {
            //System.debug('~~~~ BoltService::createSObjectFromBolt: bifByAliasFieldNameMap.get(aliasFieldName) - ' + bifByAliasFieldNameMap.get(aliasFieldName));
            //if it contains aliasFieldName and the field isn't a reference field
            if (bifByAliasFieldNameMap.containsKey(aliasFieldName)) {
                String fieldName = bifByAliasFieldNameMap.get(aliasFieldName).Field_API_Name__c;

                //field is not an external id
                if (!bifByAliasFieldNameMap.get(aliasFieldName).Is_External_Reference_Id__c) {
                    //System.debug('~~~~ BoltService::createSObjectFromBolt- is External Reference is FALSE');
                    Object value = DynamicApexService.getValueType(targetFieldSchemaByField, fieldName, genericRecordByAliasFieldMap.get(aliasFieldName));
                    resultSObject.put(fieldName, value);

                    //get info on alternative id 
                    resultSObject = setAltlIdOnRec(bifByAliasFieldNameMap, genericRecordByAliasFieldMap, aliasFieldName, resultSObject, altIdById);
                } 
 
                //Mapping has external id value that needs to be used to associate the related record 
                resultSObject = setRelatedRecUsingExternalId(bifByAliasFieldNameMap, genericRecordByAliasFieldMap, aliasFieldName, resultSObject);                
            } 
        }
        return resultSObject;
    }

    private static SObject setAltlIdOnRec(Map<String, Bolt_Integration_Fields__mdt> bifByAliasFieldNameMap, Map<String, Object> genericRecordByAliasFieldMap, String aliasFieldName, SObject resultSObject, Map<String, Id> altIdById) {
        //get info on alternative id 
        if (bifByAliasFieldNameMap.get(aliasFieldName).Is_Alternative_Update_Id__c) {
            String idFieldName = 'Id';
            String altIdFieldName= bifByAliasFieldNameMap.get(aliasFieldName).Field_API_Name__c;
            String key = (String)resultSObject.get(altIdFieldName);
            
            if (altIdById.containsKey(key)) {
                resultSObject.put(idFieldName, altIdById.get((String)resultSObject.get(altIdFieldName)));
                } else {
                    resultSObject.put(idFieldName, null); 
            }
        }
        return resultSObject;
    }

    private static SObject setRelatedRecUsingExternalId(Map<String, Bolt_Integration_Fields__mdt> bifByAliasFieldNameMap, Map<String, Object> genericRecordByAliasFieldMap, String aliasFieldName, SObject resultSObject) {
        //STAR-5609 Mapping has external id value that needs to be used to associate the related record 
        String fieldName = bifByAliasFieldNameMap.get(aliasFieldName).Field_API_Name__c;
        String objectApiName = bifByAliasFieldNameMap.get(aliasFieldName).Object_API_Name__c;
        if (bifByAliasFieldNameMap.get(aliasFieldName).Is_External_Reference_Id__c 
                && String.isNotBlank(bifByAliasFieldNameMap.get(aliasFieldName).Related_Object_API_Name__c) 
                && String.isNotBlank(bifByAliasFieldNameMap.get(aliasFieldName).Related_Field_API_Name__c)
                ) {
            if (genericRecordByAliasFieldMap.get(aliasFieldName) != null
                    && !String.isBlank(((String)genericRecordByAliasFieldMap.get(aliasFieldName)))) {
                SObject relatedRec = DynamicApexService.createObject(bifByAliasFieldNameMap.get(aliasFieldName).Related_Object_API_Name__c);
                relatedRec.put(bifByAliasFieldNameMap.get(aliasFieldName).Related_Field_API_Name__c, (String)genericRecordByAliasFieldMap.get(aliasFieldName));
                resultSObject.putSObject(fieldName, relatedRec);
            } else {
                Map<String, Schema.SObjectField> fieldNameByRelationshipInfoMap = DynamicApexService.getFieldNameByRelationshipInfo(objectApiName);
                String recFieldName = fieldNameByRelationshipInfoMap.get(fieldName).getDescribe().getName();
                resultSObject.put(recFieldName, null); //null out the lookup field in the record
            }
                }
        return resultSObject;
    }

    //get info on alternative id for updating a salesforce record -- this method will not work well if processing within a list of SObjects
    private static Map<String, Id> getAltIds(Map<String, Bolt_Integration_Fields__mdt> bifByAliasFieldNameMap, List<Map<String, Object>> genericRecordByAliasFieldMapLst) {
        String objectApiName = getObjectApiName(bifByAliasFieldNameMap.values());
        Map<String, Id> altIdById = new Map<String, Id>();
        String altIdFieldName = null;
        String aliasFieldName = null;
        Set<String> altIdValues = new Set<String>();

        //get alternative id field name
        for (String alias : bifByAliasFieldNameMap.keySet()) {
            if (bifByAliasFieldNameMap.get(alias).Is_Alternative_Update_Id__c) {
                altIdFieldName = bifByAliasFieldNameMap.get(alias).Field_API_Name__c;
                aliasFieldName = alias;
                break;
            }
        }

        //there is an alternative id for this mapping
        if (altIdFieldName != null) {
            //dynamic set field corresponding to alias attribute on request
            for(Map<String, Object> genericRecordByAliasFieldMap : genericRecordByAliasFieldMapLst) {
                //if it contains aliasFieldName and the field isn't a reference field
                if (bifByAliasFieldNameMap.containsKey(aliasFieldName)) {
                    String value = (String)genericRecordByAliasFieldMap.get(aliasFieldName);
                    //get info on alternative id for processing later
                    altIdValues.add(value);
                }
            } 

        String whereClause = QueryBuilderService.getIdStringFromLst(altIdValues);
                String query = 'SELECT Id, ' + altIdFieldName+ ' FROM ' + objectAPIName + ' WHERE ' + altIdFieldName + ' IN (' + whereClause + ')';
                List<SObject> altIdResultsLst = Database.query(query);

        for (SObject rec : altIdResultsLst) {
            altIdById.put((String)rec.get(altIdFieldName), (Id)rec.get('Id'));
            }
        }

        return altIdById;
    }

    //builds sql of of bolt integration fields mappings
    public static String buildSqol(List<Bolt_Integration_Fields__mdt> bifLst, Set<Id> ids) {
        String sqol = 'SELECT'; 
        Set<String> idStrings = (Set<String>)JSON.deserialize(JSON.serialize(ids), Set<String>.class);
                String idString=QueryBuilderService.getIdStringFromLst(idStrings);

        //build query
        Integer size = bifLst.size();
        Integer row = 1;
        for (Bolt_Integration_Fields__mdt bif : bifLst) {
            //fields
            sqol+= ' ' + bif.Field_API_Name__c;
            if (row < size) {
                sqol+=',';
                row++;
            } else { //object
                sqol+=' FROM ' + bif.Object_API_Name__c;
                sqol+=' WHERE Id IN(' + idString + ')';

                //2023-01-24 Added this to avoid error "SObject type does not allow locking rows" specific to the User object
                if (bif.Object_API_Name__c !='User') {
                    if (bif.Method_Name__c.contains('delete')) {
                        sqol+=' AND (IsDeleted=TRUE OR IsDeleted=FALSE)';
                        sqol+=' ALL ROWS';
                    } else {
                        sqol+=' FOR UPDATE';
                    }
                }
            }
        }
        return sqol;
    }

    public static List<Bolt_Integration_Fields__mdt> getBoltIntegrationFields(String integrationDirection, String methodName, Boolean isToBolt) {
        String direction;
        if (isToBolt) { 
            direction = 'To_Bolt__c=true ';
        } else { 
            direction = 'From_Bolt__c=true ';
}

        String bifQuery='SELECT ' +
                        ' Alias_Field_Name__c, '+ 
                        ' Alias_Object_Name__c, '+
                        ' Field_API_Name__c, '+ 
                        ' Default_Value__c, '+
                        ' Is_Alternative_Update_Id__c, '+ 
                        ' Is_External_Reference_Id__c, '+ 
                        ' IsDefault__c, '+   
                        ' Method_Name__c, '+
                        ' Object_API_Name__c, '+
                        ' Related_Object_API_Name__c, ' +
                        ' Related_Field_API_Name__c ' +
                        'FROM Bolt_Integration_Fields__mdt ' +
                        'WHERE Integration_Direction__c =: integrationDirection ' +
                        '   AND Method_Name__c =: methodName ' +
                        '   AND '+ direction + 
                        'ORDER BY Alias_Field_Name__c, Field_API_Name__c ';
                return (List<Bolt_Integration_Fields__mdt>)Database.query(bifQuery);
    }

    private static String getObjectApiName(List<Bolt_Integration_Fields__mdt> mappingsLst) {
        String objectApiName = '';
        if(!mappingsLst.isEmpty()) {
            objectApiName = mappingsLst[0].Object_API_Name__c; 
        }
        return objectApiName;
    }

    public static String getObjectApiName(String integrationDirection, String boltWsAction, Boolean isToBolt) {
        List<Bolt_Integration_Fields__mdt> mappingLst = getBoltIntegrationFields(integrationDirection, boltWsAction, isToBolt);
        String objectApiName = '';

        if (!mappingLst.isEmpty()) {
            objectApiName = mappingLst[0].Object_API_Name__c;
        }

        return objectApiName;
    }

    //STAR-4769
    public static Boolean turnOffIntegration(String integrationDirection, String methodName) {   
        try {
            return [SELECT Turn_Off_Integration__c FROM Bolt_Integration_Switch__mdt WHERE Integration_Direction__c=:integrationDirection AND Method_Name__c=:methodName Limit 1].Turn_Off_Integration__c;
        } catch (Exception e) {
            return false;
        }
    }
}