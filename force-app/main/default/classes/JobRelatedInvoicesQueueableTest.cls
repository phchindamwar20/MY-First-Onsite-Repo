/**
 * @description       : This is the test class for JobRelatedInvoiceQueueable, JobRelatedInvoiceService, and SelectionJobRelatedInvoices
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-25-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public with sharing class JobRelatedInvoicesQueueableTest {
    private static Integer numTestRecs = 200;
    private static Integer numInvoiceRecsPerJob = 10;
    private static String QUE_CLASS = 'JobRelatedInvoicesQueueable';
    private static String SEL_CLASS = 'SelectionJobRelatedInvoices';
    private static String ACC_NAME_1='Account Name 1', ACC_NAME_2='Account Name 2';

    @TestSetup
    private static void makeData(){
        TestFactory.turnOffDataAdminAll(); 

        //create users
        Test.startTest();
        TestFactory.createUsers();
        Test.stopTest();
        //User runningUser = [SELECT Id FROM User WHERE IsActive=true AND Alias = 'BDA' LIMIT 1];

        //System.runAs(runningUser) {
        //    TestFactory.turnOffDataAdminAll(runningUser);

            //create account
            Account acc = (Account)TestFactory.createSObject(new Account(Name=ACC_NAME_1), 'TestFactoryDefaults.AccountDefaults', true);   
            Account acc2 = (Account)TestFactory.createSObject(new Account(Name=ACC_NAME_2), 'TestFactoryDefaults.AccountDefaults', true);   
            
            //create jobs
            List<WorkOrder> jobLst = new List<WorkOrder>();
            for (Integer i=0 ; i < numTestRecs ; i++) {
                jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id), 'TestFactoryDefaults.JobDefaults'));
            }
            insert jobLst;

            //create invoices
            List<Invoice__c> invoiceLst = new List<Invoice__c>();
        	Integer j=0;
            for (WorkOrder job : jobLst) {
                for (Integer i=0 ; i < numInvoiceRecsPerJob ; i++) {
                    invoiceLst.add((Invoice__c)TestFactory.createSObject(new Invoice__c(Account__c=job.AccountId, Job__c=job.Id, Invoice_Number__c=String.valueOf(j)+'-'+String.valueOf(i)), 'TestFactoryDefaults.InvoiceDefaults'));
                    j++;
                }
            }
            insert invoiceLst;
        //}
    }

    @isTest
    private static void testChangeAccountOnInvoice() {
        //setup data
        Account acc2 = [SELECT Id FROM Account WHERE Name =: ACC_NAME_2 LIMIT 1];
        Map<Id, WorkOrder> jobOldById = new Map<Id, WorkOrder>([SELECT Id, AccountId FROM WorkOrder]);
        Map<Id, WorkOrder> jobNewById = new Map<Id, WorkOrder>();
        for (WorkOrder job : jobOldById.values()) {
            jobNewById.put(job.Id, new WorkOrder(Id=job.Id, AccountId=acc2.Id));
        }
        //User runningUser = [SELECT Id FROM User WHERE IsActive=true AND Alias = 'BDA' LIMIT 1];

        //System.runAs(runningUser) {
            //TestFactory.turnOffDataAdminAll(runningUser);
            update jobNewById.values();

            List<ExecutionItem> eiLst = new List<ExecutionItem>();
            eiLst.add(new ExecutionItem(QUE_CLASS, 1, SEL_CLASS, GeneralConstants.AFTER_UPDATE, GeneralConstants.OBJ_JOB, jobNewById, jobOldById));

            //test
            Test.startTest();
            ExecutionService es = new ExecutionService();
            es.executeInitialHandler(eiLst);
            Test.stopTest();

            //verify
            Integer totalInvoiceNum = numTestRecs * numInvoiceRecsPerJob;
            System.assertEquals(totalInvoiceNum, [SELECT Id FROM Invoice__c WHERE Account__c=:acc2.Id].size(), 'Failed:  The account wasn\'t set on the related invoices');
        //}
    }
}