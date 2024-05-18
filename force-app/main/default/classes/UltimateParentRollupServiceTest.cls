/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-29-2023
 * @last modified by  : Terri Jiles
**/
@isTest
private without sharing class UltimateParentRollupServiceTest {
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
    private static void testNewAccounts() {
        Account grandParentAcc = (Account)TestFactory.createSObject(new Account(RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PARENT).getRecordTypeId(), Name='GrandParent', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account parentAcc = (Account)TestFactory.createSObject(new Account(ParentId=grandParentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PARENT).getRecordTypeId(), Name='Parent', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child1 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child1', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account property1A = (Account)TestFactory.createSObject(new Account(ParentId=child1.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId(), Name='Property1A', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child2 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child2', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child3 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child3', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account grandChild31 = (Account)TestFactory.createSObject(new Account(ParentId=child3.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child4', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account greatGrandChild311 = (Account)TestFactory.createSObject(new Account(ParentId=grandChild31.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='greatGrandChild311', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account property311A = (Account)TestFactory.createSObject(new Account(ParentId=greatGrandChild311.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId(), Name='Property311A', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);

        Map<Id, Account> newAccById = new Map<Id, Account>();
        
        for (Account acc :[SELECT Id, ParentId FROM Account]) {
            newAccById.put(acc.Id, acc);
        }
        System.debug('~~~~~ UltimateParentRollupServiceTest::testNewAccounts: newAccById.keySet - ' + newAccById.keySet() + '  newAccById.values - ' + newAccById.values());
        Test.startTest();
        UltimateParentRollupService urs = new UltimateParentRollupService();
        Set<Id> ids = urs.setUltimateParent(newAccById.keySet());
        Test.stopTest();

        System.assert([SELECT Id FROM Account WHERE Id=:grandParentAcc.Id AND The_Ultimate_Parent_Account__c=null].size()==1, 'Fail, GrandParentAcc test fail');
        System.assert([SELECT Id FROM Account WHERE Id=:parentAcc.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The parentAcc\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:child1.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The child1\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:property1A.Id AND The_Ultimate_Parent_Account__c=null].size()==1, 'Fail: The property1A\'s Ulimate Parent Account Needs null');
        System.assert([SELECT Id FROM Account WHERE Id=:child2.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The child2\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:child3.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The child3\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:grandChild31.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The grandChild31\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:greatGrandChild311.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The greatGrandChild311\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:property311A.Id AND The_Ultimate_Parent_Account__c=null].size()==1, 'Fail: The property311A\'s Ulimate Parent Account Needs null');
    }

    //STAR-4130
    @isTest
    private static void testNoUltimateParentCalculatedOneOff() {
        Account grandParentAcc = (Account)TestFactory.createSObject(new Account(RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PARENT).getRecordTypeId(), Name='GrandParent', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account parentAcc = (Account)TestFactory.createSObject(new Account(ParentId=grandParentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PARENT).getRecordTypeId(), Name='Parent', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child1 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child1', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account property1A = (Account)TestFactory.createSObject(new Account(ParentId=child1.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId(), Name='Property1A', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child2 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child2', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child3 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child3', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account grandChild31 = (Account)TestFactory.createSObject(new Account(ParentId=child3.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='Child4', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account greatGrandChild311 = (Account)TestFactory.createSObject(new Account(ParentId=grandChild31.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId(), Name='greatGrandChild311', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);
        Account property311A = (Account)TestFactory.createSObject(new Account(ParentId=greatGrandChild311.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId(), Name='Property311A', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults', true);

        Map<Id, Account> newAccById = new Map<Id, Account>();
        
        for (Account acc :[SELECT Id, ParentId FROM Account WHERE Id=:grandChild31.Id]) {
            newAccById.put(acc.Id, acc);
        }
        System.debug('~~~~~ UltimateParentRollupServiceTest::testNewAccounts: newAccById.keySet - ' + newAccById.keySet() + '  newAccById.values - ' + newAccById.values());
        Test.startTest();
        UltimateParentRollupService urs = new UltimateParentRollupService();
        Set<Id> ids = urs.setUltimateParent(newAccById.keySet());
        Test.stopTest();

        /*
        System.assert([SELECT Id FROM Account WHERE Id=:grandParentAcc.Id AND The_Ultimate_Parent_Account__c=null].size()==1, 'Fail, GrandParentAcc test fail');
        System.assert([SELECT Id FROM Account WHERE Id=:parentAcc.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The parentAcc\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:child1.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The child1\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:property1A.Id AND The_Ultimate_Parent_Account__c=null].size()==1, 'Fail: The property1A\'s Ulimate Parent Account Needs null');
        System.assert([SELECT Id FROM Account WHERE Id=:child2.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The child2\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:child3.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The child3\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        */
        System.assert([SELECT Id FROM Account WHERE Id=:grandChild31.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The grandChild31\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:greatGrandChild311.Id AND The_Ultimate_Parent_Account__c=:grandParentAcc.Id].size()==1, 'Fail: The greatGrandChild311\'s Ulimate Parent Account Needs to be the GrandParentAcc');
        System.assert([SELECT Id FROM Account WHERE Id=:property311A.Id AND The_Ultimate_Parent_Account__c=null].size()==1, 'Fail: The property311A\'s Ulimate Parent Account Needs null');
    }    
}