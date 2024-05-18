/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-14-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class PropertyManagerTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/Property';

    @TestSetup
    static void makeData(){
        Bolt__c integrationBolt = new Bolt__c(SetupOwnerId = UserInfo.getUserId(), Is_Bolt_Integration_User__c=true);
        insert integrationBolt; //prevents trigger from firing integration back to Bolt, since the integration bolt user created the record
        Account acc = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.AccountDefaults', true);

    }
    
    @isTest
    private static void testCreateProperty(){
        Account acc = [SELECT Id FROM Account Limit 1];
        
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "Zip": "78613", "State": "TX", "Country": "US", "City": "Georgetown", "Address1": "8234 University Palace", "Address2": "Unit 4", "Active": true, "AccountId": "'+acc.Id+'", "PropertyName" : "Test", "AccountName" : "Time Job", "RecordTypeId" : "'+Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId()+'"}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        PropertyManager.createProperty();
        //PropertyManager.POST;
        Test.stopTest();
        // Verify record was updated

        Account propertyAcc = [SELECT Id, Name FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Property').getRecordTypeId()];
        System.assert(propertyAcc != null);
        System.debug('~~~~ PropertyManagerTest::testCreateProperty responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('PropertyNumber'));
        System.assert(response.responseBody.toString().contains('Id'));
    }

    @isTest
    private static void testUpdateProperty(){
        Account acc = [SELECT Id FROM Account Limit 1];
        Account propertyNew = (Account)TestFactory.createSObject(new Account(ParentId=acc.Id), 'TestFactoryDefaults.PropertyDefaults', true);
        
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "Zip": "78613", "State": "TX", "Country": "US", "City": "Georgetown", "Address1": "8234 University Palace", "Address2": "Unit 4", "Active": true, "AccountId": "'+acc.Id+'", "AccountName" : "Time Job", "RecordTypeId" : "'+Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId()+'", "Id" : "'+propertyNew.Id+'"}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        PropertyManager.updateProperty();
        //PropertyManager.POST;
        Test.stopTest();
        // Verify record was updated

        Account propertyAcc = [SELECT Id, Name FROM Account WHERE ShippingCity='Georgetown' AND RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Property').getRecordTypeId() AND Id=:propertyNew.Id];
        System.assert(propertyAcc != null);
        System.debug('~~~~ PropertyManagerTest::testUpdateProperty responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('PropertyNumber'));
        System.assert(response.responseBody.toString().contains('Id'));
    }    

}