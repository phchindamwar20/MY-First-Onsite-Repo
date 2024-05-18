/**
 * @description       : This is the test class for AccountContractsService
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class AccountContractsServiceTest {
    private static Integer numAcc=200;
    private static Integer numContractsPerAccount = 4; //  5 doesn't work

    @TestSetup
    private static void makeData(){
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

        //create test accounts and contracts
        List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(), numAcc, 'TestFactoryDefaults.AccountDefaults', true);
        List<Contract> contractLst = new List<Contract>();

        for (Account acc : accLst) {
            contractLst.addAll((List<Contract>)TestFactory.createSObjectList(new Contract(AccountId=acc.Id), numContractsPerAccount, 'TestFactoryDefaults.ContractClientDefaults', false));
        }

        Test.startTest();
        insert contractLst;
        Test.stopTest();
    }

    @isTest
    private static void testUnqualifiedStatus() {
        Map<Id, Account> accById = new Map<Id, Account>([SELECT Id, Status__c FROM Account]);
        List<Account> accUpdLst = new List<Account>();

        for (Id accId : accById.keySet()) {
            accUpdLst.add(new Account(Id=accId, Status__c=GeneralConstants.ACC_STATUS_UNQUALIFIED));
        }
        update accUpdLst;

        Test.startTest();
        AccountContractsService acs = new AccountContractsService();
        acs.updateClientContracts(accById.keySet());
        Test.stopTest();

        System.assertEquals(numAcc * numContractsPerAccount, [SELECT Id FROM Contract WHERE Canceled__c=true].size(), 'Failed:  Expected all contracts status to be canceled = true because the account\'s status is unqualified');
    }

    @isTest
    private static void testAccountContractType() {
        Map<Id, Account> accById = new Map<Id, Account>([SELECT Id, Contract_Type__c FROM Account]);
        String contractType = accById.values()[0].Contract_Type__c;

        Test.startTest();
        AccountContractsService acs = new AccountContractsService();
        acs.updateClientContracts(accById.keySet());
        Test.stopTest();

        System.assertEquals(numAcc * numContractsPerAccount, [SELECT Id FROM Contract WHERE Account_Contract_Type__c=:contractType].size(), 'Failed:  expected the Acount Contact Type to match the account\'s contract type');
    }

}