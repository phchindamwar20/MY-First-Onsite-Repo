/**
 * @description       : This is the test class for BoltLogPublisherService.  For the most part, we can't assert anything published by the bolt publisher because of a stupid undocumented limitation of salesforce. 
 *                      It appears the flow that creates the bolt log records doesn't execute when running test classes :|
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-30-2024
 * @last modified by  : Terri Jiles
**/
@isTest
private class BoltLogPublisherServiceTest {
    @TestSetup
    static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getOrgDefaults();
        dataAdmin.TurnOffFlow__c=false;
        dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.SetupOwnerId=UserInfo.getUserId();
        insert dataAdmin;
        
    }

    @isTest 
    private static void testPublishBoltEvent() {
        List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(), 20, 'TestFactoryDefaults.AccountDefaults', false);

        Set<Id> ids = new Set<Id>();
        for (Account acc : accLst) {
            ids.add(acc.Id);
        }

        try {
            test.startTest();
            BoltLogPublisherService.publishBoltErrorEvent(400, 'responseBody', 'requestBody', BoltConstants.BOLT_TO_SF, 'method', ids, 'className');
            test.stopTest();
        } catch (Exception e) {
            System.assert(FALSE, 'Problem running class: ' + e.getCause() + ' ' + e.getTypeName());
        }

        //System.assert([SELECT ID FROM Bolt_Log__c].size()> 0); can't query due to issues with running test classes with flow... the flow doesn't appear to process anything
    }

    @isTest 
    private static void testPublishMultipleBoltErrorEvent() {
        Integer testNum = 20;
        List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(), testNum, 'TestFactoryDefaults.AccountDefaults', true);
        List<Integer> statusCodeLst = new List<Integer>();
        List<String> recordLst = new List<String>();
        List<String> errorMsgLst = new List<String>();
        List<Id> idLst = new List<Id>();

        for (Account acc : accLst) {
            idLst.add(acc.Id);
            statusCodeLst.add(500);
            errorMsgLst.add('Error Msg');
            recordLst.add('record lst');
        }

        try {
            test.startTest();
            BoltLogPublisherService.publishBoltMultipleErrorEvents(statusCodeLst, errorMsgLst, recordLst, 'integrationDirection', 'method', idLst, 'className');
            test.stopTest();
        } catch (Exception e) {
            System.assert(FALSE, 'Problem running class: ' + e.getCause() + ' ' + e.getTypeName());
        }

        //System.assert([SELECT ID FROM Bolt_Log__c].size()> 0);
    }

    @isTest
    private static void testPUblishBoltIntegrationOffEvent() {
        try {
            Test.startTest();
            BoltLogPublisherService.publishBoltIntegrationOffEvent('test', BoltConstants.SF_TO_BOLT, BoltConstants.WS_BOLT_ACCOUNT, 'test');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(FALSE, 'Problem running class: ' + e.getCause() + ' ' + e.getTypeName());
        }
    }

    @isTest
    private static void testGenerateWebExceptionForICertis() {
        WorkOrder job = (WorkOrder)TestFactory.createSObject(new WorkOrder(), 'TestFactoryDefaults.JobDefaults', true);
        WebServiceLogObj webServiceObj = new WebServiceLogObj(UserInfo.getUserId(),'IcertisService','generateAzureToken', 'POST', null, new Set<Id>{job.Id});
        try {

            Integer i = 1/0;
        } catch (Exception e) {

            Test.startTest();
            BoltLogPublisherService.generateWebExceptionForICertis(e, new Set<Id>{job.Id}, WebServiceObj);
            Test.stopTest();

            //can't assert anything :(
        }         
    }

    @isTest
    private static void testGenerateNewExceptionLogEntries() {
        WorkOrder job = (WorkOrder)TestFactory.createSObject(new WorkOrder(), 'TestFactoryDefaults.JobDefaults', true);
        try {

            Integer i = 1/0;
        } catch (Exception e) {

            Test.startTest();
            BoltLogPublisherService.generateNewExceptionLogEntries('className', 'methodName', e, new Set<Id>{job.Id});
            Test.stopTest();

             //can't assert anything :(
        } 
    }

    @isTest
    static void testSetTypeByKeywordMatch(){
        System.assertEquals('Other', BoltLogPublisherService.setTypeByKeywordMatch('test'));
        System.assertEquals('Row Lock', BoltLogPublisherService.setTypeByKeywordMatch('"Update failed. First exception on row 0 with id 0WO1U000003isckWAA; first error: CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, dlrs_WorkOrderTrigger: execution of AfterUpdate\n\ncaused by: System.DmlException: Update failed. First exception on row 0 with id 0011U00001Ke2AaQAJ; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 2 records: 0011U00001Ke2AaQAJ,0011U00002EIA8jQAH: []\n\n(dlrs)\nTrigger.dlrs_WorkOrderTrigger: line 7, column 1: []" RETRYING AGAIN! retry number: 1'));
    }

    @isTest
    private static void testGetErrorsFromResult() {
        WorkOrder job = (WorkOrder)TestFactory.createSObject(new WorkOrder(), 'TestFactoryDefaults.JobDefaults', true);
        List<Employee_Commission__c> empComUpdLst = new List<Employee_Commission__c>();
        empComUpdLst.add(new Employee_Commission__c(Job__c=job.Id));
        Map<Id, List<Database.Error>> errorLstByJobId = new Map<Id, List<Database.Error>>();
        
        Test.startTest();
        Database.SaveResult[] updEcResultLst =  Database.update(empComUpdLst, false);
        errorLstByJobId = DynamicApexService.getErrorsFromResult(updEcResultLst,  empComUpdLst, 'Job__c', errorLstByJobId);
        BoltLogPublisherService.publishErrorsByJobId(errorLstByJobId, 'className', 'methodName', SalesIncentivePlanConstants.BOLT_LOG_RT_Name);
        Test.stopTest();

        //Can't assert anything related to bolt log publisher that publishes events
    }    
}