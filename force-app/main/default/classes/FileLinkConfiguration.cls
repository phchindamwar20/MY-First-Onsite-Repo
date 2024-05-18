/**
 * @description       : 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 07-13-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class FileLinkConfiguration {
    public static Map<String, FileLinkServiceConfiguration__mdt> fileLinkConfigByRecPrefix = getFileLinkServiceConfigurationMap();

    private static Map<String, FileLinkServiceConfiguration__mdt> getFileLinkServiceConfigurationMap() {
        Map<String, FileLinkServiceConfiguration__mdt> fileLinkConfigByRecPrefix = new Map<String, FileLinkServiceConfiguration__mdt>();

        for (FileLinkServiceConfiguration__mdt flsc : [SELECT Id, 
                                                            Object_API_Name__c, 
                                                            File_Links_API_Field_Name__c, 
                                                            Last_Updated_By_API_Field_Name__c, 
                                                            Last_Updated_Date_API_Field_Name__c, 
                                                            Object_Record_3_Digit_Prefix__c, 
                                                            File_Links_Number_API_Field_Name__c 
                                                        FROM FileLinkServiceConfiguration__mdt]) {
            fileLinkConfigByRecPrefix.put(flsc.Object_Record_3_Digit_Prefix__c, flsc);
        }

        return fileLinkConfigByRecPrefix;
    }

    public static String buildQueryFromConfig(Set<Id> ids, FileLinkServiceConfiguration__mdt flsc) {
        String idString=QueryBuilderService.getIdStringFromLst((Set<String>)JSON.deserialize(JSON.serialize(ids), Set<String>.class));
        String recordTypeField = DynamicApexService.isFieldExists(flsc.Object_API_Name__c, 'RecordTypeId') ? ', RecordTypeId ' : '';

        String query = 'SELECT Id, ' + 
                    flsc.File_Links_API_Field_Name__c + ', ' + 
                    flsc.Last_Updated_By_API_Field_Name__c + ', ' + 
                    flsc.Last_Updated_Date_API_Field_Name__c + ', ' + 
                    flsc.File_Links_Number_API_Field_Name__c + 
                    recordTypeField +
                ' FROM ' + flsc.Object_API_Name__c + ' WHERE Id IN(' + idString +')'; 
        System.debug('~~~~ FileLinkConfiguration.buildQueryFromConfig: query - ' + query);
        
        return query;
    }

    public static Boolean isValidFileLinkObjectType(Id recId) {
        String objectPrefix = ((String)recId).left(3);
        return fileLinkConfigByRecPrefix.containsKey(objectPrefix);
    }

    public static String getFileLinksValue(SObject rec) {
        String objectPrefix = ((String)rec.Id).left(3);
        return (String)rec.get(fileLinkConfigByRecPrefix.get(objectPrefix).File_Links_API_Field_Name__c);
    }

    public static String getLastUpdatedByValue(SObject rec) {
        String objectPrefix = ((String)rec.Id).left(3);
        return (String)rec.get(fileLinkConfigByRecPrefix.get(objectPrefix).Last_Updated_By_API_Field_Name__c);
    }

    public static Datetime getLastUpdatedDateValue(SObject rec) {
        String objectPrefix = ((String)rec.Id).left(3);
        return (Datetime)rec.get(fileLinkConfigByRecPrefix.get(objectPrefix).Last_Updated_Date_API_Field_Name__c);
    }

    public static Decimal getFileLinkNumberValue(SObject rec) {
        String objectPrefix = ((String)rec.Id).left(3);
        return (Decimal)rec.get(fileLinkConfigByRecPrefix.get(objectPrefix).File_Links_Number_API_Field_Name__c);
    }

    public static String getObjectTypeName(SObject rec) {
        String objectPrefix = ((String)rec.Id).left(3);
        return (String)rec.get(fileLinkConfigByRecPrefix.get(objectPrefix).Object_API_Name__c);
    }

    public static SObject setParentRecord(Id recId, String fileLinks, Decimal fileLinkNumber) {
        String objectPrefix = ((String)recId).left(3);
        String objectApiName = fileLinkConfigByRecPrefix.get(objectPrefix).Object_API_Name__c;
        String fileLinksApiFieldName = fileLinkConfigByRecPrefix.get(objectPrefix).File_Links_API_Field_Name__c;
        String lastUpdatedByApiFieldName = fileLinkConfigByRecPrefix.get(objectPrefix).Last_Updated_By_API_Field_Name__c;
        String lastUpdatedDateApiFieldName = fileLinkConfigByRecPrefix.get(objectPrefix).Last_Updated_Date_API_Field_Name__c;
        String fileLinksNumber = fileLinkConfigByRecPrefix.get(objectPrefix).File_Links_Number_API_Field_Name__c;

        SObject thisRecord = Schema.getGlobalDescribe().get(objectApiName).newSObject();
        thisRecord.put('Id', recId);
        thisRecord.put(fileLinksApiFieldName, fileLinks);
        thisRecord.put(lastUpdatedByApiFieldName, UserInfo.getUserId());
        thisRecord.put(lastUpdatedDateApiFieldName, Datetime.now());
        thisRecord.put(fileLinksNumber, fileLinkNumber);

        return thisRecord;
    }

}