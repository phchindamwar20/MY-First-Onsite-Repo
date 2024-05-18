/**
 * @description       : This class provides support for common dynamic apex reusable components such as
 *                      1. get a field value for an SObject
 *                      2. getting a map of the Schema.SObjectField by relationship name of all references fields associated with a given object
 *                      3. casting a field type of a generic object value, based on the field name and field type  
 *                              Utilized getType method from https://salesforce.stackexchange.com/questions/332592/ho-to-dynamically-deserialize-untyped-a-json-with-list
 *                      4. checking if a field exists on an object
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-30-2024
 * @last modified by  : Terri Jiles
**/
public with sharing class DynamicApexService {

    public static Object getFieldValue(String sfField, SObject sfRecord) {
        List<String> fieldNameLst = new List<String>();
        String parseChar = '\\.';
        //System.debug('~~~~ DynamicApexService::getFieldValue: sfField ' + sfField);

        fieldNameLst.addAll((sfField.split(parseChar)));

        Integer num = fieldNameLst.size();
        Object fieldValue;
        //System.debug('~~~~ DynamicApexService::getFieldValue: sfField.contains(parseChar) ' + sfField.contains(parseChar));
        //System.debug('~~~~ DynamicApexService::getFieldValue: sfField.split(parseChar) ' + sfField.split(parseChar));
        //System.debug('~~~~ DynamicApexService::getFieldValue: fieldNameLst ' + fieldNameLst);
        //System.debug('~~~~ DynamicApexService::getFieldValue: sfRecord ' + sfRecord);
        //System.debug('~~~~ DynamicApexService::getFieldValue: num ' + num);

        if (num > 1) {
            //get parent SObject from relationship field
            for(Integer i=0 ; i < num - 1 ; i++) {
                SObject rec = sfRecord.getSObject(fieldNameLst[i]);
                if (rec != null) 
                    sfRecord = rec;
                else {
                    return null; //parent is null, so don't continue to lookup field value or next parent
                }
                //System.debug('~~~~ DynamicApexService::getFieldValue: rec ' + rec);
            }
        }
        //get field value of SObject
        fieldValue = sfRecord.get(fieldNameLst[num - 1]);
        //System.debug('~~~~ DynamicApexService::getFieldValue: fieldValue ' + fieldValue);
        return fieldValue;
    }

    public static Map<String, Schema.sObjectField> getFieldNameByRelationshipInfo(String objectApiName) {
        List<String> objNameLst = new List<String>();
        objNameLst.add(objectApiName);
        SObject objectType = Schema.describeSObjects(objNameLst, SObjectDescribeOptions.DEFERRED)[0].getSObjectType().newSObject();
        Map<String, Schema.sObjectField> targetFieldSchemaByField = objectType.getSObjectType().getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        Map<String, Schema.sObjectField> fieldNameByRelationshipInfoMap = new Map<String, Schema.sObjectField>();

        for(Schema.sObjectField fieldToken : targetFieldSchemaByField.values()) {
            if (fieldToken.getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                fieldNameByRelationshipInfoMap.put(fieldToken.getDescribe().getRelationshipName(),fieldToken );
            }
        }
        return fieldNameByRelationshipInfoMap;
    }
        
    public static object getValueType(Map<String, Schema.sObjectField> targetFieldSchemaByField, String fieldName, Object value) {
        if (value != null) {
            switch on targetFieldSchemaByField.get(fieldName)?.getDescribe().getType() {
                when DATE {
                    value = Date.valueOf((String)value);
                }
                when DATETIME {
                    String s = (String)value;
                    value = Datetime.valueOf(s.replace('T',' '));
                }
                when PERCENT, CURRENCY {
                    value=Decimal.valueOf(String.valueOf(value));
                }
                when DOUBLE {
                    value = Double.valueOf(value);
                }
                when INTEGER {
                    value = Integer.valueOf(value);
                }
                when BASE64 {
                    value = Blob.valueOf((String)value);
                } 
                when BOOLEAN {
                    value = Boolean.valueOf(value);
                }
                when else {
                    value = String.valueOf(value);
                }
            }
        }
        return value;
    }

    public static Boolean isFieldExists(String objectType, String field) {
        Set<String> fieldNames = Schema.getGlobalDescribe().get(objectType).getDescribe().fields.getMap().keySet();
        //System.debug('~~~~ DynamicApexService::isFieldExists: fieldNames - ' + fieldNames);

        return fieldNames.contains(field.toLowerCase());
    }

    public static SObject createObject(String typeName) {
        List<String> objNameLst = new List<String>();
        objNameLst.add(typeName);
        Schema.SObjectType targetType = Schema.describeSObjects(objNameLst, SObjectDescribeOptions.DEFERRED)[0].getSObjectType();
        if (targetType == null) {
            throw new DynamicApexServiceException(typeName + ' is an invalid object type');
        }

        return targetType.newSObject();
    }    

    public static Map<String, Set<Database.Error>> createRecs(List<SObject> recLst, Boolean allOrNone) {
        Map<String, Set<Database.Error>> errorMsgsById = new Map<String, Set<Database.Error>>();
        Database.SaveResult[] resultLst = Database.insert(recLst, allOrNone);
        Integer i = 0;
        for (Database.SaveResult sr : resultLst) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    if(!errorMsgsById.containsKey(sr.getId())) {
                        errorMsgsById.put(sr.getId(), new Set<Database.Error>());
                    }
                    errorMsgsById.get(sr.getId()).add(err);
                }
            }
            i++;
        }
        return errorMsgsById;
    }  

    public static Map<String, Set<Database.Error>> updateRecs(Map<Id, SObject> recById, Boolean allOrNone) {
        Map<String, Set<Database.Error>> errorMsgsById = new Map<String, Set<Database.Error>>();
        Database.SaveResult[] resultLst = Database.update(recById.values(), allOrNone);
        Integer i = 0;
        for (Database.SaveResult sr : resultLst) {
            if (!sr.isSuccess()) {
                recById.remove(sr.getId());
                for (Database.Error err : sr.getErrors()) {
                    if(!errorMsgsById.containsKey(sr.getId())) {
                        errorMsgsById.put(sr.getId(), new Set<Database.Error>());
                    }
                    errorMsgsById.get(sr.getId()).add(err);
                }
            }
            i++;
        }

        return errorMsgsById;
    }    
    
    public static Map<Id, String> updateRecs(Map<Id, SObject> recById) {
        Map<Id, String> errorMsgById = new Map<Id, String>();
        Database.SaveResult[] resultLst = Database.update(recById.values(), false);
        for (Database.SaveResult sr : resultLst) {
            if (!sr.isSuccess()) {
                recById.remove(sr.getId());
                for (Database.Error err : sr.getErrors()) {
                    errorMsgById.put(sr.getId(), ' Error: Id - ' + sr.getId() + ', status code: ' + err.getStatusCode() + ',  messsage: ' + err.getMessage() + '\n');
                }
            } 
        } 
        
        return errorMsgById;
    }

    public static Map<Id, List<Database.Error>> getErrorsFromDelResult (List<Database.DeleteResult> deleteResultLst, List<SObject> recLst, String field, Map<Id, List<Database.Error>> errorLstByJobId) {
        Integer i=0;
        for (Database.DeleteResult sr : deleteResultLst) {
            if (!sr.isSuccess()) {
                if (recLst[i]?.get(field) != null) { 
                    if (!errorLstByJobId.containsKey((Id)recLst[i].get(field))) {
                        errorLstByJobId.put((Id)recLst[i].get(field), new List<Database.Error>());
                    }
                    errorLstByJobId.get((Id)recLst[i].get(field)).addAll(sr.getErrors());
                }
            }
            i++;
        }

        return errorLstByJobId;
    }

    public static Map<Id, List<Database.Error>> getErrorsFromResult (List<Database.SaveResult> saveResultLst, List<SObject> recLst, String field, Map<Id, List<Database.Error>> errorLstByJobId) {
        Integer i=0;
        for (Database.SaveResult sr : saveResultLst) {
            if (!sr.isSuccess()) {
                if (recLst[i]?.get(field) != null) { 
                    if (!errorLstByJobId.containsKey((Id)recLst[i].get(field))) {
                        errorLstByJobId.put((Id)recLst[i].get(field), new List<Database.Error>());
                    }
                    errorLstByJobId.get((Id)recLst[i].get(field)).addAll(sr.getErrors());
                }
            }
            i++;
        }

        return errorLstByJobId;
    }
    
    public class DynamicApexServiceException extends Exception {}    
}