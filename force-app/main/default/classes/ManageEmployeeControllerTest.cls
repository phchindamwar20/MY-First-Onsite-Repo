@isTest
public with sharing class ManageEmployeeControllerTest {
    
    @TestSetup
    private static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=false;
        dataAdmin.TurnOffProcessBuilder__c=false;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.TurnOffFlow__c=false;
        if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
            dataAdmin.SetupOwnerId = UserInfo.getUserId();
            insert dataAdmin;
        }
        else {
            update dataAdmin;
        }

        Map<String, ServiceTerritory> serviceTerritoryByNameMap = TestFactory.createServiceTerritories();
        Test.startTest();
        List<User> commissionableSalesUserLst = CommissionCalTestUtility.getSalesCommissionableUsers();
        Test.stopTest();
        
        User boltUser = [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];
        
        if (BOLT__c.getInstance(boltUser.Id) == null) {
            BOLT__c bolt = new BOLT__c(SetupOwnerId=boltUser.Id, Is_Bolt_Integration_User__c=true);
            insert bolt;
        } 

        if (DataAdmin__c.getInstance(boltUser.Id) == null ) {
            DataAdmin__c dataAdmin2 = new DataAdmin__c();
            dataAdmin2.TurnOffTrigger__c=false;
            dataAdmin2.TurnOffWorkflow__c=false;
            dataAdmin2.TurnOffProcessBuilder__c=false;
            dataAdmin2.TurnOffValidationRules__c=true;
            dataAdmin2.TurnOffFlow__c=false;
            insert dataAdmin2;
        }
    }
    
    @isTest
    private static void testManageEmployeeController() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job = CommissionCalTestUtility.createCommissionableJobByNumberOfBDsAndJobMargin(3, Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_1).Minimum_Margin_for_Tier__c + 1);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        jobCom.Actual_Commissionable_Switch__c = 5;
        update jobCom;
        Assert.areEqual(3, jobCom.Employee_Commissions__r.size(), 'Failed:  expected 3 employee commission records');
        Assert.areEqual(SalesIncentivePlanConstants.TIER_1, jobCom.Margin_Tier__c, 'Failed:  expected tier 1 margin');
        Assert.areEqual(1662.50, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(554.17, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
        
        String finalSObjectStr = '[{"Id":"005Pf000000MuA1IAK","Name":"Terence Atkinson","Employee__c":"005Pf000000MuA1IAK","Individual_Split_Percentage__c":"100.0000%","Employee_Name__c":"Terence Atkinson","Employee__r.Id":"005Pf000000MuA1IAK"}]';
        String selectedUserIds = '["005Pf000000MuA1IAK"]';
        String deletedUserIds = '["005Pf000000MuA1IAL"]';
        
        String savedEmployeesResponse = ManageEmployeeController.saveEmployeeCommissionRecord(jobCom.Id, 'Test Exception Value', finalSObjectStr, selectedUserIds, deletedUserIds,true, true);
        Assert.areEqual('success', savedEmployeesResponse, 'Employee Commisson are not saved.');
        
        ManageEmployeeController.DataTableResponse dtObj = ManageEmployeeController.getEmployeeCommission(jobCom.Id);
        Assert.areNotEqual(null, dtObj, 'Employee Commission cant be retrieved.');
        
        ManageEmployeeController.DataTableResponse dtConfirmationObj = ManageEmployeeController.getConfirmationScreenRecords(jobCom.Id, JSON.serialize(dtObj), finalSObjectStr);
        Assert.areNotEqual(null, dtConfirmationObj, 'Confirmation screen records cant be retrieved.');
        
		Job_Commission__c jobComObj = ManageEmployeeController.getJobCommission(jobCom.Id);
        Assert.areNotEqual(null, jobComObj, 'Job Commission cant be retrieved.');

		Job_Commission__c jobComUpdateObj = ManageEmployeeController.calculateSplitMultiplier(jobCom.Id, finalSObjectStr);
        Assert.areNotEqual(null, jobComUpdateObj, 'Split multiplier cant be calculated.');
        
        ManageEmployeeController.SearchWrapper inputWrapper = new ManageEmployeeController.SearchWrapper();
        inputWrapper.fieldApiName = 'Name';
        inputWrapper.otherFieldApiName = 'FirstName';
        inputWrapper.selectedUserIds = '["005Pf000000MuA1IAK","005Pf000000MuA1IAM","005Pf000000MuA1IAN"]';
        inputWrapper.searchString = 'Test';
        inputWrapper.objectApiName = 'User';
        
        
        List<ManageEmployeeController.ResultWrapper> resultWrapperObj = ManageEmployeeController.fetchRecords(inputWrapper);
        Assert.areNotEqual(null, resultWrapperObj, 'Employee Comission cant be retrieved.');
    }
}