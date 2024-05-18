/**
 * @description       : This test the GoNoGoService class
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-19-2024
 * @last modified by  : Terri Jiles
**/
@isTest 
public without sharing class GoNoGoServiceTest {
    //private static Integer numRec = 200;
    private static Integer numRec = 100; 

    @TestSetup
    private static void makeData(){
        Test.setMock(HttpCalloutMock.class, new IcertisHttpCalloutMockImpl());
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
        List<Account> accLst  = (List<Account>)TestFactory.createSObjectList(new Account(GNG_Legal_Override__c=GeneralConstants.GO), numRec, 'TestFactoryDefaults.AccountDefaults', true);
        List<WorkOrder> jobLst = new List<WorkOrder>();

        for (Account acc : accLst) {
            jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id, Job_Name__c='Test Job'), 'TestFactoryDefaults.JobDefaults', false));
        }
        insert jobLst;
    }

    @isTest
    private static void testAccountGoNoGo() {
        GoNoGoService gngsAcc = new GoNoGoService();
        Map<Id, Account> accById = new Map<Id, Account>([SELECT Id FROM Account WHERE Go_No_Gox__c=:GeneralConstants.NO_GO]);

        System.assertEquals(numRec, accById.size(), 'Failed:  expected go no go to be false intially');

        Test.startTest();
        Set<Id> accIds = gngsAcc.updateAccountsGoNoGo(accById.keySet());
        Test.stopTest();

        System.assertEquals(accById.size(), accIds.size(), 'Failed:  Number of acc Ids returned doesn\'t match original count');
        System.assertEquals(numRec, [SELECT Id FROM Account WHERE Go_No_Gox__c=:GeneralConstants.GO].size(), 'Failed:  Go No Gox not populated as expected');
    }

    @isTest
    private static void testJobGoNoGo() {
        Test.setMock(HttpCalloutMock.class, new IcertisHttpCalloutMockImpl());
        GoNoGoService gngsJob = new GoNoGoService();
        Map<Id, WorkOrder> jobById = new Map<Id, WorkOrder>([SELECT Id FROM WorkOrder WHERE Go_No_Gox__c=:GeneralConstants.NO_GO]);

        System.assertEquals(numRec, jobById.size(), 'Failed:  expected go no go to be false intially');

        Test.startTest();
        Set<Id> jobIds = gngsJob.updateJobsGoNoGo(jobById.keySet());
        Test.stopTest();

        System.assertEquals(numRec, [SELECT Id FROM WorkOrder WHERE Go_No_Gox__c=:GeneralConstants.GO].size(), 'Failed:  Go No Gox not populated as expected');
    } 
    
    @isTest
    private static void testAccountHierarchyGoNoGo() {
        //This test recurisve updates of Account Hierarchy Go/No Go
        Map<Id, Account> accById = new Map<Id, Account>([SELECT Id FROM Account]);

        //grandparent
        Account grandParent = (Account)TestFactory.createSObject(new Account(Contract_Type__c=GeneralConstants.ACC_CONTRACT_TYPE_COVERED_BY_PARENT), 'TestFactoryDefaults.AccountDefaults', true);
        Contract contr = (Contract)TestFactory.createSObject(new Contract(AccountId=grandParent.Id, Revised_Contract_End_Date__c=Date.today(), Account_Contract_Type__c='MSA Only', Rate_Type__c='T&M', T_M_Year__c='Client-specific'), 
            'TestFactoryDefaults.ContractClientDefaults', true);
            contr.Status='Fully Executed';
        update contr;
        Account graParAcc = [SELECT Id, Go_No_Go__c, Go_No_Gox__c, GNG_Count__c, GNG_DLRS_T_M__c FROM Account WHERE Id=:grandParent.Id LIMIT 1];
        Contract contrUpd = [SELECT Id, Active__c, Account_Contract_Type__c, Status, Revised_Contract_End_Date__c FROM Contract LIMIT 1];

        //System.debug('~~~~ GoNoGoServiceTest::testAccountHierarchyGoNoGo: contr - ' + contrUpd);
        //System.debug('~~~~ GoNoGoServiceTest::testAccountHierarchyGoNoGo: grand parent - ' + graParAcc);
        
        //parents
        List<Account> updAccLst = new List<Account>();
        for (Account acc : accById.values()) {
            updAccLst.add(new Account(Id=acc.Id, ParentId=grandParent.Id, GNG_Legal_Override__c=null, Contract_Type__c=GeneralConstants.ACC_CONTRACT_TYPE_COVERED_BY_PARENT));
        }
        update updAccLst;
        Account parentRec = [SELECT Id, Go_No_Go__c, Go_No_Gox__c, GNG_Count__c, GNG_DLRS_T_M__c FROM Account WHERE Id=:updAccLst[0].Id LIMIT 1];
        //System.debug('~~~~ GoNoGoServiceTest::testAccountHierarchyGoNoGo: parent - ' + parentRec);

        //children
        List<Account> accChildLst = new List<Account>();
        for (Account acc : updAccLst) {
            accChildLst.add((Account)TestFactory.createSObject(new Account(ParentId=acc.Id, Contract_Type__c=GeneralConstants.ACC_CONTRACT_TYPE_COVERED_BY_PARENT), 'TestFactoryDefaults.AccountDefaults', false));
        }
        insert accChildLst;
        //System.debug('~~~~ GoNoGoServiceTest::testAccountHierarchyGoNoGo: sample child - ' + [SELECT Id, Go_No_Go__c, Go_No_Gox__c FROM Account WHERE Id=:accChildLst[0].Id]);


        //grandchildren
        List<Account> accGrChildLst = new List<Account>();
        for (Account acc : accChildLst) {
            accGrChildLst.add((Account)TestFactory.createSObject(new Account(ParentId=acc.Id, Contract_Type__c=GeneralConstants.ACC_CONTRACT_TYPE_COVERED_BY_PARENT), 'TestFactoryDefaults.AccountDefaults', false));
        }
        insert accGrChildLst;
        //System.debug('~~~~ GoNoGoServiceTest::testAccountHierarchyGoNoGo: sample grand child - ' + [SELECT Id, Go_No_Go__c, Go_No_Gox__c FROM Account WHERE Id=:accGrChildLst[0].Id]);


        //great grandchildren
        List<Account> accGrGrChildLst = new List<Account>();
        for (Account acc : accGrChildLst) {
            accGrGrChildLst.add((Account)TestFactory.createSObject(new Account(ParentId=acc.Id, Contract_Type__c=GeneralConstants.ACC_CONTRACT_TYPE_COVERED_BY_PARENT), 'TestFactoryDefaults.AccountDefaults', false));
        }
        insert accGrGrChildLst;
        //System.debug('~~~~ GoNoGoServiceTest::testAccountHierarchyGoNoGo: sample great grand child - ' + [SELECT Id, Go_No_Go__c, Go_No_Gox__c FROM Account WHERE Id=:accGrGrChildLst[0].Id]);


        Test.startTest();
        GoNoGoService gngsAcc = new GoNoGoService();
        Set<Id> accIds = gngsAcc.updateAccountsGoNoGo(accById.keySet());
        Test.stopTest();

        System.assertEquals(accById.size() + accChildLst.size() + accGrChildLst.size() + accGrGrChildLst.size(), accIds.size(), 'Failed:  expected the ids returned are for all the parents and descendants');

        //Note:  the grandparent isn't included in this because we didn't explicitly include it as input to the gngsAcc to update the go/no go
        System.assertEquals(accById.size() + accChildLst.size() + accGrChildLst.size() + accGrGrChildLst.size(), [SELECT Id FROM Account WHERE Go_No_Gox__c=:GeneralConstants.GO].size(), 'Failed:  ALL of the accounts should have Go No Gox as GO');
    }
}