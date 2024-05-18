/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-15-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class JobListManagerTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/JobList';

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
        Bolt__c integrationBolt = new Bolt__c(SetupOwnerId = UserInfo.getUserId(), Is_Bolt_Integration_User__c=true);
        insert integrationBolt; //prevents trigger from firing integration back to Bolt, since the integration bolt user created the record
        TestFactory.createJobTestData(200); 
    }
    
    @isTest
    private static void testUpdateJobList(){
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');

        Integer n = 1;
        String bodyRequest = '[';
        for (WorkOrder job : [SELECT Id FROM WorkOrder]) {
            bodyRequest +='{';
            bodyRequest +='    "Id": "' + job.Id + '"/,';
            bodyRequest +='     "ResponseBody": "Success"/,';
            bodyRequest +='     "ResponseDate": "' + Datetime.Now() + '"/,';
            bodyRequest +='    "StatusCode" : 200';
            bodyRequest +='}';          
            if (n < 200) {
                bodyRequest +=',';
            }
            n++;
        }
        bodyRequest+=']';

        request.requestBody = Blob.valueOf(bodyRequest);
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        JobListManager.updateJobList();
        Test.stopTest();
        
        // Verify record was updated
        List<WorkOrder> jobList = [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Bolt_Response_Status_Code__c=200 Limit 200];

        System.debug('~~~~ JobListManagerTest::testUpdateJobList responseBody - ' + response.responseBody.toString());
    }
}