/**
 * @File Name          : IcertisAgreementRecallRecallBatchTest.cls
 * @Description        : This is the test calss for iCertisAgreementRecallBatch
 * @Author             : Arpit Vashishtha
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 02-22-2024
 * @Modification Log   :  
 * Ver       Date            Author                 Modification

**/
@isTest
private class IcertisAgreementRecallBatchTest {
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
        List<WorkOrder> grandParentsJobsLstA = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=10000, AR_Balance__c=0, ROM_Contracted_Sales__c=0, Status='In Progress'), 20, 'TestFactoryDefaults.JobDefaults', false);
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
        }
        insert contractLst;
        System.debug('contractLst::::'+contractLst);
    }
    
    @isTest
    private static void trigger_TEST() {
        Test.setMock(HttpCalloutMock.class, new IcertisHttpCalloutMockImpl());
        List<Contract> contractLst = new List<Contract>();
        
        IC_API__c customSettingObj = new IC_API__c();
        customSettingObj.Azure_Endpoint__c = 'https://www.loginmicrosoft.com/';
        customSettingObj.Client_Id__c = '1111111';
        customSettingObj.Client_Secret__c = 'XXXXXX';
        customSettingObj.Tenant_Id__c = 'TTTTTT';
        
        insert customSettingObj;
            
		contractLst = [SELECT Id, Status FROM Contract];
        List<WorkOrder> grandParentsJobsLstA = [SELECT Id FROM WorkOrder limit 1];
        System.debug('grandParentsJobsLstA::::'+grandParentsJobsLstA);
        System.debug('contractLst2::::'+contractLst);
        Integer j=0;
        for(Contract contractObj : contractLst) {
            contractObj.Job__c = grandParentsJobsLstA[0].Id;
            
            if(math.mod(j, 2) == 0) contractObj.Status = 'Approved';
            else contractObj.Status = 'Executed';
            
            contractObj.IC_Agreement_Code__c = 'ABC00'+j;
            j++;
        }
        Test.startTest();
        System.debug('contractLst3::::'+contractLst);
        update contractLst;
        System.debug('contractLst4::::'+contractLst);
        IcertisAgreementRecallBatch bcn = new IcertisAgreementRecallBatch();
        Database.executeBatch(bcn);
        
        IcertisAgreementCancelBatch bcnCancel = new IcertisAgreementCancelBatch();
        Database.executeBatch(bcnCancel);
        Test.stopTest();
    }
}