/**
 * @File Name          : TestFactoryTest.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 03-20-2023
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0      2/26/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
@IsTest
private class TestFactoryTest{

    @TestSetup
    static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=false;
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

    @IsTest
    static void when_objectIsCreated_expect_defaultFieldsArePopulated(){
        //when
        Account a = (Account)TestFactory.createSObject(new Account());
        //then
        System.assertEquals('Test Account', a.Name, 'Expecting Default field value is set to specific value');
    }

    @IsTest
    static void when_objectIsInserted_expect_defaultFieldsArePopulated(){
        //when
        Account a = (Account)TestFactory.createSObject(new Account(),true);
        //then
        a = [SELECT Name FROM Account WHERE Id = :a.Id];
        System.assertEquals('Test Account', a.Name, 'Expecting Default field value is set to specific value');
    }

    @IsTest
    static void when_objectIsCreatedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated(){
        //when
        Account a = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.MyAccountDefaults');
        //then
        System.assertEquals('My Test Account', a.Name, 'Expecting Default field value is set to specific value');
    }

    @IsTest
    static void when_objectIsInsertedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated(){
        //when
        Account a = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.MyAccountDefaults', true);
        //then
        System.assertEquals('My Test Account', a.Name, 'Expecting Default field value is set to specific value');
    }

    @IsTest
    static void when_ListOfObjectsIsCreated_expect_defaultFieldsArePopulated(){
        //when
        Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 200);
        //then
        for(Account a : aList){
            System.assert(a.Name.startsWith('Test Account'), 'Expecting Default field value is set to specific value');
        }
    }

    @IsTest
    static void when_ListOfObjectIsInserted_expect_defaultFieldsArePopulated(){
        //when
        Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 200, true);
        //then
        aList = [SELECT Name FROM Account WHERE Id IN :aList ORDER BY Name];
        for(Account a : aList){
            System.assert(a.Name.startsWith('Test Account'), 'Expecting Default field value is set to specific value');
        }
    }

    @IsTest
    static void when_ListOfObjectsIsCreatedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated(){
        //when
        Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 200, 'TestFactoryDefaults.MyAccountDefaults');
        //then
        for(Account a : aList){
            System.assert(a.Name.startsWith('My Test Account'), 'Expecting Default field value is set to specific value');
        }
    }

    @IsTest
    static void when_ListOfObjectsIsInsertedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated(){
        //when
        Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 200, 'TestFactoryDefaults.MyAccountDefaults', true);
        //then
        aList = [SELECT Name FROM Account WHERE Id IN :aList ORDER BY Name];
        for(Account a : aList){
            System.assert(a.Name.startsWith('My Test Account'), 'Expecting Default field value is set to specific value');
        }
    }

}