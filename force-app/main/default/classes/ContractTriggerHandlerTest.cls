@isTest
private class ContractTriggerHandlerTest {
    private static Integer numAcc=2;
    private static Integer numContractsPerAccount = 4; //  5 doesn't work

    @TestSetup
    private static void makeData(){
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
    private static void trigger_TEST() {
        Test.setMock(HttpCalloutMock.class, new IcertisHttpCalloutMockImpl());
        List<Contract> contractLst = new List<Contract>();
        contractLst = [SELECT Id, Status FROM Contract];
        for(Contract conObj : contractLst) {
            conObj.Status = 'Approved';
        }
        update contractLst;
    }
}