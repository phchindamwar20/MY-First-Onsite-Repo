/**
 * @description       : 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 07-31-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class MatchNameQueueableTest {
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
    static void testSelectionMatchNameAccountAddIdForMatchName(){
        SelectionMatchNameAccount smna = new SelectionMatchNameAccount();

        Account parAcc = new Account(Name='Test parent');
        insert parAcc;

        Account acc = new Account(Name='Test', RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY, ParentId=null, Active__c=true, ShippingStateCode='TX', ShippingCity='Austin', ShippingStreet='1234 Hello St.', The_Ultimate_Parent_Account__c=parAcc.Id, Inactive_Date__c=null);
        Account accClone = acc.clone(false, true, false, false);
        
        System.assertEquals(true, smna.addIdForMatchName(acc, null));

        accClone.Name='Test2';
        System.assertEquals(true, smna.addIdForMatchName(acc, accClone), 'Failed:  it should be true due to change in name');

        accClone.Name=acc.Name;
        accClone.RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT;
        System.assertEquals(true, smna.addIdForMatchName(acc, accClone), 'Failed:  it should be true due to change in RecordTypeId');

        accClone.RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY;
        accClone.Active__c=false;
        System.assertEquals(true, smna.addIdForMatchName(acc, accClone), 'Failed:  it should be true due to change in Active');

        accClone.Active__c=true;
        accClone.ShippingStateCode='LA';
        System.assertEquals(true, smna.addIdForMatchName(acc, accClone), 'Failed:  it should be true due to change in ShippingStateCode');

        accClone.ShippingStateCode='TX';
        accClone.ShippingCity='Dallas';
        System.assertEquals(true, smna.addIdForMatchName(acc, accClone), 'Failed:  it should be true due to change in ShippingCity');

        accClone.ShippingCity='Austin';
        accClone.ShippingStreet = '123 Sesame Street';
        System.assertEquals(true, smna.addIdForMatchName(acc, accClone), 'Failed:  it should be true due to change in ShippingStreet');

        accClone.ShippingStreet = '1234 Hello St.';
        accClone.ParentId=parAcc.Id;
        System.assertEquals(true, smna.addIdForMatchName(acc, accClone), 'Failed:  it should be true due to change in Parent Id');

        accClone.ParentId = null;
        accClone.The_Ultimate_Parent_Account__c=null;
        System.assertEquals(true, smna.addIdForMatchName(acc, accClone), 'Failed:  it should be true due to change in The Ultimate Parent Account');

        accClone.The_Ultimate_Parent_Account__c=parAcc.Id;
        acc.Inactive_Date__c = Date.today();
        System.assertEquals(true, smna.addIdForMatchName(acc, accClone), 'Failed:  it should be true due to change in Inactive Date');
    }

    @isTest
    static void testMatchNameQueueable(){
        Account grandParentAcc = (Account)TestFactory.createSObject(new Account(RecordTypeId=GeneralConstants.RT_ID_ACC_PARENT, Name='GrandParent'), 'TestFactoryDefaults.AccountDefaults', true);
        Account parentAcc = (Account)TestFactory.createSObject(new Account(ParentId=grandParentAcc.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_PARENT, Name='Parent', The_Ultimate_Parent_Account__c=grandParentAcc.Id), 'TestFactoryDefaults.AccountDefaults', true);
        Account child1 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT, Name='Child1 A', The_Ultimate_Parent_Account__c=grandParentAcc.Id), 'TestFactoryDefaults.AccountDefaults', true);
        Account property1A = (Account)TestFactory.createSObject(new Account(ParentId=child1.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY, Name='Property1A', ShippingStateCode='TX', ShippingCity='Dallas', ShippingPostalCode='77838', ShippingCountryCode='US'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child2 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT, Name='Child2 123', The_Ultimate_Parent_Account__c=grandParentAcc.Id), 'TestFactoryDefaults.AccountDefaults', true);
        Account child3 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_PARENT, Name='Child3 XYZ', The_Ultimate_Parent_Account__c=grandParentAcc.Id), 'TestFactoryDefaults.AccountDefaults', true);
        Account grandChild31 = (Account)TestFactory.createSObject(new Account(ParentId=child3.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT, Name='Child4 BC', The_Ultimate_Parent_Account__c=grandParentAcc.Id), 'TestFactoryDefaults.AccountDefaults', true);
        Account greatGrandChild311 = (Account)TestFactory.createSObject(new Account(ParentId=grandChild31.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT, Name='greatGrandChild311', The_Ultimate_Parent_Account__c=grandParentAcc.Id), 'TestFactoryDefaults.AccountDefaults', true);
        Account property311A = (Account)TestFactory.createSObject(new Account(ParentId=greatGrandChild311.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY, Name='Property311A', ShippingStateCode='TX', ShippingCity='Houston', ShippingPostalCode='77838', ShippingCountryCode='US'), 'TestFactoryDefaults.AccountDefaults', true);
        
        List<Account> propAccLst  = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=child1.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY, ShippingStateCode='TX', ShippingCity='El Paso', ShippingPostalCode='77838', ShippingCountryCode='US'), 46, 'TestFactoryDefaults.AccountDefaults', false);
        Integer i=0;
        for (Account acc : propAccLst) {
            acc.Name = 'grandChildren1_'+String.valueOf(i);
            acc.ShippingStreet = i + ' Sesame Street';
            i++;
        }
        insert propAccLst;

        i=0;
        List<Account> prop2AccLst  = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=child2.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY, ShippingStateCode='TX', ShippingCity='Austin', ShippingPostalCode='77838', ShippingCountryCode='US'), 46, 'TestFactoryDefaults.AccountDefaults', false); 
        for (Account acc : prop2AccLst) {
            acc.Name = 'grandChildren2_'+String.valueOf(i);
            acc.ShippingStreet = i + ' Main Street';
            i++;
        }
        insert prop2AccLst;

        Set<Id> accIds = new Set<Id>();
        accIds.add(grandParentAcc.Id);

        Test.startTest();
        ExecutionService chainQueueableJobService = new ExecutionService();
        List<ExecutionItem> justMatchNameLst = new List<ExecutionItem>();

        for (ExecutionItem ei : chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_ACCOUNT, 
                GeneralConstants.AFTER_UPDATE, 
                new Map<Id, Account>([SELECT Id, ParentId, Name, RecordTypeId, Active__c, ShippingStateCode, ShippingCity, ShippingStreet, The_Ultimate_Parent_Account__c, Inactive_Date__c FROM Account]), null)) {
            if (ei.getSelection().getSelectionName() == 'SelectionMatchNameAccount') {
                justMatchNameLst.add(ei);
            }
        }
        chainQueueableJobService.executeInitialHandler(justMatchNameLst);
        Test.stopTest();

        System.assertEquals([SELECT Id FROM Account WHERE RecordTypeId=:GeneralConstants.RT_ID_ACC_PROPERTY].size(), [SELECT Id FROM Account WHERE RecordTypeId=:GeneralConstants.RT_ID_ACC_PROPERTY AND Match_Name__c LIKE : '%' + grandParentAcc.Name + '%'].size(), 'Failed because All accounts should have a match name that start with the ultimate parent name and it doesn\'t');
    }
}