/**
 * @description       : This is the test class for the UltimateParentRollupCalculationQueueable chained job
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-01-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public with sharing class UltimateParentRollupCalculationQueueTest {
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
    }

    @isTest
    private static void testQueueable(){
        Account grandParentAcc = (Account)TestFactory.createSObject(new Account(RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PARENT).getRecordTypeId(), Name='GrandParent'), 'TestFactoryDefaults.AccountDefaults', true);
        Account parentAcc = (Account)TestFactory.createSObject(new Account(ParentId=grandParentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PARENT).getRecordTypeId(), Name='Parent'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child1 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child1'), 'TestFactoryDefaults.AccountDefaults', true);
        Account property1A = (Account)TestFactory.createSObject(new Account(ParentId=child1.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId(), Name='Property1A'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child2 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child2'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child3 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PARENT).getRecordTypeId(), Name='Child3'), 'TestFactoryDefaults.AccountDefaults', true);
        Account grandChild31 = (Account)TestFactory.createSObject(new Account(ParentId=child3.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child4'), 'TestFactoryDefaults.AccountDefaults', true);
        Account greatGrandChild311 = (Account)TestFactory.createSObject(new Account(ParentId=grandChild31.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='greatGrandChild311'), 'TestFactoryDefaults.AccountDefaults', true);
        Account property311A = (Account)TestFactory.createSObject(new Account(ParentId=greatGrandChild311.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId(), Name='Property311A'), 'TestFactoryDefaults.AccountDefaults', true);
        
        List<Account> grandChildren1AccLst  = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=child1.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId()), 46, 'TestFactoryDefaults.AccountDefaults', false);
        Integer i=0;
        for (Account acc : grandChildren1AccLst) {
            acc.Name = 'grandChildren1_'+String.valueOf(i);
        }
        insert grandChildren1AccLst;

        i=0;
        List<Account> grandChildren2AccLst  = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=child2.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId()), 46, 'TestFactoryDefaults.AccountDefaults', false); 
        for (Account acc : grandChildren2AccLst) {
            acc.Name = 'grandChildren2_'+String.valueOf(i);
        }
        insert grandChildren2AccLst;

        Map<Id, Account> accById = new Map<Id, Account>([SELECT Id, ParentId, Name, RecordTypeId FROM Account]);

        for (Id accId : accById.keySet()) {
            System.debug('~~~~ UltimateParentRollupBatchTest::testQueueable: accId - ' + accId + ', acc - ' + accById.get(accId));
        }

        Test.startTest();
        ExecutionService chainQueueableJobService = new ExecutionService();
        //List<ExecutionItem> executionItemLst = chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_ACCOUNT, GeneralConstants.AFTER_INSERT, accById, null);
        List<ExecutionItem> justUltimateParentItmLst = new List<ExecutionItem>();

        for (ExecutionItem ei : chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_ACCOUNT, GeneralConstants.AFTER_INSERT, accById, null)) {
            if (ei.getSelection().getSelectionName() == 'SelectionUltimateParent') {
                justUltimateParentItmLst.add(ei);
            }
        }
        chainQueueableJobService.executeInitialHandler(justUltimateParentItmLst);
        Test.stopTest();

        Set<Id> grandChildren1AccIds = new Set<Id>();
        Set<Id> grandChildren2AccIds = new Set<Id>();

        for (Account acc : [SELECT ID FROM Account WHERE RecordType.DeveloperName=:BoltConstants.RT_ACC_ACCOUNT AND ParentId=:child1.Id]) {
            grandChildren1AccIds.add(acc.Id);
        }
        for (Account acc : [SELECT ID FROM Account WHERE RecordType.DeveloperName=:BoltConstants.RT_ACC_ACCOUNT AND ParentId=:child2.Id]) {
            grandChildren2AccIds.add(acc.Id);
        }

        System.assert([SELECT Id FROM Account WHERE Id=:grandParentAcc.Id AND The_Ultimate_Parent_Account__c=null].size()==1, 'Fail, GrandParentAcc test fail');
        System.assert([SELECT Id FROM Account WHERE Id=:parentAcc.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The parentAcc\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:child1.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The child1\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:property1A.Id AND The_Ultimate_Parent_Account__c=null].size()==1, 'Fail: The property1A\'s Ulimate Parent Account Needs null');
        System.assert([SELECT Id FROM Account WHERE Id=:child2.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The child2\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:child3.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The child3\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:grandChild31.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The grandChild31\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:greatGrandChild311.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The greatGrandChild311\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:property311A.Id AND The_Ultimate_Parent_Account__c=null].size()==1, 'Fail: The property311A\'s Ulimate Parent Account Needs null');
        System.assert([SELECT Id FROM Account WHERE Id IN: grandChildren1AccIds AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()>1, 'Fail, the grand children 1 acc\'s Ultimate Parent Acc should be grandParentAccId');
        System.assert([SELECT Id FROM Account WHERE Id IN: grandChildren2AccIds AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()>1, 'Fail, the grand children 2 acc\'s Ultimate Parent Acc should be grandParentAccId');
    }

    @isTest
    private static void testSelection(){
        SelectionUltimateParent sup = new SelectionUltimateParent();

        Account parAcc = new Account(Name='Test parent');
        insert parAcc;
        
        Account parAcc2 = new Account(Name='Test parent 2');
        insert parAcc2;

        Account acc = new Account(Name='Test', RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT, ParentId=parAcc.Id);
        Account accClone = acc.clone(false, true, false, false);
        
        //new acc
        System.assertEquals(true, sup.isUltimateParentCalRequired(acc, null), 'Failed:  it should return true for new acc');

        //change parent to null
        accClone.ParentId=null;
        System.assertEquals(true, sup.isUltimateParentCalRequired(acc, accClone), 'Failed:  it should be true due to change parent changed to null');

        //change parent 
        accClone.ParentId=parAcc2.Id;
        System.assertEquals(true, sup.isUltimateParentCalRequired(acc, accClone), 'Failed:  it should be true due to change in ParentId');

        //change from property record type
        accClone.RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY;
        System.assertEquals(true, sup.isUltimateParentCalRequired(acc, accClone), 'Failed:  it should be true due to change from property record type');

        //change in name
        accClone.RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT;
        accClone.Name='changed acc name';
        System.assertEquals(true, sup.isUltimateParentCalRequired(acc, accClone), 'Failed:  it should be true due to change in Name');
    }    
}