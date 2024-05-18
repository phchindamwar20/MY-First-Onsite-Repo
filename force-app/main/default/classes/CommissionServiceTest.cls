/**
 * @description       : This is the test class for CommissionService class.  STAR-6037, STAR-6264
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-17-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class CommissionServiceTest {
    private static Integer numRecs = 2;  //reduced from  200 to 2 for speed purposes.... the batch that uses the service test at 200 records but without all the asserts

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
    private static void testCommissionRecordsCreation() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {
            //run test (should of been ran in setup test)
            Test.startTest();
            createJobCommissions();
            Test.stopTest();

            //verify expected job commission count = numRecs
            Assert.areEqual(numRecs, [SELECT Id FROM Job_Commission__c].size(), 'Failed:  created number of job commissions incorrect');
            
            //verify expected EC count = numRecs * 2
            Assert.areEqual(numRecs*2, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');
        
            //verify calculations for 1 job commissiona and associated employee commissions
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
            Assert.areEqual(750, [SELECT Id, Actual_Commission_Amount__c FROM Employee_Commission__c LIMIT 1].Actual_Commission_Amount__c, 'Failed:  Employee Commission Actual Commission Amount wrong');
        }
    }

    @istest
    private static void testCommissionRecordsCreationClosedJob() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {
            List<WorkOrder> jobUpdLst = new List<WorkOrder>();
            for (WorkOrder job : [SELECT Id FROM WorkOrder]) {
                jobUpdLst.add(new WorkOrder(Id=job.Id, Status=GeneralConstants.JOB_STATUS_CLOSED, Close_Date__c=Date.today(), Final_Margin__c=Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_2).Minimum_Margin_for_Tier__c+1));
            }
            update jobUpdLst;

            //run test (should of been ran in setup test)
            Test.startTest();
            createJobCommissions();
            Test.stopTest();

            //verify expected job commission count = numRecs
            Assert.areEqual(numRecs, [SELECT Id FROM Job_Commission__c].size(), 'Failed:  created number of job commissions incorrect');
            
            //verify expected EC count = numRecs * 2
            Assert.areEqual(numRecs*2, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');
        
            //verify calculations for 1 job commissiona and associated employee commissions
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
            Assert.areEqual(600, [SELECT Id, Actual_Commission_Amount__c FROM Employee_Commission__c LIMIT 1].Actual_Commission_Amount__c, 'Failed:  Employee Commission Actual Commission Amount wrong');

            //verify commission close date set
            CommissionCalTestUtility.assertJobCommissionCloseDate([SELECT Id, Job__r.Close_Date__c, Commission_Close_Date__c FROM Job_Commission__c LIMIT 1]);
        }        
    }

    @isTest
    private static void testRemoveBDRemoveEC() {
         //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //create job commissions and employee commissions
            createJobCommissions();
                        
            //pre verify expected EC count = numRecs * 2
            Assert.areEqual(numRecs*2, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');

            //remove BD2 from all jobs
            List<WorkOrder> jobUpdLst = new List<WorkOrder>();
            for (WorkOrder job : [SELECT Id FROM WorkOrder]) {
                jobUpdLst.add(new WorkOrder(Id=job.Id, BD_Account_Manager_2__c=null));
            }
            update jobUpdLst;
            
            //run test (should of been ran in setup test)
            Test.startTest();
            CommissionService sync = new CommissionService();
            sync.syncBdEcs([SELECT Id FROM Job_Commission__c]);
            Test.stopTest();

            //verify expected EC count = numRecs * 1
            Assert.areEqual(numRecs*1, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');
        
            //verify calculations for 1 job commissiona and associated employee commissions
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
            Assert.areEqual(1250, [SELECT Id, Actual_Commission_Amount__c FROM Employee_Commission__c LIMIT 1].Actual_Commission_Amount__c, 'Failed:  Employee Commission Actual Commission Amount wrong');
        }         
    }

    @isTest
    private static void testAddBDEC() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //create job commissions and employee commissions
            createJobCommissions();
                        
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
            CommissionService sync = new CommissionService();
            sync.syncBdEcs([SELECT Id FROM Job_Commission__c]);
            Test.stopTest();

            //verify expected EC count = numRecs * 3
            Assert.areEqual(numRecs*3, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');
        
            //verify calculations for 1 job commissiona and associated employee commissions
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
            Assert.areEqual(554.17, [SELECT Id, Actual_Commission_Amount__c FROM Employee_Commission__c LIMIT 1].Actual_Commission_Amount__c, 'Failed:  Employee Commission Actual Commission Amount wrong');
        } 
    }

    @isTest
    private static void testReplaceBDRemoveAddEC() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //create job commissions and employee commissions
            createJobCommissions();
                        
            //pre verify expected EC count = numRecs * 2
            Assert.areEqual(numRecs*2, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');

            //replace B2 on all jobs with a different commissionable sales user 
            WorkOrder sampleJob = [SELECT Id, BD_Account_Manager__c, BD_Account_Manager_2__c, BD_Account_Manager_3__c FROM WorkOrder LIMIT 1];
            User salesUser = [SELECT Id FROM User WHERE Sales_Commissionable_User__c=true AND Id !=: sampleJob.BD_Account_Manager__c AND Id !=: sampleJob.BD_Account_Manager_2__c LIMIT 1];
            Id oldBD2Id = sampleJob.BD_Account_Manager_2__c;

            List<WorkOrder> jobUpdLst = new List<WorkOrder>();
            for (WorkOrder job : [SELECT Id, BD_Account_Manager__c, BD_Account_Manager_2__c, BD_Account_Manager_3__c FROM WorkOrder]) {
                jobUpdLst.add(new WorkOrder(Id=job.Id, BD_Account_Manager_2__c=salesUser.Id));
            }
            update jobUpdLst;

            //run test (should of been ran in setup test)
            Test.startTest();
            CommissionService sync = new CommissionService();
            sync.syncBdEcs([SELECT Id FROM Job_Commission__c]);
            Test.stopTest();

            //verify expected EC count = numRecs * 2
            Assert.areEqual(numRecs*2, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');
            Assert.areEqual(0, [SELECT Id FROM Employee_Commission__c WHERE Employee__c=:oldBD2Id].size(), 'Failed: there aren\'t suppose to be any ecs matching the old BD2');
            Assert.areEqual(numRecs, [SELECT Id FROM Employee_Commission__c WHERE Employee__c=:salesUser.Id].size(), 'Failed: there aren\'t suppose to be any ecs matching the old BD2');
        
            //verify calculations for 1 job commissiona and associated employee commissions
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
            Assert.areEqual(750, [SELECT Id, Actual_Commission_Amount__c FROM Employee_Commission__c LIMIT 1].Actual_Commission_Amount__c, 'Failed:  Employee Commission Actual Commission Amount wrong');
        }         
    }

    @isTest
    private static void testIsEcsEligibleForSyncHappy() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //create job commissions and employee commissions
            createJobCommissions();

            //get job commission
            Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();

            //run test
            Test.startTest();
            CommissionService sync = new CommissionService();
            Assert.areEqual(true, sync.isEcsEligibleForSync(jobCom), 'Failed:  expected to be true because job commission meets requirements');
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testIsEcsEligibleForSyncNonOpenJC() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //create job commissions and employee commissions
            createJobCommissions();

            //update Job commission to non-open status
            Job_Commission__c jobCom =  [SELECT Id FROM Job_Commission__c LIMIT 1];
            jobCom.Commission_Status__c=SalesIncentivePlanConstants.JC_STATUS_FINALIZED;
            update jobCom;

            //get updated job commission
            jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();

            //run test
            Test.startTest();
            CommissionService sync = new CommissionService();
            Assert.areEqual(false, sync.isEcsEligibleForSync(jobCom), 'Failed:  expected to be false because job commission isn\'t open');
            Test.stopTest();
        }
    }

    @isTest
    private static void testIsEcsEligibleForSyncCustomSplitJC() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //create job commissions and employee commissions
            createJobCommissions();

            //update Job commission to non-open status
            Job_Commission__c jobCom =  [SELECT Id FROM Job_Commission__c LIMIT 1];
            jobCom.Custom_Splits__c=SalesIncentivePlanConstants.YES;
            update jobCom;

            //get updated job commission
            jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();

            //run test
            Test.startTest();
            CommissionService sync = new CommissionService();
            Assert.areEqual(false, sync.isEcsEligibleForSync(jobCom), 'Failed:  expected to be false because job commission has custom splits');
            Test.stopTest();
        }
    }

    @isTest
    private static void testIsEcsEligibleForSyncEcPaid() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //create job commissions and employee commissions
            createJobCommissions();

            //update Job commission to non-open status
            Employee_Commission__c empCom = [SELECT Id FROM Employee_Commission__c LIMIT 1];
            empCom.Status__c = SalesIncentivePlanConstants.EC_STATUS_PAID;
            update empCom;

            //get updated job commission
            Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();

            //run test
            Test.startTest();
            CommissionService sync = new CommissionService();
            Assert.areEqual(false, sync.isEcsEligibleForSync(jobCom), 'Failed:  expected to be false because job commission has custom splits');
            Test.stopTest();
        }
    }    

    @isTest
    private static void testIsEcsEligibleForSyncMoreThan3() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //create job commissions and employee commissions
            createJobCommissions();

            //update Job commission to non-open status
            Job_Commission__c jobCom =  [SELECT Id, Job__c FROM Job_Commission__c LIMIT 1];
            User nonComSales = [SELECT Id FROM User WHERE Sales_Commissionable_User__c=false LIMIT 1];
            Employee_Commission__c empCom = new Employee_Commission__c(Job__c=jobCom.Job__c, Job_Commission__c=jobCom.Id, Employee__c=nonComSales.Id, Individual_Split_Percentage__c=0);
            insert empCom;

            //get updated job commission
            jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();

            //run test
            Test.startTest();
            CommissionService sync = new CommissionService();
            Assert.areEqual(false, sync.isEcsEligibleForSync(jobCom), 'Failed:  expected to be false because job commission has custom splits');
            Test.stopTest();
        }
    }

    @isTest
    private static void testIsEcsEligibleForSyncEcNonCommissionableSales() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //create job commissions and employee commissions
            createJobCommissions();

            //update Job commission to non-open status
            Employee_Commission__c empCom = [SELECT Id, Employee__c FROM Employee_Commission__c LIMIT 1];
            User ecUser = new User(Id=empCom.Employee__c, Sales_Commissionable_User__c=false);
            update ecUser;

            //get updated job commission
            Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();

            //run test
            Test.startTest();
            CommissionService sync = new CommissionService();
            Assert.areEqual(false, sync.isEcsEligibleForSync(jobCom), 'Failed:  expected to be false because job commission has custom splits');
            Test.stopTest();
        }
    }     


    @isTest
    private static void testAddBDECActualDifferentThanDefault() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {

            //create job commissions and employee commissions
            createJobCommissions();
                        
            //pre verify expected EC count = numRecs * 2
            Assert.areEqual(numRecs*2, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');

            //add BD3 to all jobs
            WorkOrder sampleJob = [SELECT Id, BD_Account_Manager__c, BD_Account_Manager_2__c FROM WorkOrder LIMIT 1];
            User salesUser = [SELECT Id FROM User WHERE Sales_Commissionable_User__c=true AND Id !=: sampleJob.BD_Account_Manager__c AND Id !=: sampleJob.BD_Account_Manager_2__c LIMIT 1];

            //update job with BD and making job in collections
            List<WorkOrder> jobUpdLst = new List<WorkOrder>();
            for (WorkOrder job : [SELECT Id, BD_Account_Manager__c, BD_Account_Manager_2__c FROM WorkOrder]) {
                jobUpdLst.add(new WorkOrder(Id=job.Id, BD_Account_Manager_3__c=salesUser.Id, In_Collections__c=true));
            }
            update jobUpdLst;

            //simulate override commissionable
            List<Job_Commission__c> jobComLst = new List<Job_Commission__c>();
            for (Job_Commission__c jobCom : [SELECT Id FROM Job_Commission__c]) {
                jobComLst.add(new Job_Commission__c(Id=jobCom.Id, Actual_Commissionable__c=SalesIncentivePlanConstants.YES, Exception_Commissionable__c=SalesIncentivePlanConstants.YES));
            }
            update jobComLst;
            
            //run test (should of been ran in setup test)
            Test.startTest();
            CommissionService sync = new CommissionService();
            sync.syncBdEcs([SELECT Id FROM Job_Commission__c]);
            Test.stopTest();

            //verify expected EC count = numRecs * 3
            Assert.areEqual(numRecs*3, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');
        
            //verify calculations for 1 job commissiona and associated employee commissions
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
            Assert.areEqual(554.17, [SELECT Id, Actual_Commission_Amount__c FROM Employee_Commission__c LIMIT 1].Actual_Commission_Amount__c, 'Failed:  Employee Commission Actual Commission Amount wrong');
            Assert.areEqual(0, [SELECT Id, Default_Commission_Amount__c FROM Employee_Commission__c LIMIT 1].Default_Commission_Amount__c, 'Failed:  Employee Commission Default Commission Amount wrong');
        } 
    }  
    
    @istest
    private static void testAllBdsRemovedFromJob() {
        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {
            List<WorkOrder> jobUpdLst = new List<WorkOrder>();
            for (WorkOrder job : [SELECT Id FROM WorkOrder]) {
                jobUpdLst.add(new WorkOrder(Id=job.Id, BD_Account_Manager__c=null, BD_Account_Manager_2__c=null, BD_Account_Manager_3__c=null));
            }
            update jobUpdLst;

            //run test (should of been ran in setup test)
            Test.startTest();
            createJobCommissions();
            Test.stopTest();

            //verify expected job commission count = numRecs
            Assert.areEqual(numRecs, [SELECT Id FROM Job_Commission__c].size(), 'Failed:  created number of job commissions incorrect');
            
            //verify expected EC count = numRecs * 0
            Assert.areEqual(numRecs*0, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');
        
            //verify calculations for 1 job commissiona and associated employee commissions
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
        }        
    }    

    private static void createJobCommissions() {
          //turn off data admin for all but flow only
          TestFactory.turnOffDataAdmin(true, true, true, true, false, new User(Id=System.UserInfo.getUserId()));
  
          //create initial job commissions
          CommissionService comSer = new CommissionService();
          comSer.createJobCommissions([SELECT Id FROM WorkOrder]);     
    }
}