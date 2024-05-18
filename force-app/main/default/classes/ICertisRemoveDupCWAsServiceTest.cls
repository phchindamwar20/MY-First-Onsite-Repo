/**
 * @File Name          : ICertisRemoveDupCWAsServiceTest.cls
 * @Description        : Test class for ICertisRemoveDupCWAsService
 * @Author             : Arpit Vashishtha
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 02-22-2024
 * @Modification Log   :  
 * Ver       Date            Author                 Modification
**/
@isTest
private class ICertisRemoveDupCWAsServiceTest {
    private static Integer numAcc=2;
    private static Integer numContractsPerAccount = 4; //  5 doesn't work
    
    @TestSetup
    private static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        dataAdmin.TurnOffFlow__c=true;
        dataAdmin.TurnOffTrigger__c=true;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
            dataAdmin.SetupOwnerId = UserInfo.getUserId();
            insert dataAdmin;  
        }
        else {
            update dataAdmin;
        } 
        List<Account> grandParentAccountLst = (List<Account>)TestFactory.createSObjectList(new Account(RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId()), 20, 'TestFactoryDefaults.AccountDefaults', false);
        List<WorkOrder> grandParentsJobsLstA = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=10000, AR_Balance__c=0, ROM_Contracted_Sales__c=0, Status='In Progress', IC_Bolt_CWA__c = TRUE), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> grandParentsJobsLst = new List<WorkOrder>();
        
        Integer j=0;
        for (Account grandParentAcc : grandParentAccountLst) {
            grandParentAcc.Name='Grandparent'+j;
            j++;
        }
        insert grandParentAccountLst;

        j=0;
        for (Account grandParentAcc : grandParentAccountLst) {
            grandParentsJobsLstA[j].AccountId=grandParentAcc.Id;
            j++;
        }

        grandParentsJobsLst.addAll(grandParentsJobsLstA);
        insert grandParentsJobsLst;
        
        List<Contract> contractLst = new List<Contract>();
        System.debug('grandParentAccountLst::::'+grandParentAccountLst);
        for (Account acc : grandParentAccountLst) {
            contractLst.addAll((List<Contract>)TestFactory.createSObjectList(new Contract(AccountId=acc.Id), numContractsPerAccount, 'TestFactoryDefaults.ContractClientDefaults', false));
        }
        System.debug('contractLst1::::'+contractLst);
        for(Contract conObj : contractLst) {
            conObj.Status = 'Draft';
            conObj.IC_Agreement_Code__c = 'ICMCWA_001';
            conObj.IC_SysId__c = 'xxxx-x-xxxx-xxxx';
        }
        insert contractLst;
        System.debug('contractLst::::'+contractLst);
    }
    
    @isTest 
    private static void testRecallContracts() {
        Test.setMock(HttpCalloutMock.class, new IcertisHttpCalloutMockImpl());
        List<WebServiceLogObj> logWrapperList = new List<WebServiceLogObj>();
        System.assertEquals(80, [SELECT Id, Status, IC_Agreement_Code__c FROM Contract WHERE IC_Recalled__c = FALSE].size(), 'Fail:  Prevalidation check field, all contract should have recalled FASLE.'); 
        List<Contract> contractList = [SELECT Id, Status, IC_Agreement_Code__c FROM Contract WHERE IC_Recalled__c = FALSE];
        Test.startTest();
        List<Contract> contractRecalledList = ICertisRemoveDupCWAsService.recallContracts(contractList, logWrapperList);
        Test.stoptest();
    }
    
    @isTest 
    private static void testCancelContracts() {
        Test.setMock(HttpCalloutMock.class, new IcertisHttpCalloutMockImpl());
        List<WebServiceLogObj> logWrapperList = new List<WebServiceLogObj>();
        System.assertEquals(80, [SELECT Id, Status, IC_SysId__c, IC_Agreement_Code__c FROM Contract WHERE IC_Cancelled__c = FALSE].size(), 'Fail:  Prevalidation check field, all contract should have recalled FASLE.'); 
        List<Contract> contractList = [SELECT Id, Status, IC_SysId__c, IC_Agreement_Code__c FROM Contract WHERE IC_Cancelled__c = FALSE LIMIT 1];
        Test.startTest();
        List<Contract> contractCancelList = ICertisRemoveDupCWAsService.cancelContracts(contractList, logWrapperList);
        Test.stoptest();
    }
    
    @isTest 
    private static void testGetContractsToRecall() {
        System.assertEquals(20, [SELECT Id FROM WorkOrder].size(), 'Fail:  Prevalidation check field, all jobs exist.'); 
        List<WorkOrder> jobList = [SELECT Id FROM WorkOrder];
        List<Contract> contractList = [SELECT Id, Status, IC_SysId__c, IC_Agreement_Code__c FROM Contract];
        for(Contract contractObj : contractList) {
            contractObj.status = 'Approved';
        }
        update contractList;
        Test.startTest();
        Set<Id> jobIdsSet = (new Map<Id,WorkOrder>(jobList)).keySet().clone();
        Map<String, Contract> jobContractMap = ICertisRemoveDupCWAsService.getContractsToRecall(jobIdsSet);
        Test.stoptest();
    }

}