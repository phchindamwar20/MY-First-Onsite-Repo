/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-20-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private  class WorkTypeManagerTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/WorkTypes';

    @TestSetup
    static void makeData(){
        Bolt__c integrationBolt = new Bolt__c(SetupOwnerId = UserInfo.getUserId(), Is_Bolt_Integration_User__c=true);
        insert integrationBolt; //prevents trigger from firing integration back to Bolt, since the integration bolt user created the record        
        Map<String, WorkType> workTypeByNameMap  = SandboxTestData.createWorkTypes();
        insert workTypeByNameMap.values();
    }
    @isTest
    private static void testGetWorkTypes() {        
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        List<WorkType> workTypeLst = WorkTypeManager.getWorkTypes();
        //PropertyManager.POST;
        Test.stopTest();
        // Verify records obtained
        System.assert(workTypeLst.size() > 0);
    }     
}