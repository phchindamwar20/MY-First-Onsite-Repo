/**
 * @description       : This is the test class for JobManager
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-12-2024
 * @last modified by  : Terri Jiles
**/
@isTest
private class JobManagerTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/Jobs';

    @TestSetup
    private static void makeData(){
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
        Bolt__c integrationBolt = new Bolt__c(SetupOwnerId = UserInfo.getUserId(), Is_Bolt_Integration_User__c=true);
        insert integrationBolt; //prevents trigger from firing integration back to Bolt, since the integration bolt user created the record
        Account acc = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.AccountDefaults', true);
        Account propertyNew = (Account)TestFactory.createSObject(new Account(ParentId=acc.Id), 'TestFactoryDefaults.PropertyDefaults', true);
        TestFactory.createUsers();
    }
    
    @isTest
    private static void testCreateJobDefault(){   
        //Get parent records
        Account acc = [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId() Limit 1];
        Account prop = [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId() Limit 1];   

        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "jobId": "f509b6ad-1628-4466-ad90-6b6119e0de8e", "jobName": "NS Integration test Rene 1", "salesforceAccountId": "'+acc.Id+'", "PropertyId": "'+prop.Id+'",  "incidentType": "Capital Improvements", "Status" : "In Queue"}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        JobManager.createJob();
        Test.stopTest();
        
        // Verify record was updated
        WorkOrder job = [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Lead_Source__c='Created by BOLT' AND Running_Margin__c=0 Limit 1];
        System.assert(acc != null);
        System.debug('~~~~ PropertyManagerTest::testCreateJobDefault responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('WorkOrderNumber'));
        System.assert(response.responseBody.toString().contains('Id'));
    }

    @isTest
    private static void testCreateJobNotDefault(){   
        //Get parent records
        Account acc = [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId() Limit 1];
        Account prop = [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId() Limit 1];   

        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "jobId": "f509b6ad-1628-4466-ad90-6b6119e0de8e", "jobName": "NS Integration test Rene 1", "salesforceAccountId": "'+acc.Id+'", "PropertyId": "'+prop.Id+'",  "incidentType": "Capital Improvements", "Status" : "In Queue", "LeadSource" : "Website"}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        JobManager.createJob();
        Test.stopTest();
        
        // Verify record was updated
        WorkOrder job = [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Lead_Source__c='Website' Limit 1];
        System.assert(acc != null);
        System.debug('~~~~ PropertyManagerTest::testCreateJobNotDefault responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('WorkOrderNumber'));
        System.assert(response.responseBody.toString().contains('Id'));
    }    

    @isTest
    private static void testUpdateJob(){
        //Get parent records
        Account acc = [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId() Limit 1];
        Account prop = [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId() Limit 1];  
        WorkOrder jobNew = (WorkOrder)TestFactory.createSObject(new WorkOrder(), 'TestFactoryDefaults.JobDefaults', true);
        
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "jobId": "f509b6ad-1628-4466-ad90-6b6119e0de8e", "jobName": "NS Integration test Rene 1", "salesforceAccountId": "'+acc.Id+'", "PropertyId": "'+prop.Id+'",  "incidentType": "Capital Improvements", "Status" : "In Queue", "Id": "'+jobNew.Id+'", "InitialMargin" : 35.0}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        JobManager.updateJob();
        //PropertyManager.POST;
        Test.stopTest();
        // Verify record was updated

        WorkOrder job = [SELECT Id FROM WorkOrder WHERE Id=:jobNew.Id AND AccountId=:acc.Id AND Property__c=:prop.Id AND Initial_Margin__c=35.0];
        System.assert(job != null);
        System.debug('~~~~ JobManagerTest::testUpdateJOb responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('Id'));
    } 
    
    @isTest
    private static void testCreateJobWithKTMOIDs(){
        //Get parent records
        Account acc = [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId() Limit 1];
        Account prop = [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId() Limit 1];   

        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "jobId": "f509b6ad-1628-4466-ad90-6b6119e0de8e", "ProjectManager": "ABCD12345679", "ProjectDirector":"ABCD12345680", "RMCMOM":"ABCD12345681", "jobName": "NS Integration test Rene 1", "salesforceAccountId": "'+acc.Id+'", "PropertyId": "'+prop.Id+'",  "incidentType": "Capital Improvements", "Status" : "In Queue", "LeadSource" : "Website"}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        JobManager.createJob();
        Test.stopTest();
        
        // Verify record was created
        WorkOrder job = [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Project_Manager__r.ADP_Associate_OID__c='ABCD12345679' AND Project_Director__r.ADP_Associate_OID__c='ABCD12345680' AND RM_CM_OM__r.ADP_Associate_OID__c='ABCD12345681' Limit 1];
        System.assert(acc != null);
        System.debug('~~~~ PropertyManagerTest::testCreateJobWithKTMOIDs responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('WorkOrderNumber'));
        System.assert(response.responseBody.toString().contains('Id'));
        
    }

    @isTest
    private static void testUpdateJobWithKTMOIDs(){
        //Get parent records
        Account acc = [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId() Limit 1];
        Account prop = [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId() Limit 1]; 
        WorkOrder jobNew = (WorkOrder)TestFactory.createSObject(new WorkOrder(), 'TestFactoryDefaults.JobDefaults', true);  

        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "Id": "'+jobNew.Id+'", "jobId": "f509b6ad-1628-4466-ad90-6b6119e0de8e", "ProjectManager": "ABCD12345679", "ProjectDirector":"ABCD12345680", "RMCMOM":"ABCD12345681", "jobName": "NS Integration test Rene 1", "salesforceAccountId": "'+acc.Id+'", "PropertyId": "'+prop.Id+'",  "incidentType": "Capital Improvements", "Status" : "In Queue", "LeadSource" : "Website"}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        JobManager.updateJob();
        Test.stopTest();
        
        // Verify record was updated
        WorkOrder job = [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Project_Manager__r.ADP_Associate_OID__c='ABCD12345679' AND Project_Director__r.ADP_Associate_OID__c='ABCD12345680' AND RM_CM_OM__r.ADP_Associate_OID__c='ABCD12345681' Limit 1];
        System.assert(job != null);
        System.debug('~~~~ PropertyManagerTest::testUpdateJobWithKTMOIDs responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('WorkOrderNumber'));
        System.assert(response.responseBody.toString().contains('Id'));
        
    }    
}