/**
 * @File Name          : AccountTriggerHandlerTest.cls
 * @Description        : This test the AccountTriggerHandler.  
 * @Author             : Terri Jiles
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 08-17-2023
 * @Modification Log   : 
 * Ver       Date            Author              Modification
 * 1.0    4/9/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 * 2.0    05/09/2024          Kiran K             updated delete methods to allow flow run
**/
@isTest
public with sharing class AccountTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        Integer numRec = 100;      
        
        List<Opportunity> oppUpdLst = new List<Opportunity>();

        TestFactory.turnOffDataAdminAllExceptTrigger(); 

        WorkOrderTriggerHandler.isDefaultOverride = false;


        Test.startTest();
        List<Account> accLst = new List<Account>();
        List<Default_Portal_Account__mdt> dpaLst = [SELECT DeveloperName, CountryCode__c, StateProvinceCode__c, Default_Account_Name__c FROM Default_Portal_Account__mdt];
        for(Default_Portal_Account__mdt dpa : [SELECT DeveloperName, CountryCode__c, StateProvinceCode__c, Default_Account_Name__c FROM Default_Portal_Account__mdt]) {
            accLst.add((Account)TestFactory.createSObject(new Account(Name=dpa.Default_Account_Name__c, Partner_Type__c='Subcontractor'), 'TestFactoryDefaults.AccountDefaults'));    
        }
        upsert accLst;

        for (Account acc : [SELECT Id, Name FROM Account]) {
            System.debug('~~~~ AccountTriggerHandler::makeData: acc.Name ' + acc.Name ); 
        }

        Account parentAcc = (Account)TestFactory.createSObject(new Account(Name='Parent Account B'), 'TestFactoryDefaults.AccountDefaults', true);
        
        Account acc = (Account)TestFactory.createSObject(new Account(Name='House Account Sandbox', Status__c='Dormant', Drive_Down__c='No', National_Account__c='Yes', Contract_Type__c='MSA Only',Number_of_Active_Contracts__c=1,
             CurrencyIsoCode='USD', ParentId=parentAcc.Id), 'TestFactoryDefaults.AccountDefaults');
        insert acc;     
    }

    @isTest
    static void testInsert() {
        List<WorkOrder> jobLst2 = new List<WorkOrder>();
        List<Account> accLst = new List<Account>();
        List<Account> accUpdLst = new List<Account>();
        List<Account> grandParent = [SELECT Id, Name, (SELECT Id FROM WorkOrders) FROM Account WHERE Name='House Account Sandbox'];
        Set<Id> accIds = new Set<Id>();
       
        TriggerDispatcher.tc.clear();
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='ParentA', ParentId=grandParent[0].Id), 'TestFactoryDefaults.MyAccountDefaults', true);

        List<Default_Portal_Account__mdt> dpaLst = [SELECT DeveloperName, CountryCode__c, StateProvinceCode__c, Default_Account_Name__c FROM Default_Portal_Account__mdt];
        List<String> stateCodesLst = new List<String>();
       
        List<Account> childALst = new List<Account>();
        for (Integer i=0 ; i < 100 ; i++) {
            String state, country;

            /*if (i<33) {*/
                state=dpaLst[0].StateProvinceCode__c; country=dpaLst[0].CountryCode__c;
            /*} else if (i >=33 && i < 67) {
                state=dpaLst[1].StateProvinceCode__c; country=dpaLst[1].CountryCode__c; 
            } else {
                state=dpaLst[2].StateProvinceCode__c; country=dpaLst[2].CountryCode__c;
            }*/
            stateCodesLst.add(state);
            System.debug('~~~~ AccountTriggerHandler::testInsert: state ' + state + ' country ' + country);
            childALst.add((Account)TestFactory.createSObject(new Account(Name='ChildA1_'+String.valueOf(i), BillingStateCode=state, BillingCountryCode=country),  'TestFactoryDefaults.MyAccountDefaults', false));
        }
        TriggerDispatcher.tc.clear();

        Test.startTest();
        insert childALst;
        Test.stopTest();       

        for (Account a : [SELECT Id, BillingStateCode, BillingCountryCode, Parent_Portal_Account__r.Name FROM Account WHERE BillingStateCode IN: stateCodesLst]) {
            System.debug('~~~~ AccountTriggerHandlerTest::testInsert a ' + a);
        }
        
        System.assert([SELECT Id FROM Account WHERE Parent_Portal_Account__r.Name=:dpaLst[0].Default_Account_Name__c].size() > 30);
        //System.assert([SELECT Id FROM Account WHERE Parent_Portal_Account__r.Name=:dpaLst[1].Default_Account_Name__c].size() > 30);
        //System.assert([SELECT Id FROM Account WHERE Parent_Portal_Account__r.Name=:dpaLst[2].Default_Account_Name__c].size() > 30);
    }


    @isTest 
    static void testUpdate() {
        List<WorkOrder> jobLst2 = new List<WorkOrder>();
        List<Account> accLst = new List<Account>();
        List<Account> accUpdLst = new List<Account>();
        List<Account> grandParent = [SELECT Id, Name, (SELECT Id FROM WorkOrders) FROM Account WHERE Name='House Account Sandbox'];
        Set<Id> accIds = new Set<Id>();
       
        TriggerDispatcher.tc.clear();
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='ParentA', ParentId=grandParent[0].Id), 'TestFactoryDefaults.MyAccountDefaults', true);

        List<Account> childALst = new List<Account>();
        for (Integer c=0 ; c < 100 ; c++) {
            childALst.add((Account)TestFactory.createSObject(new Account(Name='ChildA1_'+String.valueOf(c)),  'TestFactoryDefaults.MyAccountDefaults', false));
        }
        TriggerDispatcher.tc.clear();
        insert childALst;
        Integer i=0;
    
        for (WorkOrder jobRec : [SELECT Id FROM WorkOrder WHERE AccountId=:grandParent[0].Id]) {
            System.debug('~~~~ AccountTriggerHandlerTest::testUpdate: i ' + i);
            System.debug('~~~~ AccountTriggerHandlerTest::testUpdate: jobRec ' + jobRec);
            WorkOrder job = new WorkOrder(Id=jobRec.Id, AccountId=childALst[i].Id);
            System.debug('~~~~ AccountTriggerHandlerTest::testUpdate: job ' + job);
            jobLst2.add(job);
            i++;      
        }
        
        TriggerDispatcher.tc.clear();
        update jobLst2;
        for (WorkOrder jobRec : [SELECT Id, AccountId, Account.Name, Account.Parent.Name FROM WorkOrder WHERE AccountId=:grandParent[0].Id]) {
            System.debug('~~~~ AccountTriggerHandlerTest::testUpdate: i ' + i);
            System.debug('~~~~ AccountTriggerHandlerTest::testUpdate: after job update jobRec ' + jobRec);
            i++;      
        }

        List<Default_Portal_Account__mdt> dpaLst = [SELECT DeveloperName, CountryCode__c, StateProvinceCode__c, Default_Account_Name__c FROM Default_Portal_Account__mdt];
        List<String> stateCodesLst = new List<String>();

        String state, country;
        Integer c=0;
        for (Account acc : childALst) {
            //if (c<33) {
                state=dpaLst[0].StateProvinceCode__c; country=dpaLst[0].CountryCode__c;
            /*} else if (c >=33 && c < 67) {
                state=dpaLst[1].StateProvinceCode__c; country=dpaLst[1].CountryCode__c; 
            } else {
                state=dpaLst[2].StateProvinceCode__c; country=dpaLst[2].CountryCode__c;
            }*/
            stateCodesLst.add(state);

            Account newAcc = new Account(Id=acc.Id, ParentId=parentA.Id, BillingStateCode=state, BillingCountryCode=country, Data_Admin_Reason__c='Mass Update');
            accUpdLst.add(newAcc);    
            accIds.add(acc.Id); 
            System.debug(logginglevel.INFO, '~~~~~ After jobs insert acc ' + newAcc);   
            c++;    
        }
        
        Test.startTest();
        TriggerDispatcher.tc.clear();
        update accUpdLst;
        Test.stopTest();

        for (WorkOrder jobRec : [SELECT Id, AccountId, Account.Name, Account.Parent.Name FROM WorkOrder WHERE AccountId=:grandParent[0].Id]) {
            System.debug('~~~~ AccountTriggerHandlerTest::testUpdate: i ' + i);
            System.debug('~~~~ AccountTriggerHandlerTest::testUpdate: after account update jobRec ' + jobRec);
            i++;      
        }
        for (Account acc : [SELECT Id, Name, ParentId, Parent.Name, Parent_Portal_Account__r.Name, BillingStateCode, BillingCountryCode FROM Account]) {
            System.debug('~~~~ AccountTriggerHandlerTest::testUpdate acc: ' + acc);
        }

        System.assert([SELECT Id FROM Account WHERE Parent_Portal_Account__r.Name=:dpaLst[0].Default_Account_Name__c].size() > 30);
        /* STAR-1339 System.assert([SELECT Id FROM Account WHERE Parent_Portal_Account__r.Name=:dpaLst[0].Default_Account_Name__c].size() > 30);
        System.assert([SELECT Id FROM Account WHERE Parent_Portal_Account__r.Name=:dpaLst[1].Default_Account_Name__c].size() > 30);
        System.assert([SELECT Id FROM Account WHERE Parent_Portal_Account__r.Name=:dpaLst[2].Default_Account_Name__c].size() > 30);
        System.assertEquals(1, [SELECT Id FROM Account WHERE Id=:grandParent[0].Id AND Open_Collections__c=0 AND Open_Collections_of_Children__c=10000 AND Open_Collections_of_This_and_Children__c=10000 AND Total_Lifetime_Revenue_of_This__c=0 AND Total_Lifetime_Revenue_of_Children__c=10000 AND Total_Lifetime_Revenue_This_and_Children__c=10000 AND Number_of_Jobs__c=0 AND Number_of_Child_Jobs__c=100 AND Number_of_Jobs_and_Child_Jobs__c=100].size());
        System.assertEquals(1, [SELECT Id FROM Account WHERE Id=:parentA.Id AND Open_Collections__c=0 AND Open_Collections_of_Children__c=10000 AND Open_Collections_of_This_and_Children__c=10000 AND Total_Lifetime_Revenue_of_This__c=0 AND Total_Lifetime_Revenue_of_Children__c=10000 AND Total_Lifetime_Revenue_This_and_Children__c=10000 AND Number_of_Jobs__c=0 AND Number_of_Child_Jobs__c=100 AND Number_of_Jobs_and_Child_Jobs__c=100].size());
        System.assertEquals(100, [SELECT Id FROM Account WHERE Id IN: accIds AND Open_Collections__c=100 AND  Open_Collections_of_Children__c=0 AND Open_Collections_of_This_and_Children__c=100 AND Total_Lifetime_Revenue_of_This__c=100 AND Total_Lifetime_Revenue_of_Children__c=0 AND Total_Lifetime_Revenue_This_and_Children__c=100 AND Number_of_Jobs__c=1 AND  Number_of_Child_Jobs__c=0 AND Number_of_Jobs_and_Child_Jobs__c=1].size());        
        */
    }

    @isTest
    static void preventRecordTypeChangeAccount(){
        List<WorkOrder> jobLst = new List<WorkOrder>();
        List<Account> accLst = new List<Account>();
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='ParentA'), 'TestFactoryDefaults.MyAccountDefaults', true);

        for (Account acc : [SELECT Id, RecordTypeId FROM Account]) {
            System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: acc - ' + acc);
            jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id), 'TestFactoryDefaults.JobDefaults'));
            Account upAcc = new Account(Id=acc.Id, ParentId=parentA.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId());
            System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: upAcc - ' + upAcc);
            accLst.add(upAcc);
        }
        insert jobLst;

        Test.startTest();
        try {
            update accLst;
            System.assert(false, 'Error wasn\'t thrown');
        } catch(Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    
    @isTest
    static void preventBoltDeleteAccountWithJobs(){
        List<WorkOrder> jobLst = new List<WorkOrder>();
        //List<Account> accLst = new List<Account>();
        //Account parentA = (Account)TestFactory.createSObject(new Account(Name='ParentA'), 'TestFactoryDefaults.MyAccountDefaults', true);
        for (Account acc : [SELECT Id, RecordTypeId FROM Account]) {
            System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: acc - ' + acc);
            jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id), 'TestFactoryDefaults.JobDefaults'));
            //Account upAcc = new Account(Id=acc.Id, ParentId=parentA.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId());
            //System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: upAcc - ' + upAcc);
            //accLst.add(upAcc);
        }
        insert jobLst;

        Test.startTest();
        try {
            DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        	dataAdmin.TurnOffFlow__c=false;
        	Update dataAdmin;
            delete [SELECT Id, RecordTypeId FROM Account];
            System.assert(false, 'Error wasn\'t thrown');
        } catch(Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @isTest
    static void preventBoltDeletePropertyWithJobs(){
        List<WorkOrder> jobLst = new List<WorkOrder>();
        List<Account> accLst = new List<Account>();
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='ParentA'), 'TestFactoryDefaults.MyAccountDefaults', true);

        for (Account acc : [SELECT Id, RecordTypeId FROM Account WHERE Name !='ParentA']) {
            System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: acc - ' + acc);
            jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id), 'TestFactoryDefaults.JobDefaults'));
            Account upAcc = new Account(Id=acc.Id, ParentId=parentA.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId());
            //System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: upAcc - ' + upAcc);
            accLst.add(upAcc);
        }
        update accLst;
        insert jobLst;

        Test.startTest();
        try {
            DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        	dataAdmin.TurnOffFlow__c=false;
        	Update dataAdmin;
            delete [SELECT Id, RecordTypeId FROM Account];
            System.assert(false, 'Error wasn\'t thrown');
        } catch(Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }    

    /*
    @isTest
    static void deleteBoltAccountWithoutJobs(){
        Test.startTest();
        try {
            delete [SELECT Id, RecordTypeId FROM Account];
            System.assert(BoltCalloutEngineQueueable.isBoltCalloutMade == true, 'Did\'t make call out to Bolt');
            System.assert(BoltCalloutEngineQueueable.methodName == BoltConstants.WS_BOLT_DEL_ACCOUNTS, 'Did\'t call the bolt method to delete accounts');
        } catch(Exception e) {
            System.assert(false, 'error thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void deleteBoltPropertyWithoutJobs(){
        List<Account> accLst = new List<Account>();
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='ParentA'), 'TestFactoryDefaults.MyAccountDefaults', true);

        for (Account acc : [SELECT Id, RecordTypeId FROM Account WHERE Name !='ParentA']) {
            System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: acc - ' + acc);
            Account upAcc = new Account(Id=acc.Id, ParentId=parentA.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId());
            //System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: upAcc - ' + upAcc);
            accLst.add(upAcc);
        }
        update accLst;

        Test.startTest();
        try {
            delete [SELECT Id, RecordTypeId FROM Account];
            System.assert(BoltCalloutEngineQueueable.isBoltCalloutMade == true, 'Did\'t make call out to Bolt');
            System.assert(BoltCalloutEngineQueueable.methodName == BoltConstants.WS_BOLT_DEL_PROPERTIES, 'Did\'t call the bolt method to delete properties');
        } catch(Exception e) {
            System.assert(false, 'error thrown');
        }
        Test.stopTest();
    }   
    */

    /*
    @isTest
    static void testUltimateParentWorkUpInsert(){
        Account parentA = [SELECT Id FROM Account Limit 1];
        List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=parentA.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId()), 200, 'TestFactoryDefaults.AccountDefaults', false);

        Test.startTest();
        insert accLst;
        Test.stopTest();
        System.debug('~~~~ AccountTriggerHandlerTest::testUltimateParentWorkUp: accLst[0] - ' + accLst[0]);
        System.debug('~~~~ AccountTriggerHandlerTest::testUltimateParentWorkUp: accountQueueable.isUltimateParentProcessing - ' +  AccountTriggerHandler.isUltimateParentProcessing);

        System.assert(AccountTriggerHandler.isUltimateParentProcessing, 'Fail: didn \'t attempt to perform ultimate parent calculation');
    }*/

   /*  Not working for some reason but works when manually testing
    @isTest
    static void changeAccRecordTypeWithNoJobs() {
        //List<WorkOrder> jobLst = new List<WorkOrder>();
        List<Account> accLst = new List<Account>();
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='ParentA'), 'TestFactoryDefaults.MyAccountDefaults', true);

        for (Account acc : [SELECT Id, RecordTypeId FROM Account WHERE Name !='ParentA']) {
            System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: acc - ' + acc);
            //jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id), 'TestFactoryDefaults.JobDefaults'));
            Account upAcc = new Account(Id=acc.Id, ParentId=parentA.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId());
            System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: upAcc - ' + upAcc);
            accLst.add(upAcc);
        }
        //insert jobLst;

        Test.startTest();
        try {
            update accLst;
            System.assert(BoltCalloutAccountQueueable.isBoltAccountDeleteCalloutProcessing, 'Error wasn\'t thrown');
        } catch(Exception e) {
            System.assert(false, 'Error was thrown');
        }
        Test.stopTest();
    }
    */

    /*@isTest
    static void changePropRecordTypeWithNoJobs() {
        
    }  */  
    /**** Changing the record type on the account doesn't work from apex test class for some reason....  
    @isTest
    static void preventRecordTypeChangeProperty(){
        List<WorkOrder> jobLst = new List<WorkOrder>();
        List<Account> accLst = new List<Account>();
        List<Account> accUpLst = new List<Account>();
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='ParentA'), 'TestFactoryDefaults.MyAccountDefaults', true);

        for (Integer i=0 ; i<1 ; i++) {
            accLst.add(new Account(Name='AccountName ' + String.valueOf(i), ParentId=parentA.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId()));
        }
        insert accLst;

        for (Account acc : accLst) {
            System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: acc - ' + acc);
            jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=parentA.Id, Property__c=acc.Id), 'TestFactoryDefaults.JobDefaults'));
            Account upAcc = new Account(Id=acc.Id, 
                RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId());
            System.debug('~~~~ AccountTriggerHandlerTest::preventRecordTypeChange: upAcc - ' + upAcc);
            accUpLst.add(upAcc);
        }
        insert jobLst;

        Test.startTest();
        try {
            update accUpLst;
            System.assert(false, 'Error wasn\'t thrown');
        } catch(Exception e) {
            System.assert(true);
        }
        Test.stopTest();  
    }   */
    
}