/**
 * @description       : This class test both SyncBdsToEmplyeeCommissionsBatch and SyncBdsToEmployeeCommissionsSchedule
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-02-2024
 * @last modified by  : Terri Jiles
**/
@isTest
private without sharing class SyncBdsToEmployeeCommissionsTest {
    //private static Integer numRecs = 50; //numbers that don't work due to CPU Timeout Limit error: 200, 190, 180, 150, 100
    private static Integer  numRecs = Integer.valueOf(Apex_Job_Configuration__mdt.getInstance('SyncBdsToEmployeeCommissionsBatch').Batch_Size__c);

    @TestSetup
    private static void makeData(){

        System.runAs(new User (Id=UserInfo.getUserId())) {
            TestFactory.turnOffDataAdminAll();
            Map<String, ServiceTerritory> serviceTerritoryByNameMap = TestFactory.createServiceTerritories();

            TestFactory.createUsersNonFuture();
            List<User> salesUsers = [SELECT Id FROM User WHERE Sales_Commissionable_User__c=true];
            System.debug('~~~~~ CommissionServiceTest::makeData: users.size - ' + [SELECT Id FROM User LIMIT 20].size());
            
            //create numRecs accounts
            List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(), numRecs, 'TestFactoryDefaults.AccountDefaults', true);

            //create numRecs properties
            List<Account> propLst =  new List<Account>();
            for (Account acc : accLst) {
                propLst.add((Account)TestFactory.createSObject(new Account(ParentId=acc.Id), 'TestFactoryDefaults.PropertyDefaults', false));
            }
            insert propLst;

            //create numRec jobs with 2 commissionable bds each
            Id branchId = [SELECT Id FROM ServiceTerritory WHERE IsActive=true LIMIT 1][0].Id;

            System.debug('~~~~ CommissionServiceTest::makeData: salesUsers - ' + salesUsers.size());
            List<WorkOrder> jobLst = new List<WorkOrder>();
            for (Integer i=0 ; i<numRecs ; i++) {
                jobLst.add((WorkOrder)CommissionCalTestUtility.createCommissionableJobsList(2, salesUsers, accLst[i].Id, propLst[i].Id, branchId, false));
            }
            Test.startTest();
            insert jobLst; 
            Test.stopTest(); 
            
        }
    }


    @isTest
    private static void testBatch() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //turn off data admin for all but flow only
            TestFactory.turnOffDataAdmin(true, true, true, true, false, new User(Id=System.UserInfo.getUserId()));
    
            //create initial job commissions
            CommissionService comSer = new CommissionService();
            comSer.createJobCommissions([SELECT Id FROM WorkOrder]);
                        
            //pre verify expected EC count = numRecs * 2
            Assert.areEqual(numRecs*2, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');

            //add BD3 to all jobs
            WorkOrder sampleJob = [SELECT Id, BD_Account_Manager__c, BD_Account_Manager_2__c FROM WorkOrder LIMIT 1];
            User salesUser = [SELECT Id FROM User WHERE Sales_Commissionable_User__c=true AND Id !=: sampleJob.BD_Account_Manager__c AND Id !=: sampleJob.BD_Account_Manager_2__c LIMIT 1];

            List<WorkOrder> jobUpdLst = new List<WorkOrder>();
            for (WorkOrder job : [SELECT Id, BD_Account_Manager__c, BD_Account_Manager_2__c FROM WorkOrder]) {
                jobUpdLst.add(new WorkOrder(Id=job.Id, BD_Account_Manager_3__c=salesUser.Id));
            }
            update jobUpdLst;
            
            //run test (should of been ran in setup test)
            Test.startTest();
            SyncBdsToEmployeeCommissionsBatch b = new SyncBdsToEmployeeCommissionsBatch();
            b.executeBatchJob();
            Test.stopTest();

            //verify expected EC count = numRecs * 3
            Assert.areEqual(numRecs*3, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');
        
            //verify calculations for 1 associated employee commissions
            Assert.areEqual(554.17, [SELECT Id, Actual_Commission_Amount__c FROM Employee_Commission__c LIMIT 1].Actual_Commission_Amount__c, 'Failed:  Employee Commission Actual Commission Amount wrong');

            //test cancel job
            SyncBdsToEmployeeCommissionsBatch b2 = new SyncBdsToEmployeeCommissionsBatch();
            b2.executeBatchJob();
            b2.cancelBatchJob();
        } 
    }

    @isTest
    private static void testSchedule() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {
            //turn off data admin for all but flow only
            TestFactory.turnOffDataAdmin(true, true, true, true, false, new User(Id=System.UserInfo.getUserId()));
    
            //create initial job commissions
            CommissionService comSer = new CommissionService();
            comSer.createJobCommissions([SELECT Id FROM WorkOrder]);
                        
            //pre verify expected EC count = numRecs * 2
            Assert.areEqual(numRecs*2, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');

            //add BD3 to all jobs
            WorkOrder sampleJob = [SELECT Id, BD_Account_Manager__c, BD_Account_Manager_2__c FROM WorkOrder LIMIT 1];
            User salesUser = [SELECT Id FROM User WHERE Sales_Commissionable_User__c=true AND Id !=: sampleJob.BD_Account_Manager__c AND Id !=: sampleJob.BD_Account_Manager_2__c LIMIT 1];

            List<WorkOrder> jobUpdLst = new List<WorkOrder>();
            for (WorkOrder job : [SELECT Id, BD_Account_Manager__c, BD_Account_Manager_2__c FROM WorkOrder]) {
                jobUpdLst.add(new WorkOrder(Id=job.Id, BD_Account_Manager_3__c=salesUser.Id));
            }
            update jobUpdLst;
            
            //run test (should of been ran in setup test)
            SyncBdsToEmployeeCommissionsSchedule j = new SyncBdsToEmployeeCommissionsSchedule();
            String actualJobName = j.getActualJobName();
            String jobName =j.getJobName();

            Test.startTest();
            String jobId = j.scheduleJob();
            Test.stopTest();

            CronTrigger chronInfo = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id=:jobId AND CronJobDetail.Name=:actualJobName];

            //verify chron expression expected
            Assert.areEqual(Apex_Job_Configuration__mdt.getInstance(jobName).Chron_Expression__c, chronInfo.CronExpression, 'Failed: Chron expression does not match');

            //verify has a next fire time
            Assert.areEqual(true, chronInfo.NextFireTime != null, 'Failed:  Does not have a next fire time');

            //test canceling job
            j.cancelScheduledJob();

            Assert.areEqual(0, [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: actualJobName].size(), 'Failed:  expected there not be be a scheduled job');
        }
    }
}