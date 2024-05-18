/**
 * @description       : This is the test class for MapCampaignMemberService
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-09-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class MapCampaignMemberServiceTest {
    private static String campaignName='Test Campaign';

    @TestSetup
    static void makeData(){
        //turn off data admin
        TestFactory.turnOffDataAdminAllExceptTrigger();

        //create campaign
        TestFactory.createSObject(new Campaign(Name=campaignName), true);
    }

    @isTest 
    static void testUpdateBulkCommonSameCampaignAccount(){
        //test test the common maps scenario of a user selecting a group of accounts and assigning them the same campaign name trigger
       
        //setup test data
        Integer totalNum = 200;

        List<Account> accLst = new List<Account>();
        for (Integer i=0 ; i < totalNum ; i++) {
            accLst.add((Account)TestFactory.createSObject(new Account(Name='Test Account ' + String.valueOf(i)), 'TestFactoryDefaults.AccountDefaults'));
        }
        insert accLst;  

        List<Contact> conLst = new List<Contact>();
        Integer c = 0;
        for (Account a : accLst) {
            conLst.add((Contact)TestFactory.createSObject(new Contact(LastName='Test'+String.valueOf(c), AccountId=a.Id), 'TestFactoryDefaults.ContactDefaults'));
            c++;
        }
        insert conLst;
        
        TriggerDispatcher.tc.clear();
        
        List<Account> updAccLst = new List<Account>();
        for (Account acc : [SELECT Id FROM Account]) {
            updAccLst.add(new Account(Id=acc.Id, Maps_Campaign_Trigger__c=campaignName));
        }
        update updAccLst;
        Test.startTest();
        MapCampaignMemberService.createCampaignMembers(new Map<Id, Account>(updAccLst), null);
        Test.stopTest();

        Set<Id> accIds = new Set<Id>(new Map<Id, Account>(updAccLst).keySet());
        Set<Id> conIds = new Set<Id>(new Map<Id, Contact>(conLst).keySet());
        Id campId = [SELECT Id FROM Campaign Limit 1].Id;

        System.assertEquals(totalNum, [SELECT Id FROM AccountContactRelation].size(), 'Account Contact Relationship Number wrong');
        System.assertEquals(totalNum, [SELECT Id FROM CampaignMember WHERE AccountId IN : accIds AND CampaignId=:campId].size(), 'Number of Campaign Members associated with Accounts wrong');
        System.assertEquals(totalNum, [SELECT Id FROM CampaignMember WHERE ContactId IN : conIds AND CampaignId=:campId].size(), 'Number of Campaign Members associated with Contacts wrong');
    }

    @isTest
    static void testSameContactMultipleAccountsSameCampaignBulk() {
        //The same contacts are associated to multiple accounts; all those accounts are associated to the same campaign
        Integer totalNumAcc = 200;
        Integer totalNumCon = 100;

        //setup test data
        Integer totalNum = 200;

        List<Account> accLst = new List<Account>();
        for (Integer i=0 ; i < totalNumAcc ; i++) {
            accLst.add((Account)TestFactory.createSObject(new Account(Name='Test Account ' + String.valueOf(i)), 'TestFactoryDefaults.AccountDefaults'));
        }
        insert accLst;  

        List<Contact> conLst = new List<Contact>();
        for (Integer i=0 ; i < totalNumCon ; i++) {
            conLst.add((Contact)TestFactory.createSObject(new Contact(LastName='Test'+String.valueOf(i), AccountId=accLst[i].Id), 'TestFactoryDefaults.ContactDefaults'));
        }
        insert conLst;

        List<AccountContactRelation> accConRelLst = new List<AccountContactRelation>();
        Integer c = 0;
        for (Integer i=totalNumCon ; i < totalNumAcc ; i++) {
            accConRelLst.add(new AccountContactRelation(ContactId=conLst[c].Id, AccountId=accLst[i].Id));
            c++;
        }
        insert accConRelLst;

        TriggerDispatcher.tc.clear();
        List<Account> updAccLst = new List<Account>();
        for (Account acc : [SELECT Id FROM Account]) {
            updAccLst.add(new Account(Id=acc.Id, Maps_Campaign_Trigger__c=campaignName));
        }
        update updAccLst;
        Test.startTest();
        MapCampaignMemberService.createCampaignMembers(new Map<Id, Account>(updAccLst), null);
        Test.stopTest();

        Set<Id> accIds = new Set<Id>(new Map<Id, Account>(updAccLst).keySet());
        Set<Id> conIds = new Set<Id>(new Map<Id, Contact>(conLst).keySet());
        Id campId = [SELECT Id FROM Campaign Limit 1].Id;

        System.assertEquals(totalNumAcc, [SELECT Id FROM AccountContactRelation].size(), 'Account Contact Relationship Number wrong');
        System.assertEquals(totalNumAcc, [SELECT Id FROM CampaignMember WHERE AccountId IN : accIds AND CampaignId=:campId].size(), 'Number of Campaign Members associated with Accounts wrong');
        System.assertEquals(totalNumCon, [SELECT Id FROM CampaignMember WHERE ContactId IN : conIds AND CampaignId=:campId].size(), 'Number of Campaign Members associated with Contacts wrong');
    }
    
    @isTest
    static void testSameContactMultipleAccountsDifferentCampaignBulk() {
        Integer totalNumAcc = 200;
        Integer totalNumCon = 100;

        //setup test data
        Integer totalNum = 200;

        List<Account> accLst = new List<Account>();
        for (Integer i=0 ; i < totalNumAcc ; i++) {
            accLst.add((Account)TestFactory.createSObject(new Account(Name='Test Account ' + String.valueOf(i)), 'TestFactoryDefaults.AccountDefaults'));
        }
        insert accLst;  

        List<Contact> conLst = new List<Contact>();
        for (Integer i=0 ; i < totalNumCon ; i++) {
            conLst.add((Contact)TestFactory.createSObject(new Contact(LastName='Test'+String.valueOf(i), AccountId=accLst[i].Id), 'TestFactoryDefaults.ContactDefaults'));
        }
        insert conLst;

        List<AccountContactRelation> accConRelLst = new List<AccountContactRelation>();
        Integer c = 0;
        for (Integer i=totalNumCon ; i < totalNumAcc ; i++) {
            accConRelLst.add(new AccountContactRelation(ContactId=conLst[c].Id, AccountId=accLst[i].Id));
            c++;
        }
        insert accConRelLst;

        Campaign camp2 = new Campaign(Name='Campaign2');
        insert camp2;

        TriggerDispatcher.tc.clear();
        List<Account> updAccLst = new List<Account>();
        Integer i = 0;
        for (Account acc : [SELECT Id FROM Account]) {
            if (i < totalNumCon) {
                updAccLst.add(new Account(Id=acc.Id, Maps_Campaign_Trigger__c=campaignName));
            } else {
                updAccLst.add(new Account(Id=acc.Id, Maps_Campaign_Trigger__c=camp2.Name));
            }
            i++;
        }
        update updAccLst;
        Test.startTest();
        MapCampaignMemberService.createCampaignMembers(new Map<Id, Account>(updAccLst), null);
        Test.stopTest();

        Set<Id> accIds = new Set<Id>(new Map<Id, Account>(updAccLst).keySet());
        Set<Id> conIds = new Set<Id>(new Map<Id, Contact>(conLst).keySet());
        Id campId = [SELECT Id FROM Campaign Limit 1].Id;

        System.assertEquals(totalNumAcc, [SELECT Id FROM AccountContactRelation].size(), 'Account Contact Relationship Number wrong');
        System.assertEquals(totalNumCon, [SELECT Id FROM CampaignMember WHERE AccountId IN : accIds AND CampaignId=:campId].size(), 'Number of Campaign Members associated with Accounts wrong');
        System.assertEquals(totalNumCon, [SELECT Id FROM CampaignMember WHERE ContactId IN : conIds AND CampaignId=:campId].size(), 'Number of Campaign Members associated with Contacts wrong');  
        System.assertEquals(totalNumCon, [SELECT Id FROM CampaignMember WHERE AccountId IN : accIds AND CampaignId=:camp2.Id].size(), 'Number of Campaign Members associated with Accounts wrong');
        System.assertEquals(totalNumCon, [SELECT Id FROM CampaignMember WHERE ContactId IN : conIds AND CampaignId=:camp2.Id].size(), 'Number of Campaign Members associated with Contacts wrong');        
    }

    @isTest 
    static void testUpdateBulkExistingSameCampaignAccount(){
        //test test the common maps scenario of a user selecting a group of accounts and assigning them the same campaign name trigger
       
        //setup test data
        Integer totalNum = 200;
        Id campId = [SELECT Id FROM Campaign Limit 1].Id;

        List<Account> accLst = new List<Account>();
        for (Integer i=0 ; i < totalNum ; i++) {
            accLst.add((Account)TestFactory.createSObject(new Account(Name='Test Account ' + String.valueOf(i)), 'TestFactoryDefaults.AccountDefaults'));
        }
        insert accLst;  

        List<Contact> conLst = new List<Contact>();
        Integer c = 0;
        for (Account a : accLst) {
            conLst.add((Contact)TestFactory.createSObject(new Contact(LastName='Test'+String.valueOf(c), AccountId=a.Id), 'TestFactoryDefaults.ContactDefaults'));
            c++;
        }
        insert conLst;

        //create existing account & contact campaign members
        List<CampaignMember> campMemLst = new List<CampaignMember>();
        
        for (Integer i=0 ; i < totalNum/2 ; i++) {
            campMemLst.add(new CampaignMember(CampaignId=campId, AccountId=accLst[i].Id));
            campMemLst.add(new CampaignMember(CampaignId=campId, ContactId=conLst[i].Id));
        }
        insert campMemLst;

        //pretest checks
        Set<Id> preAccIds = new Set<Id>(new Map<Id, Account>(accLst).keySet());
        Set<Id> preConIds = new Set<Id>(new Map<Id, Contact>(conLst).keySet());
        System.assertEquals(totalNum, [SELECT Id FROM AccountContactRelation].size(), 'Account Contact Relationship Number wrong');
        System.assertEquals(totalNum/2, [SELECT Id FROM CampaignMember WHERE AccountId IN : preAccIds AND CampaignId=:campId].size(), 'Number of Existing Campaign Members associated with Accounts wrong');
        System.assertEquals(totalNum/2, [SELECT Id FROM CampaignMember WHERE ContactId IN : preConIds AND CampaignId=:campId].size(), 'Number of Existing Campaign Members associated with Contacts wrong');
        
        TriggerDispatcher.tc.clear();
        
        List<Account> updAccLst = new List<Account>();
        for (Account acc : [SELECT Id FROM Account]) {
            updAccLst.add(new Account(Id=acc.Id, Maps_Campaign_Trigger__c=campaignName));
        }
        update updAccLst;
        Test.startTest();
        MapCampaignMemberService.createCampaignMembers(new Map<Id, Account>(updAccLst), null);
        Test.stopTest();

        Set<Id> accIds = new Set<Id>(new Map<Id, Account>(updAccLst).keySet());
        Set<Id> conIds = new Set<Id>(new Map<Id, Contact>(conLst).keySet());
        System.assertEquals(totalNum, [SELECT Id FROM CampaignMember WHERE AccountId IN : accIds AND CampaignId=:campId].size(), 'Number of Campaign Members associated with Accounts wrong');
        System.assertEquals(totalNum, [SELECT Id FROM CampaignMember WHERE ContactId IN : conIds AND CampaignId=:campId].size(), 'Number of Campaign Members associated with Contacts wrong');
    }    

    @isTest
    static void testSameParentContactMultipleChildAccountsDifferentCampaignBulk() {
        Integer totalNumAcc = 200;
        Integer totalNumCon = 100;

        //setup test data
        Integer totalNum = 200;

        Account parentAcc = (Account)TestFactory.createSObject(new Account(Name='Parent Account'), 'TestFactoryDefaults.AccountDefaults', true);
        List<Account> accLst = new List<Account>();
        for (Integer i=0 ; i < totalNumAcc ; i++) {
            accLst.add((Account)TestFactory.createSObject(new Account(Name='Test Account ' + String.valueOf(i), ParentId=parentAcc.Id), 'TestFactoryDefaults.PropertyDefaults'));
        }
        insert accLst;  

        List<Contact> conLst = new List<Contact>();
        for (Integer i=0 ; i < totalNumCon ; i++) {
            conLst.add((Contact)TestFactory.createSObject(new Contact(LastName='Test'+String.valueOf(i), AccountId=parentAcc.Id), 'TestFactoryDefaults.ContactDefaults'));
        }
        insert conLst;

        Campaign camp2 = new Campaign(Name='Campaign2');
        insert camp2;

        TriggerDispatcher.tc.clear();
        List<Account> updAccLst = new List<Account>();
        Integer i = 0;
        for (Account acc : [SELECT Id FROM Account WHERE RecordTypeId=:GeneralConstants.RT_ID_ACC_PROPERTY]) {
            if (i < totalNumCon) {
                updAccLst.add(new Account(Id=acc.Id, Maps_Campaign_Trigger__c=campaignName));
            } else {
                updAccLst.add(new Account(Id=acc.Id, Maps_Campaign_Trigger__c=camp2.Name));
            }
            i++;
        }
        update updAccLst;
        Test.startTest();
        MapCampaignMemberService.createCampaignMembers(new Map<Id, Account>(updAccLst), null);
        Test.stopTest();

        Set<Id> accIds = new Set<Id>(new Map<Id, Account>(updAccLst).keySet());
        Set<Id> conIds = new Set<Id>(new Map<Id, Contact>(conLst).keySet());
        Id campId = [SELECT Id FROM Campaign Limit 1].Id;

        System.assertEquals(totalNumCon, [SELECT Id FROM AccountContactRelation].size(), 'Account Contact Relationship Number wrong');
        System.assertEquals(totalNumCon, [SELECT Id FROM CampaignMember WHERE AccountId IN : accIds AND CampaignId=:campId].size(), 'Number of Campaign Members associated with Accounts wrong');
        System.assertEquals(totalNumCon, [SELECT Id FROM CampaignMember WHERE ContactId IN : conIds AND CampaignId=:campId].size(), 'Number of Campaign Members associated with Contacts of Parents wrong for first Campaign');  
        System.assertEquals(totalNumCon, [SELECT Id FROM CampaignMember WHERE AccountId IN : accIds AND CampaignId=:camp2.Id].size(), 'Number of Campaign Members associated with Accounts wrong');
        System.assertEquals(totalNumCon, [SELECT Id FROM CampaignMember WHERE ContactId IN : conIds AND CampaignId=:camp2.Id].size(), 'Number of Campaign Members associated with Contacts of Parents wrong for second Campaign');        
    }    
    
}