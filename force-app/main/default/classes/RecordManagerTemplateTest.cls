/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-21-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public without sharing class RecordManagerTemplateTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/Test';

    @isTest
    static void testTurnOffIntegration() {
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "name": "This is a Test"}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        TestManager.createRecordTest();
        Test.stopTest();
        
        System.debug('~~~~ RecordManagerTemplateTest::testTurnOffIntegration responseBody - ' + response.responseBody.toString());
        System.assertEquals(503, response.statusCode);
        System.assert(response.responseBody.toString().contains(System.Label.BOLT_INTEGRATION_OFF));
    }

    @isTest
    static void testTurnOffIntegrationList() {
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{ "name": "This is a Test"}]');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        TestManager.updateRecordListTest();
        Test.stopTest();
        
        System.debug('~~~~ RecordManagerTemplateTest::testTurnOffIntegration responseBody - ' + response.responseBody.toString());
        System.assertEquals(503, response.statusCode);
        System.assert(response.responseBody.toString().contains(System.Label.BOLT_INTEGRATION_OFF));
    }    
}