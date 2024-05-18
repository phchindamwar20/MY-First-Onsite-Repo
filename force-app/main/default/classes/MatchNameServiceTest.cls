/**
 * @description       : 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 07-31-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class MatchNameServiceTest {
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
    static void testMatchNameService(){
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
        MatchNameService mns = new MatchNameService();
        mns.setMatchNames(accIds);
        Test.stopTest();

        System.debug('~~~~ MatchNameServiceTest::testMatchNameService: grandParentAcc.Name - ' + grandParentAcc.Name);
        System.assertEquals([SELECT Id FROM Account WHERE RecordTypeId=:GeneralConstants.RT_ID_ACC_PROPERTY].size(), [SELECT Id FROM Account WHERE RecordTypeId=:GeneralConstants.RT_ID_ACC_PROPERTY AND Match_Name__c LIKE : '%' + grandParentAcc.Name + '%'].size(), 'Failed because All accounts should have a match name that start with the ultimate parent name and it doesn\'t');
    }
}