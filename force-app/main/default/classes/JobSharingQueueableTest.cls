/**
 * @description       : This test JobSharingQueueable class
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-21-2023
 * @last modified by  : Terri Jiles
**/
@isTest
private with sharing class JobSharingQueueableTest {
    private static Integer numUsers = 0;
    private static Integer numJobs = 200;
    private static String QUE_CLASS = 'JobSharingQueueable';
    private static String SEL_CLASS = 'SelectionJobSharing';

    @TestSetup
    private static void makeData(){
        TestFactory.turnOffDataAdminAll(); 
        
        //create users
        Test.startTest();
        TestFactory.createUsers();
        Test.stopTest();
        List<User> userLst = [SELECT Id FROM User WHERE IsActive=true AND (Alias LIKE 'ATM%' OR Alias = 'Owner')];

        numUsers = userLst.size();
        
        //create account
        Account acc = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.AccountDefaults', true);   
        List<AccountTeamMember> atmLst = new List<AccountTeamMember>();

        //create account team members
        for (User u : userLst) {
            atmLst.add((AccountTeamMember)TestFactory.createSObject(new AccountTeamMember(AccountId=acc.Id, UserId=u.Id), 'TestFactoryDefaults.AccountTeamMemberDefaults', false));   
        }
        //create atm that has same owner as job
        atmLst.add((AccountTeamMember)TestFactory.createSObject(new AccountTeamMember(AccountId=acc.Id, UserId=UserInfo.getUserId()), 'TestFactoryDefaults.AccountTeamMemberDefaults', false));   
        insert atmLst;

        //create jobs
        List<WorkOrder> jobLst = new List<WorkOrder>();
        for (Integer i=0 ; i < numJobs ; i++) {
            jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id, OwnerId=UserInfo.getUserId()), 'TestFactoryDefaults.JobDefaults', false));
        }
        insert jobLst;

        //create job sharing for 1 account team member
        List<Job_Sharing__c> jobSharingLst = new List<Job_Sharing__c>();
        for (WorkOrder job : jobLst) {
            jobSharingLst.add(new Job_Sharing__c(Job__c=job.Id, User__c=atmLst[0].UserId));
        }
        insert jobSharingLst;
    }

    @isTest 
    private static void testJobSharingFromAtmInsert() {
        //setup data
        Map<Id, WorkOrder> jobById = new Map<Id, WorkOrder>([SELECT Id, OwnerId, AccountId FROM WorkOrder]);

        List<ExecutionItem> eiLst = new List<ExecutionItem>();
        eiLst.add(new ExecutionItem(QUE_CLASS, 1, SEL_CLASS, GeneralConstants.AFTER_INSERT, GeneralConstants.OBJ_JOB, jobById, null));

        //test
        Test.startTest();
        ExecutionService es = new ExecutionService();
        es.executeInitialHandler(eiLst);
        Test.stopTest();

        //verify
        Integer numJobSharesExpected = ([SELECT Id FROM AccountTeamMember].size()-1) * numJobs;

        //Total Number of Job Sharing should match ATMs numbers where the ATM user isn't the same as Job Owner
        System.assertEquals(numJobSharesExpected, [SELECT Id FROM Job_Sharing__c].size(), 'Failed: number of job shares created incorrect' );
    }

    @isTest 
    private static void testJobSharingFromAtmUpdate() {
        //setup data
        Map<Id, WorkOrder> jobOldById = new Map<Id, WorkOrder>([SELECT Id, OwnerId, AccountId FROM WorkOrder]);
        User u = [SELECT Id FROM User WHERE (Alias LIKE 'ATM%' OR Alias = 'Owner') LIMIT 1];
        Map<Id, WorkOrder> jobNewById = new Map<Id, WorkOrder>();
        for (WorkOrder wo : jobOldById.values()) {
            jobNewById.put(wo.Id, new WorkOrder(Id=wo.Id, OwnerId=u.Id, AccountId=wo.AccountId));
        }
        update jobNewById.values();

        List<ExecutionItem> eiLst = new List<ExecutionItem>();
        eiLst.add(new ExecutionItem(QUE_CLASS, 1, SEL_CLASS, GeneralConstants.AFTER_INSERT, GeneralConstants.OBJ_JOB, jobNewById, jobOldById));

        //test
        Test.startTest();
        ExecutionService es = new ExecutionService();
        es.executeInitialHandler(eiLst);
        Test.stopTest();

        //verify
        Integer numJobSharesExpected = ([SELECT Id FROM AccountTeamMember].size()-1) * numJobs;

        //Total Number of Job Sharing should match ATMs numbers where the ATM user isn't the same as Job Owner
        System.assertEquals(numJobSharesExpected, [SELECT Id FROM Job_Sharing__c].size(), 'Failed: number of job shares created incorrect' );
    }    

    @isTest
    private static void testSelection() {
        SelectionJobSharing selection = new SelectionJobSharing();

        User u=[SELECT Id FROM User WHERE (Alias LIKE 'ATM%' OR Alias = 'Owner') LIMIT 1];
        Account acc = (Account)TestFactory.createSObject(new Account(Name='Test Account 2'), 'TestFactoryDefaults.AccountDefaults', true);  

        WorkOrder oldJob = [SELECT Id, AccountId, OwnerId FROM WorkOrder LIMIT 1];
        WorkOrder newJob = new WorkOrder(Id=oldJob.Id, AccountId=oldJob.AccountId, OwnerId=u.Id);
        WorkOrder newJob2 = new WorkOrder(Id=oldJob.id, AccountId=acc.Id, OwnerId=oldJob.OwnerId);

        Test.startTest();
        Boolean result = selection.selectJob(newJob, oldJob);
        Boolean result2 = selection.selectJob(newJob2, oldJob);
        Boolean result3 = selection.selectJob(oldJob, oldJob);
        Boolean result4 = selection.selectJob(oldJob, null);
        Test.stopTest();

        System.assertEquals(true, result, 'Failed:  didn\'t detect change in owner');
        System.assertEquals(true, result2, 'Failed:  didn\'t detect change in account');
        System.assertEquals(false, result3, 'Failed:  shouldn\'t of selected a job because there was no change');
        System.assertEquals(true, result4, 'Failed:  should of selected job because it is a new job');
    }
}