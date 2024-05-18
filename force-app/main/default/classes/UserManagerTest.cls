/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-25-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private with sharing class UserManagerTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/User';

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
        User testUser = new User(ADP_Associate_OID__c='83747473756', Alias='tbolt', CountryCode='US', Department='Test', Email='Test@test.com.BoltUpdate', EmailEncodingKey='UTF-8', FederationIdentifier='test@test.com.BoltUpdate', FirstName='Test', IsActive=true, LanguageLocaleKey='en_US', LastName='test', LocaleSidKey='en_US', Location__c='US - CO - Denver', MobilePhone='888-888-8888', Phone='888-888-8888', ProfileId='00e1U000001wM2QQAU', TimezoneSidKey='America/New_York', Title='Test', Username='test@test.com.BoltUpdate');
        insert testUser;
    }

    @isTest
    private static void testInsertUser() {
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        String requestBody =             
            '{\n' +
            '    "AssociateOID":"123743784756",\n' + 
            '    "Alias":"tmix",\n'+
            '    "BoltKey": "143234dfsd576",\n'+
            '    "Subsidiary": "CompanyName",\n'+
            '    "Country" : "US",\n'+
            '    "Department" : "Test",\n'+
            '    "Email" : "test@test.com.BoltTest",\n'+
            '    "EmailEncoding" : "UTF-8",\n'+
            '    "SAMLFederationIdentifier" : "test@test.com.BoltTest",\n'+
            '    "PreferredName" : "Test",\n'+
            '    "Active" : true,\n'+
            '    "Language" : "en_US",\n'+
            '    "LastName" : "Test",\n'+
            '    "Locale" : "en_US",\n'+
            '    "Location": "US - CO - Denver",\n'+
            '    "MobilePhone" : "999-888-8888",\n'+
            '    "PhoneNumber" : "999-888-8888",\n'+
            '    "ProfileId" : "00e1U000001wM2QQAU",\n'+
            '    "TimeZone" : "America/New_York",\n'+
            '    "Title" : "Test",\n'+
            '    "Username" : "test@test.com.BoltTest"\n'+
            '}';
        System.debug('~~~~ UserManagerTest::testInsertUser: requestBody - ' + requestBody);
        request.requestBody = Blob.valueOf(
            requestBody
        );
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        Test.startTest();
        UserManager.createUser();
        Test.stopTest();

        User userRec = [SELECT Id FROM User WHERE Username='test@test.com.BoltTest'];
        System.assert(userRec != null);
        System.debug('~~~~ UserManagerTest::testUser responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('AssociateOID'));
        System.assert(response.responseBody.toString().contains('Id'));
    }

    @isTest
    private static void testInsertDefaulttUser() {
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        String requestBody =             
            '{\n' +
            '    "AssociateOID":"123743784756",\n' + 
            '    "Alias":"tmix",\n'+
            '    "BoltKey": "143234dfsd576",\n'+
            '    "Subsidiary": "CompanyName",\n'+
            '    "Department" : "Test",\n'+
            '    "Email" : "test@test.com.BoltTest",\n'+
            '    "SAMLFederationIdentifier" : "test@test.com.BoltTest",\n'+
            '    "PreferredName" : "Test",\n'+
            '    "LastName" : "Test",\n'+
            '    "Location": "US - CO - Denver",\n'+
            '    "MobilePhone" : "999-888-8888",\n'+
            '    "PhoneNumber" : "999-888-8888",\n'+
            '    "Title" : "Test",\n'+
            '    "Username" : "test@test.com.BoltTest"\n'+
            '}';
        System.debug('~~~~ UserManagerTest::testInsertUser: requestBody - ' + requestBody);
        request.requestBody = Blob.valueOf(
            requestBody
        );
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        Test.startTest();
        UserManager.createUser();
        Test.stopTest();

        User userRec = [SELECT Id, CountryCode, EmailEncodingKey, IsActive, LanguageLocaleKey, LocaleSidKey, ProfileId, TimezoneSidKey FROM User WHERE Username='test@test.com.BoltTest' AND TimezoneSidKey='America/New_York' AND Profile.Name='Chatter Free User'];
        System.debug('~~~~~ UserManager::testInsertDefaultUser: userRec - ' + userRec);
        System.assert(userRec != null);
        System.debug('~~~~ UserManagerTest::testUser responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('AssociateOID'));
        System.assert(response.responseBody.toString().contains('Id'));
    }    

    @isTest
    private static void testUpdateUser() {
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        User origUser = [SELECT Id, ADP_Associate_OID__c FROM User WHERE ADP_Associate_OID__c=:'83747473756' Limit 1];
        String requestBody =             
            '{\n' +
            '    "AssociateOID":"'+origUser.ADP_Associate_OID__c+'",\n' + 
            '    "Active" : false\n'+
            '}';
        System.debug('~~~~ UserManagerTest::testInsertUser: requestBody - ' + requestBody);
        request.requestBody = Blob.valueOf(
            requestBody
        );
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        Test.startTest();
        UserManager.updateUser();
        Test.stopTest();

        User userRec = [SELECT Id FROM User WHERE ADP_Associate_OID__c=:origUser.ADP_Associate_OID__c AND IsActive=false];
        System.assert(userRec != null);
        System.debug('~~~~ UserManagerTest::testUser responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('AssociateOID'));
        System.assert(response.responseBody.toString().contains('Id'));
    }    
}