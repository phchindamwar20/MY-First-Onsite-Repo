/**
 * @description       : This is the test class for the FileLinkBatch
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-04-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class FileLinkBatchTest {
    //https://help.salesforce.com/s/articleView?id=000384323&type=1 contentdocumentlink not bulkified
    static Integer testAccRecNum = 1; //50, 100, 200 gives dlrs:Too many SQOL queries errors 
    static Integer testFileRecNum = 5;

    @TestSetup
    static void makeData() {
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=true;
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

        Test.startTest();
        insert fileLst;
        Test.stopTest();
    }

    @isTest 
    static void testFileLinkBatchDefaultConstructor() {
    	Test.startTest();
        FileLinkBatch flb = new FileLinkBatch();
        Database.executeBatch(flb,testAccRecNum);
        Test.stopTest();
        
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
    static void testFileLinkBatchObjectApiNameConstructor() {
    	Test.startTest();
        FileLinkBatch flb = new FileLinkBatch('Account');
        Database.executeBatch(flb,testAccRecNum);
        Test.stopTest();
        
        String fieldName = [SELECT File_Links_API_Field_Name__c FROM FileLinkServiceConfiguration__mdt WHERE Object_API_Name__c='Account' LIMIT 1].File_Links_API_Field_Name__c;

        List<Account> accLst = Database.query('SELECT Id, '+fieldName+' FROM Account');
        for (Account acc : accLst) {
            //the links should be different
            String htmlLink = (String)acc.get(fieldName);
            System.debug('~~~~ FileLinkServiceTest::testFileLinksInitial: htmlLink ' + htmlLink);
            System.assert(htmlLink.length() > 0 , 'Failed because no change');
        }
    }
}