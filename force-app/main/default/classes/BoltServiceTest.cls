/**
 * @description       : This is the Test class for BoltService
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-24-2024
 * @last modified by  : Terri Jiles
**/
@isTest
private without sharing class BoltServiceTest {
    @TestSetup
    static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=true;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
            dataAdmin.SetupOwnerId = UserInfo.getUserId();
            insert dataAdmin;  
        }
        else {
            update dataAdmin;
        }          
    }

    @isTest
    private static void testIsChangeInRecord() {

        String integrationDirection = BoltConstants.SF_TO_BOLT;
        String methodName = BoltConstants.WS_BOLT_JOB;
        List<Bolt_Integration_Fields__mdt> bifLst = BoltService.getBoltIntegrationFields(integrationDirection, methodName, true);
        //BoltService.objectApiName='WorkOrder';
        //<String, String> fieldNameByRelationshipNameMap = BoltService.getFieldNameByRelationshipName();

        Account accOld = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.AccountDefaults', true);
        Account accNew = (Account)TestFactory.createSObject(new Account(Name='Test Test'), 'TestFactoryDefaults.AccountDefaults', true);

        Account property = (Account)TestFactory.createSObject(new Account(ParentId=accNew.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId()));
        Contact adjusterOld = (Contact)TestFactory.createSObject(new Contact(AccountId=accNew.Id), 'TestFactoryDefaults.ContactDefaults', true);
        Contact adjusterNew = (Contact)TestFactory.createSObject(new Contact(AccountId=accNew.Id, LastName='Adjuster', FirstName='Contact', Email='adjuster@test.com'), 'TestFactoryDefaults.ContactDefaults', true);

        WorkOrder oldJob =  (WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=accOld.Id, Property__c=property.Id, Insurance_Adjuster_Contactx__c=adjusterOld.Id), 'TestFactoryDefaults.JobDefaults', true);
        Set<Id> ids = new Set<Id>();
        ids.add(oldJob.Id);
        List<WorkOrder> oldJobLst = Database.query(BoltService.buildSqol(bifLst, ids));

        //test no change
        System.assertEquals(false, BoltService.isChangeInRecord(oldJob, oldJob, integrationDirection, methodName), 'Failed:  Expected No change');

        //test normal change
        WorkOrder normalJob =  new WorkOrder(AccountId=accNew.Id, Id=oldJob.Id);
        update normalJob;
        List<WorkOrder> normalJobLst = Database.query(BoltService.buildSqol(bifLst, ids));
        System.assertEquals(true, BoltService.isChangeInRecord(oldJobLst[0], normalJobLst[0], integrationDirection, methodName), 'Failed:  Expected a change in normal field');


        //test relationship
        WorkOrder newJob = new WorkOrder(Id=oldJob.Id, Insurance_Adjuster_Contactx__c=adjusterNew.Id);
        update newJob;
        List<WorkOrder> newJobLst = Database.query(BoltService.buildSqol(bifLst, ids));
        System.assertEquals(true, BoltService.isChangeInRecord(oldJobLst[0], newJobLst[0], integrationDirection, methodName), 'Failed:  Expected a change in relationship field');
    }

    @isTest
    static void testTransformSalesforceBody(){
        String integrationDirection = BoltConstants.SF_TO_BOLT;
        String methodName = BoltConstants.WS_BOLT_ACCOUNT;
        List<Account> accLst = new List<Account>();
        accLst.add((Account)TestFactory.createSObject(new Account(Name='Test'), 'TestFactoryDefaults.AccountDefaults'));
        insert accLst;

        Test.startTest();
        List<Map<String, Object>> boltLst = BoltService.transformSalesforceBody(new Set<Id>{accLst[0].Id}, integrationDirection, methodName);
        Test.stopTest();
        System.assertEquals('Test', (String)boltLst[0].get('Name'));
    }

    @isTest
    private static void testTransformBoltResponse() {
        String integrationDirection = BoltConstants.BOLT_TO_SF;
        String methodName = BoltConstants.WS_BOLT_ACCOUNT_CREATE;
        String requestBody =   '{\n'+
            '"name": "TestAccount"\n'+
        '}';    

        try {
            Test.startTest();
            Account acc = (Account)BoltService.transformBoltResponse(integrationDirection, methodName, requestBody);
            Test.stopTest();
            System.assertEquals('TestAccount', acc.Name, 'fail: record not found');
        } catch (Exception e) {
            System.assert(false, 'failed due to ' + e.getMessage());
        }
    }

    @isTest
    private static void testGetObjectApiName() {
        System.assertEquals('Account', BoltService.getObjectApiName(BoltConstants.BOLT_TO_SF, BoltConstants.WS_BOLT_ACCOUNT_CREATE, false));

        System.assertEquals('Account', BoltService.getObjectApiName(BoltConstants.SF_TO_BOLT, BoltConstants.WS_BOLT_PROPERTY, true));
    }
}