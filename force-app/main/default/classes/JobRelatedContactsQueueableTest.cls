/**
 * @description       : This test class test the following classes:  JobRelatedContactsQueueable, JobRelatedContactsService, and SelectionJobRelatedContacts
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-22-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public with sharing class JobRelatedContactsQueueableTest {
    private static Integer numTestRecs = 200;
    private static String QUE_CLASS = 'JobRelatedContactsQueueable';
    private static String SEL_CLASS = 'SelectionJobRelatedContacts';

    @TestSetup
    private static void makeData(){
        TestFactory.turnOffDataAdminAll(); 
        //create account
        Account acc = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.AccountDefaults', true);   
        
        //create contacts
        List<Contact> conLst = (List<Contact>)TestFactory.createSObjectList(new Contact(AccountId=acc.Id), numTestRecs, 'TestFactoryDefaults.ContactDefaults', true);

        //create jobs
        List<WorkOrder> jobLst = new List<WorkOrder>();
        for (Contact con : conLst) {
            jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id, Referred_By__c=con.Id), 'TestFactoryDefaults.JobDefaults'));
        }
        insert jobLst;
    }

    @isTest
    private static void testReferredByDate() {
        Map<Id, WorkOrder> jobById = new Map<Id, WorkOrder>([SELECT Id, Referred_By__c FROM WorkOrder]);
        List<ExecutionItem> eiLst = new List<ExecutionItem>();
        eiLst.add(new ExecutionItem(QUE_CLASS, 1, SEL_CLASS, GeneralConstants.AFTER_INSERT, GeneralConstants.OBJ_JOB, jobById, null));

        //test
        Test.startTest();
        ExecutionService es = new ExecutionService();
        es.executeInitialHandler(eiLst);
        Test.stopTest();

        //verify
        System.assertEquals(numTestRecs, [SELECT Id FROM Contact WHERE Last_Referral_Date__c =: Date.today()].size(), 'Failed:  The referred date wasn\'t set on the related contacts');
    }
}