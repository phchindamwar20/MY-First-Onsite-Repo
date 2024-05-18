/**
 * @description       : This test the FileLinkService class
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-10-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public with sharing class FileLinkServiceTest {
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

        Test.startTest();
        FileLinkService.buildFileLinks([SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:(new Map<Id,Account>(accLst)).keySet()]);
        Test.stopTest();
    }

    @isTest 
    static void testFileLinksInitial() {
        String fieldName = [SELECT File_Links_API_Field_Name__c FROM FileLinkServiceConfiguration__mdt WHERE Object_API_Name__c='Account' LIMIT 1].File_Links_API_Field_Name__c;

        List<Account> accLst = Database.query('SELECT Id, '+fieldName+' FROM Account');
        for (Account acc : accLst) {
            //the links should be different
            String htmlLink = (String)acc.get(fieldName);
            System.debug('~~~~ FileLinkServiceTest::testFileLinksInitial: htmlLink ' + htmlLink);
            System.assert(htmlLink.length() > 0 , 'Failed because no change');
        }
    }

    @isTest
    static void testFileLinksAddMore() {
        String fieldName = [SELECT File_Links_API_Field_Name__c FROM FileLinkServiceConfiguration__mdt WHERE Object_API_Name__c='Account' LIMIT 1].File_Links_API_Field_Name__c;
        Map<Id, Account> accOrgById = new Map<Id, Account>((List<Account>)Database.query('SELECT Id, '+fieldName+' FROM Account'));

        //make files for each account
        List<ContentVersion> fileLst = new List<ContentVersion>();
        for (Account acc : accOrgById.values()) {
            for (Integer i=0; i<testFileRecNum; i++) {
                fileLst.add(new ContentVersion(FirstPublishLocationId=acc.Id, PathOnClient='testDoc'+String.valueOf(i)+'.txt', Title='testDoc'+String.valueOf(i), VersionData=Blob.valueOf('Test Body!!')));
            }
        }

        insert fileLst;

        Test.startTest();
        FileLinkService.buildFileLinks([SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:accOrgById.keySet()]);
        Test.stopTest();        

        List<Account> updAccLst = Database.query('SELECT Id, '+fieldName+' FROM Account');
        Map<Id, Account> accUpdById = new Map<Id, Account> (updAccLst);

        for (Account acc : accOrgById.values()) {
            //the newly constructed links should be a bigger size than the old version of the links because we added more files to the account
            String oldValue = acc.get(fieldName) != null ? (String)acc.get(fieldName) : null;
            String newValue =  accUpdById.containsKey(acc.Id) && accUpdById.get(acc.Id).get(fieldName) != null ? (String)accUpdById.get(acc.Id).get(fieldName) : null;
            System.assert(oldValue.length() < newValue.length() , 'Failed because no change');
        }
    }

    @isTest
    static void testFileLinksDelete(){
        String fieldName = [SELECT File_Links_API_Field_Name__c FROM FileLinkServiceConfiguration__mdt WHERE Object_API_Name__c='Account' LIMIT 1].File_Links_API_Field_Name__c;
        List<Account> accOrgLst = Database.query('SELECT Id, '+fieldName+' FROM Account');

        Test.startTest();
        delete [SELECT Id FROM ContentDocument];
        Test.stopTest();
        
        List<Account> updAccLst = Database.query('SELECT Id, '+fieldName+' FROM Account');
        Map<Id, Account> accUpdById = new Map<Id, Account> (updAccLst);

        for (Account acc : accOrgLst) {
            //the newly constructed links should be a null size than the old version of the links should have a larger size because we deleted files from the account
            String oldValue = (String)acc.get(fieldName);
            String newValue =  (String)accUpdById.get(acc.Id).get(fieldName);
            System.assert(oldValue.length() > 0 && String.isBlank(newValue) , 'Failed because no change, new value not null');
        }
    }

    //Unable to test with platform events undelete.  The trigger doesn't fire.  Manually testing undeletes work as expected.
    /*@isTest
    static void testFileLinksUndelete() {
        Test.startTest();
        Map<Id, ContentDocument> fileById = new Map<Id, ContentDocument>([SELECT Id FROM ContentDocument]);
        delete fileById.values();    
        Test.stopTest();
        System.debug('~~~~ FileLinkServiceTest::testFileLinkUndelete: Content Documents Deleted Count - ' + [SELECT Id FROM ContentDocumentLink WHERE Id IN : fileById.keySet()].size());
        
        String fieldName = [SELECT File_Links_API_Field_Name__c FROM FileLinkServiceConfiguration__mdt WHERE Object_API_Name__c='Account' LIMIT 1].File_Links_API_Field_Name__c;
        List<Account> accOrgLst = Database.query('SELECT Id, '+fieldName+' FROM Account');
        System.debug('~~~~ FileLinkServiceTest::testFileLinksUndelete: accOrgLst - ' + accOrgLst);

        TriggerDispatcher.tc.clear();
        System.debug('~~~~ FileLinkServiceTest::testFileLinksUndelete: before');
        //undeleteLst(fileById.keySet());
        undelete [SELECT Id FROM ContentDocument WHERE Id IN: fileById.keySet() AND IsDeleted=true];
        System.debug('~~~~ FileLinkServiceTest::testFileLinksUndelete: after');       

        List<Account> updAccLst = Database.query('SELECT Id, '+fieldName+' FROM Account');
        Map<Id, Account> accUpdById = new Map<Id, Account> (updAccLst);

        for (Account acc : accOrgLst) {
            //the newly constructed links should have a size greater than 0 and the old version should be null because we undeleted the files associated with the account
            String oldValue = (String)acc.get(fieldName) != null ? (String)acc.get(fieldName) : '';
            String newValue =  (String)accUpdById.get(acc.Id).get(fieldName) != null ? (String)accUpdById.get(acc.Id).get(fieldName) : '';
            System.debug('~~~~ FileLinkServiceTest::testFileLinkUndelete:oldValue - ' + oldValue + ', newValue - ' + newValue);
            System.assert(String.isBlank(oldValue) && newValue.length() > 0, 'Failed because no change, undelete resulted in no links restored');
        }
    }*/

    @future
    private static void undeleteLst(Set<Id> ids) {
        Test.startTest();
        undelete [SELECT Id FROM ContentDocument WHERE Id IN: ids];   
        Test.stopTest();
    }

        
}