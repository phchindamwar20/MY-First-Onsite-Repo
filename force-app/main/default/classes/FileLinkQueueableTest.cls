/**
 * @description       : This test the SelectionFileLinksContentDocumentLinks and FileLinkQueueable
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-10-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class FileLinkQueueableTest {
    //https://help.salesforce.com/s/articleView?id=000384323&type=1 contentdocumentlink not bulkified
    static Integer testAccRecNum = 1; //50, 100, 200 gives dlrs:Too many SQOL queries errors 
    static Integer testFileRecNum = 1; //5 doesn't work with platform events test classes

    @TestSetup
    static void makeData() {
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.TurnOffFlow__c=true;
        if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
            dataAdmin.SetupOwnerId = UserInfo.getUserId();
            insert dataAdmin;  
        }
        else {
            update dataAdmin;
        } 

        //make accounts
        List<Account> accLst = new List<Account>();
        for (Integer i=0 ; i<testAccRecNum ; i++) {
            accLst.add((Account)TestFactory.createSObject(new Account(Name='Test Account ' + String.valueOf(i)), 'TestFactoryDefaults.AccountDefaults'));
        }
        insert accLst;

        //make files for each account
        List<ContentVersion> fileLst = new List<ContentVersion>();
        for (Account acc : accLst) {
            for (Integer i=0; i<testFileRecNum; i++) {
                fileLst.add(new ContentVersion(FirstPublishLocationId=acc.Id, PathOnClient='testDoc'+String.valueOf(i)+'.txt', Title='testDoc'+String.valueOf(i), VersionData=Blob.valueOf('Test Body!!')));
            }
        }

        insert fileLst;
    }

    @isTest
    private static void testSelectionAndQueueable(){
        Map<Id, ContentDocumentLink> cdlLst = new Map<Id, ContentDocumentLink>([SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN: (new Map<Id, Account>([SELECT Id FROM Account])).keySet()]);

        ExecutionService es = new ExecutionService();
        Test.startTest();
        es.buildAndKickoffQueueableJobs(GeneralConstants.OBJ_CONTENT_DOCUMENT_LINK, GeneralConstants.AFTER_INSERT, cdlLst, null);
        Test.stopTest();

        String fieldName = [SELECT File_Links_API_Field_Name__c FROM FileLinkServiceConfiguration__mdt WHERE Object_API_Name__c='Account' LIMIT 1].File_Links_API_Field_Name__c;
        List<Account> accOrgLst = Database.query('SELECT Id, '+fieldName+' FROM Account');

        for (Account acc : accOrgLst) {
            //the newly constructed links should be a null size than the old version of the links should have a larger size because we deleted files from the account
            String newValue = (String)acc.get(fieldName);
            System.assert(newValue.length() > 0, 'Failed because no change, new value not null');
        }
    }
}