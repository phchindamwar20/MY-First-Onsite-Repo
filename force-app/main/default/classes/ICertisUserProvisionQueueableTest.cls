/**
 * @description       : This is the test class for ICertisUserProvisionQueueable, 
 *                      we will be testing here with one user record only as Icertis API's only accept one user at a time.
 * @author            : Arpit Vashishtha
 * @group             : 
 * @last modified on  : 01-10-2024
 * @last modified by  : Arpit Vashishtha
**/
@isTest
public without sharing class ICertisUserProvisionQueueableTest {
    private static final String ICERTIS_USER_PROVISIONING_SELECTION = 'SelectionICertisUserProvisioning';
    private static final String ICERTIS_USER_PROVISIONING_QUEUEABLE = 'ICertisUserProvisionQueueable';
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
    }
    
    @isTest 
    private static void testICertisUserProvisionQueueableInsert() {
        System.assertEquals(null, [SELECT Id, IC_Status__c FROM User WHERE UserName =: 'testing27062022001@testorg.com'].IC_Status__c, 'Fail:  Prevalidation check field, user IC_Status__c should be blank.'); 
        Map<Id, User> userById = new Map<Id, User>([SELECT Id, IsActive, IC_User__c FROM User WHERE UserName =: 'testing27062022001@testorg.com']);

        List<ExecutionItem> eiLst = new List<ExecutionItem>(); 
        eiLst.add(new ExecutionItem(ICERTIS_USER_PROVISIONING_QUEUEABLE, 0, ICERTIS_USER_PROVISIONING_SELECTION, GeneralConstants.AFTER_INSERT, GeneralConstants.OBJ_USER, userById, null));

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ExecutionService es = new ExecutionService();
        es.executeInitialHandler(eiLst);
        Test.stopTest();

        System.assertEquals('Provisioned', [SELECT Id, IC_Status__c FROM User WHERE UserName =: 'testing27062022001@testorg.com'].IC_Status__c, 'Failed:  Users should be provisioned');        
    }
}