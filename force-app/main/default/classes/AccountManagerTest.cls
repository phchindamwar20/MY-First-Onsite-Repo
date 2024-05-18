/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-26-2023
 * @last modified by  : Terri Jiles
**/
@isTest
private class AccountManagerTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/Accounts';

    @TestSetup
    static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=false;
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
    }
    
    @isTest
    private static void testCreateAccount(){        
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "name": "This Test Account", "driveDown" : "No", "drivePlanPlace" : "No", "contractType" : "MSA Only", "email" : "test@test.com", "phone" : "888888888", "billingZip" : "123456", "billingCountry" : "US", "billingState" : "TX", "billingCity" : "Round Rock", "billingAddress" : "123 Cool St.", "billingPhone" : "8888888888", "billingEmail" : "test@test.com", "billTo" : "Bill To Email", "RecordTypeId" : "'+Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId()+'"}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        AccountManager.createAccount();
        Test.stopTest();
        
        // Verify record was updated
        Account acc = [SELECT Id, Name FROM Account WHERE Name='This Test Account' AND RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId()];
        System.assert(acc != null);
        System.debug('~~~~ PropertyManagerTest::testCreateAccount responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('AccountNumber'));
        System.assert(response.responseBody.toString().contains('Id'));
    }

    @isTest
    private static void testUpdateAccount(){
        Account accNew = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.AccountDefaults', true);
        
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "name": "This Test Account", "driveDown" : "No", "drivePlanPlace" : "No", "contractType" : "MSA Only", "email" : "test@test.com", "phone" : "888888888", "billingZip" : "123456", "billingCountry" : "US", "billingState" : "TX", "billingCity" : "Round Rock", "billingAddress" : "123 Cool St.", "billingPhone" : "8888888888", "billingEmail" : "test@test.com", "billTo" : "Bill To Email", "RecordTypeId" : "'+Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId()+'" , "Id" : "'+accNew.Id+'"}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        AccountManager.updateAccount();
        //PropertyManager.POST;
        Test.stopTest();
        // Verify record was updated
        Account accUpd = [SELECT Id, Name FROM Account WHERE Name='This Test Account' AND RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId() AND Id=:accNew.Id];
        System.assert(accUpd != null);
        System.debug('~~~~ AccountManagerTest::testUpdateAccount responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);

        System.assert(response.responseBody.toString().contains('Id'));
    }    

    @isTest
    private static void testGetAccount() {
        Account accNew = (Account)TestFactory.createSObject(new Account(Name='AccountTest'), 'TestFactoryDefaults.AccountDefaults', true);
        
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI + '/' + accNew.Name;
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        Account thisAcc = AccountManager.getAccount();
        //PropertyManager.POST;
        Test.stopTest();
        // Verify record was updated

        System.assertEquals(accNew.Id, thisAcc.Id);
    }

}