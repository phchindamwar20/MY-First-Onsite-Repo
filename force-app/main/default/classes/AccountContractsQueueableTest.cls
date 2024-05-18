/**
 * @description       : This test the AccountContractsQueueable and SelectionAccountsWithContracts classes
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : Terri Jiles
**/
@isTest 
public with sharing class AccountContractsQueueableTest {
    private static Integer numAcc=200;
    private static Integer numContractsPerAccount = 6; // 7 doesn't work
    private static final String SELECTION_CONTRACT_ACCOUNT = 'SelectionAccountsWithContracts';
    private static final String QUEUEABLE_CONTRACT_ACCOUNT = 'AccountContractQueueable';

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

        
        Test.startTest();
        insertContracts(new Set<Id>((new Map<Id, Account>(accLst)).keySet()));
        Test.stopTest();
    }

    @future
    private static void insertContracts(Set<Id> accIds) {
        List<Contract> contractLst = new List<Contract>();
        for (Id accId : accIds) {
            contractLst.addAll((List<Contract>)TestFactory.createSObjectList(new Contract(AccountId=accId), numContractsPerAccount, 'TestFactoryDefaults.ContractClientDefaults', false));
        }

        insert contractLst;
    }

    @isTest
    private static void testSelection(){
        SelectionAccountsWithContracts sawc = new SelectionAccountsWithContracts();

        Account newAcc = [SELECT Id, MSA_Rate_Type__c, T_M_Year__c, Status__c, Contract_Type__c, 
                        (SELECT Id FROM Contracts WHERE RecordTypeId =: GeneralConstants.RT_ID_CONTRACT_CLIENT ) 
                        FROM Account LIMIT 1];
        Account oldAcc = newAcc.clone(false, true, false, false);

        oldAcc.Status__c=GeneralConstants.ACC_STATUS_UNQUALIFIED;
        System.assertEquals(true, sawc.isCriteriaMet(oldAcc, newAcc), 'Failed: It should return true because the Statuses are different');

        oldAcc.Status__c=GeneralConstants.ACC_STATUS_NEEDS_ASSESSMENT;
        oldAcc.Contract_Type__c='MSA Only';
        System.assertEquals(true, sawc.isCriteriaMet(newAcc, oldAcc), 'Failed: It should return true because the Contract Statues are different');        
    }

    @isTest
    private static void testActiveContract() {
        Map<Id, Account> accById = new Map<Id, Account>([SELECT Id, Contract_Type__c, RecordTypeId, ParentId FROM Account]);
        String contractType = accById.values()[0].Contract_Type__c;

        ExecutionService chainQueueableJobService = new ExecutionService();
        List<ExecutionItem> singleItmLst = new List<ExecutionItem>();

        for (ExecutionItem ei : chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_ACCOUNT, GeneralConstants.AFTER_UPDATE, accById, null)) {
            if (ei.getSelection().getSelectionName() == SELECTION_CONTRACT_ACCOUNT) {
                singleItmLst.add(ei);
            }
        }

        Test.startTest();
        chainQueueableJobService.executeInitialHandler(singleItmLst);
        Test.stopTest();

        System.assertEquals(numAcc * numContractsPerAccount, [SELECT Id FROM Contract WHERE Account_Contract_Type__c=:contractType].size(), 'Failed:  expected the Acount Contact Type to match the account\'s contract type');
    }
}