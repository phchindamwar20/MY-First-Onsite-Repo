/**
 * @description       : This is the test class for ICertisUserProvisionQueueable, we will be testing here with one user 
 *                      record only as Icertis API's only accept one user at a time.
 * @author            : Arpit Vashishtha
 * @group             : 
 * @last modified on  : 03-18-2024
 * @last modified by  : Terri Jiles
**/
@isTest
private without sharing class ICertisUserProviReProviQueueableTest {
    private static final String ICERTIS_USER_REPROVISIONING_SELECTION = 'SelectionICertisUserProvOrReprov';
    private static final String ICERTIS_USER_REPROVISIONING_QUEUEABLE = 'ICertisUserProviReProviQueueable';
    private static final Integer numRec = 1;
    
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
        
        // Creating Standard user
        Profile profileObj = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User standardICUserObj = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing27062022001', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = profileObj.Id, isActive = TRUE, Country = 'Australia', 
                                TimeZoneSidKey='America/Los_Angeles', UserName='testing27062022001@testorg.com', IC_User__c = TRUE);
        insert standardICUserObj;
        
        // Creating Standard user
        User standardReProvUserObj = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing27062022001', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = profileObj.Id, isActive = TRUE, Country = 'Australia', 
                                TimeZoneSidKey='America/Los_Angeles', UserName='testing27062022002@testorg.com', IC_User__c = FALSE, IC_Status__c = 'De-Provisioned');
        insert standardReProvUserObj;
        
        // Creating Standard user
        User standardProvUserObj = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing27062022001', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = profileObj.Id, isActive = TRUE, Country = 'Australia', 
                                TimeZoneSidKey='America/Los_Angeles', UserName='testing27062022003@testorg.com');
        insert standardProvUserObj;
    }
    
    @isTest 
    private static void testICertisUserDeProvisionQueueableInsert() {
        System.assertEquals(null, [SELECT Id, IC_Status__c FROM User WHERE UserName =: 'testing27062022001@testorg.com'].IC_Status__c, 'Fail:  Prevalidation check field, user IC_Status__c should be blank.'); 
        Map<Id, User> oldUserById = new Map<Id, User>([SELECT Id, IsActive, IC_User__c FROM User WHERE UserName =: 'testing27062022001@testorg.com']);
        Map<Id, User> newUserById = new Map<Id, User>();
        
        for (User userObj : [SELECT Id, IC_User__c FROM User WHERE UserName =: 'testing27062022001@testorg.com']) {
            newUserById.put(userObj.Id, new User(Id=userObj.Id, IC_User__c=FALSE));
        }
        update newUserById.values();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ExecutionService chainQueueableJobService = new ExecutionService();
        ExecutionItem ei = new ExecutionItem([SELECT Id, Object__c, Order__c, Queueable_Class_Name__c, Selection_Name__c, Trigger_Operation__c, Is_Delay__c, Delay_In_Minutes__c 
                                                FROM Execute_Item_Configuration__mdt
                                                WHERE Selection_Name__c=:ICERTIS_USER_REPROVISIONING_SELECTION LIMIT 1], newUserById, oldUserById);
        List<ExecutionItem> justMapCampaignMemberItmLst = new List<ExecutionItem>();
        justMapCampaignMemberItmLst.add(ei);

        chainQueueableJobService.executeInitialHandler(justMapCampaignMemberItmLst);
        Test.stopTest();
        
        System.debug('~~~~ ei ' + ei);
        System.assertEquals(true, !ei.getSelection().getRecIds().isEmpty(),  'Fail:  DeProvisioned didnt\'t happen.');
        System.debug('~~~~ De-Provisioned User: ' + [SELECT Id, IC_Status__c FROM User]);
        System.assertEquals('De-Provisioned', [SELECT Id, IC_Status__c FROM User WHERE UserName =: 'testing27062022001@testorg.com'].IC_Status__c, 'Fail:  It did not De-Provision the user.');        
    }
    
    @isTest 
    private static void testICertisUserReProvisionQueueableInsert() {
        System.assertEquals('De-Provisioned', [SELECT Id, IC_Status__c FROM User WHERE UserName =: 'testing27062022002@testorg.com'].IC_Status__c, 'Fail:  Prevalidation check field, user IC_Status__c should be De-Provisioned.'); 
        Map<Id, User> oldUserById = new Map<Id, User>([SELECT Id, IsActive, IC_User__c FROM User WHERE UserName =: 'testing27062022002@testorg.com']);
        Map<Id, User> newUserById = new Map<Id, User>();
        
        for (User userObj : [SELECT Id, IC_User__c FROM User WHERE UserName =: 'testing27062022002@testorg.com']) {
            newUserById.put(userObj.Id, new User(Id=userObj.Id, IC_User__c=TRUE));
        }
        update newUserById.values();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ExecutionService chainQueueableJobService = new ExecutionService();
        ExecutionItem ei = new ExecutionItem([SELECT Id, Object__c, Order__c, Queueable_Class_Name__c, Selection_Name__c, Trigger_Operation__c, Is_Delay__c, Delay_In_Minutes__c  
                                                FROM Execute_Item_Configuration__mdt
                                                WHERE Selection_Name__c=:ICERTIS_USER_REPROVISIONING_SELECTION LIMIT 1], newUserById, oldUserById);
        List<ExecutionItem> justMapCampaignMemberItmLst = new List<ExecutionItem>();
        justMapCampaignMemberItmLst.add(ei);

        chainQueueableJobService.executeInitialHandler(justMapCampaignMemberItmLst);
        Test.stopTest();
        
        System.debug('~~~~ ei ' + ei);
        System.assertEquals(true, !ei.getSelection().getRecIds().isEmpty(),  'Fail:  ReProvisioned didnt\'t happen.');
        System.debug('~~~~ Re-Provisioned User: ' + [SELECT Id, IC_Status__c FROM User]);
        System.assertEquals('Re-Provisioned', [SELECT Id, IC_Status__c FROM User WHERE UserName =: 'testing27062022002@testorg.com'].IC_Status__c, 'Fail:  It did not Re-Provision the user.');        
    }
    
    @isTest 
    private static void testICertisUserProvisionQueueableInsert() {
        System.assertEquals(null, [SELECT Id, IC_Status__c FROM User WHERE UserName =: 'testing27062022003@testorg.com'].IC_Status__c, 'Fail:  Prevalidation check field, user IC_Status__c should be blank.'); 
        Map<Id, User> oldUserById = new Map<Id, User>([SELECT Id, IsActive, IC_User__c FROM User WHERE UserName =: 'testing27062022003@testorg.com']);
        Map<Id, User> newUserById = new Map<Id, User>();
        
        for (User userObj : [SELECT Id, IC_User__c FROM User WHERE UserName =: 'testing27062022003@testorg.com']) {
            newUserById.put(userObj.Id, new User(Id=userObj.Id, IC_User__c=TRUE));
        }
        update newUserById.values();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ExecutionService chainQueueableJobService = new ExecutionService();
        ExecutionItem ei = new ExecutionItem([SELECT Id, Object__c, Order__c, Queueable_Class_Name__c, Selection_Name__c, Trigger_Operation__c, Is_Delay__c, Delay_In_Minutes__c  
                                                FROM Execute_Item_Configuration__mdt
                                                WHERE Selection_Name__c=:ICERTIS_USER_REPROVISIONING_SELECTION LIMIT 1], newUserById, oldUserById);
        List<ExecutionItem> justMapCampaignMemberItmLst = new List<ExecutionItem>();
        justMapCampaignMemberItmLst.add(ei);

        chainQueueableJobService.executeInitialHandler(justMapCampaignMemberItmLst);
        Test.stopTest();
        
        System.debug('~~~~ ei ' + ei);
        System.assertEquals(true, !ei.getSelection().getRecIds().isEmpty(),  'Fail:  Provisioned didnt\'t happen.');
        System.debug('~~~~ Provisioned User: ' + [SELECT Id, IC_Status__c FROM User]);
        System.assertEquals('Provisioned', [SELECT Id, IC_Status__c FROM User WHERE UserName =: 'testing27062022003@testorg.com'].IC_Status__c, 'Fail:  It did not Provision the user.');        
    }
}