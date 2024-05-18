/**
 * @description       : STAR-6037 test class for intializing commissions
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-26-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class InitializeCommissionsBatchTest {
    private static Integer numRecs = 200;

    @TestSetup
    private static void makeData(){
        //TestFactory.turnOffDataAdminAll();

        System.runAs(new User (Id=UserInfo.getUserId())) {
        //List<User> salesUsers = CommissionCalTestUtility.getSalesCommissionableUsers(); <-- this calls TestFactory.createUsers()
            TestFactory.turnOffDataAdminAll();
            Map<String, ServiceTerritory> serviceTerritoryByNameMap = TestFactory.createServiceTerritories();

            TestFactory.createUsersNonFuture();
                //TestFactory.createUsers(); <-- @future
                //List<User> salesUsers = [SELECT Id FROM User WHERE LastName LIKE 'BDAccountManager%'];
            List<User> salesUsers = [SELECT Id FROM User WHERE Sales_Commissionable_User__c=true];
                //List<User> salesUsers = CommissionCalTestUtility.getSalesCommissionableUsers();
            System.debug('~~~~~ CommissionServiceTest::makeData: users.size - ' + [SELECT Id FROM User LIMIT 20].size());
            
            //create numRecs accounts
            List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(), numRecs, 'TestFactoryDefaults.AccountDefaults', true);

            //create numRecs properties
            List<Account> propLst =  new List<Account>();
            for (Account acc : accLst) {
                propLst.add((Account)TestFactory.createSObject(new Account(ParentId=acc.Id), 'TestFactoryDefaults.PropertyDefaults', false));
            }
            insert propLst;

            //TestFactory.createUsers();
            //commissionableSalesUserLst = [SELECT Id FROM User WHERE Alias LIKE 'BDAccountManager%'];

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
    private static void testBatchDefaultConstructor() {
        TestFactory.turnOffDataAdmin(true, true, true, true, false, new User(Id=System.UserInfo.getUserId()));

        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {
            //run test (should of been ran in setup test)
            Test.startTest();
            InitializeCommissionsBatch b = new InitializeCommissionsBatch();
            database.executeBatch(b, numRecs);
            Test.stopTest();

            //verify expected job commission count = numRecs
            Assert.areEqual(numRecs, [SELECT Id FROM Job_Commission__c].size(), 'Failed:  created number of job commissions incorrect');
            
            //verify expected EC count = numRecs * 2
            Assert.areEqual(numRecs*2, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');    
        }   
    }

    @isTest
    private static void testBatchDateConstructor() {
        //turn off data admin for all but flow only
        TestFactory.turnOffDataAdmin(true, true, true, true, false, new User(Id=System.UserInfo.getUserId()));

        //run as system admin user
        User systemAdmin = [SELECT Id FROM User WHERE Alias='Admin' LIMIT 1];
        System.runAs(systemAdmin) {
            //run test (should of been ran in setup test)
            Test.startTest();
            InitializeCommissionsBatch b = new InitializeCommissionsBatch(Datetime.newInstance(2024, 2, 1));
            database.executeBatch(b, numRecs);
            Test.stopTest();

            //verify expected job commission count = numRecs
            Assert.areEqual(numRecs, [SELECT Id FROM Job_Commission__c].size(), 'Failed:  created number of job commissions incorrect');
            
            //verify expected EC count = numRecs * 2
            Assert.areEqual(numRecs*2, [SELECT Id FROM Employee_Commission__c].size(), 'Failed:  created number of employee commissions incorrect');    
        }   
    }
  
}