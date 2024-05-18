/**
 * @description       : This is the test class for ContentDocumentLinkTriggerHandler
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-26-2023
 * @last modified by  : Terri Jiles
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   08-03-2021   Terri Jiles                          Initial Version
**/
@isTest
private class ContentDocumentLinkTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        //make parent data jobs and a contract
        //only doing this for a small portion of jobs, because in all likelyhood files can't be loaded in bulk operations due to transaction
        //Update -- Salesforce won't allow me to create ContentVersion documents in bulk for Email Messages.  The ContentDocumentLinkTrigger fires only for one emailMessage and the associated Account/User/Contact
        TestFactory.createJobTestData(1);

        //create email messages
        List<EmailMessage> emailMsgLst = new List<EmailMessage>();
        for (WorkOrder job : [SELECT Id FROM WorkOrder]) {
            emailMsgLst.add(new EmailMessage(RelatedToId=job.Id, Incoming=true, Subject='Test', htmlBody = '<html><body><b>Hello</b></body></html>', fromAddress='testFrom@test.com', toAddress='testTo@test.com'));
        }
        insert emailMsgLst;
        System.debug('~~~~~ ContentDocumentLinkTriggerHandlerTest::makeData: emailMsgLst.size() - ' + emailMsgLst.size());
    }

    @isTest
    static private void testJobFile() {
        Set<Id> jobIds = new Set<Id>();

        for (WorkOrder job : [SELECT Id FROM WorkOrder]) {
            jobIds.add(job.Id);
        }

        //create files
        List<ContentVersion> fileLst = new List<ContentVersion>();
        for (EmailMessage email : [SELECT Id FROM EmailMessage WHERE RelatedToId In: jobIds]) {
            fileLst.add(new ContentVersion(FirstPublishLocationId=email.Id, PathOnClient='testDoc.txt', Title='testDoc', VersionData=Blob.valueOf('Test Body!!')));
        }

        test.startTest();
        insert fileLst;
        test.stopTest();

        System.assertEquals(jobIds.size(), [SELECT Id FROM ContentDocumentLink WHERE Visibility='AllUsers' AND LinkedEntityId In: jobIds].size(), 'ContentDocumentLink records not created for the job');
    }

    @isTest
    static private void testContractFile() {
        Id contractId = [SELECT Id FROM Contract Limit 1].Id;
        
        
        EmailMessage emailMsg = new EmailMessage(RelatedToId=contractId, Incoming=true, Subject='Test', htmlBody = '<html><body><b>Hello</b></body></html>', fromAddress='testFrom@test.com', toAddress='testTo@test.com');
        insert emailMsg;

        ContentVersion file = new ContentVersion(FirstPublishLocationId=contractId, PathOnClient='testDoc.txt', Title='testDoc', VersionData=Blob.valueOf('Test Body!!'));
        test.startTest();
        insert file;
        test.stopTest();
        
        System.assertEquals(1, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId=:contractId].size(), 'ContentDocumentLink records not created for the contract');
    }
}