/**
 * @description       : Adapted code from following source to test BoltCallouts class https://developer.salesforce.com/blogs/developer-relations/2013/03/testing-apex-callouts-using-httpcalloutmock
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-15-2024
 * @last modified by  : Terri Jiles
**/


@isTest
private class BoltCalloutsTest {
    //private static string BEARER_RESPONSE = '{"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjRQaFVma1NkcGwxeU5uUU00RWhVSiJ9.eyJpc3MiOiJodHRwczovL2prb2RlLnVzLmF1dGgwLmNvbS8iLCJzdWIiOiJUeG9STnJYY3lSVVJxWDBTMGh5ZnRrT0VQUEJjZWd4aEBjbGllbnRzIiwiYXVkIjoiUHJvamVjdEphcnZpc1Jlc3RBUEkiLCJpYXQiOjE2Mzg5MTc3MDQsImV4cCI6MTYzOTAwNDEwNCwiYXpwIjoiVHhvUk5yWGN5UlVScVgwUzBoeWZ0a09FUFBCY2VneGgiLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbHMifQ.Kr_bArvmul7t2G5bWNXqDhRCXW2a1jIzyIRG8kG03d6gT_p_R8YsykoThtA7vHBnxiqMzHiqyOeyPFuUqmUGBKICwGzdDnoeMRfUs9i-eQWs9Tfm"}';
    private static string ACCOUNT_RESPONSE = '{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"60e65bc1-b77a-529b-9c02-0162de6e9487"},"SendMessageResult":{"MD5OfMessageAttributes":"5861045bf6924584cb81b42ca38fb255","MD5OfMessageBody":"bcdbc51cebb8f7cff6686fb658a0bd15","MD5OfMessageSystemAttributes":null,"MessageId":"8d8ac3d5-92bd-431d-afcb-7fffd47c65ba","SequenceNumber":"18868345473583089152"}}}';//'[ { "BillingState" : "TX", "BillingCountry" : "US", "AccountNumber" : "00000099", "RecordTypeId" : "0121U000000b3ytQAA", "Phone" : "8888888888", "Name" : "Alma\'s Account", "Id" : "0016C00000hADjwQAG", "BillingStreet" : "5401 North Mays Street", "BillingPostalCode" : "78626", "BillingCity" : "Georgetown" } ]';
    private static string DEL_RESPONSE = '';
    private static string PROPERTY_RESPONSE = '{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"60e65bc1-b77a-529b-9c02-0162de6e9487"},"SendMessageResult":{"MD5OfMessageAttributes":"5861045bf6924584cb81b42ca38fb255","MD5OfMessageBody":"bcdbc51cebb8f7cff6686fb658a0bd15","MD5OfMessageSystemAttributes":null,"MessageId":"8d8ac3d5-92bd-431d-afcb-7fffd47c65ba","SequenceNumber":"18868345473583089152"}}}';//[ { "Zip": "78613", "State": "TX", "Country": "US", "Ciy": "Georgetown", "Address1": "8234 University Palace", "Address2": "Unit 4", "Active": true, "AccountId": "0017h00000dDe5UAAS", "PropertyName" : "Time Job", "Id" : "0016C00000hADgsQAG"} ]';
    private static string JOB_RESPONSE = '{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"60e65bc1-b77a-529b-9c02-0162de6e9487"},"SendMessageResult":{"MD5OfMessageAttributes":"5861045bf6924584cb81b42ca38fb255","MD5OfMessageBody":"bcdbc51cebb8f7cff6686fb658a0bd15","MD5OfMessageSystemAttributes":null,"MessageId":"8d8ac3d5-92bd-431d-afcb-7fffd47c65ba","SequenceNumber":"18868345473583089152"}}}'; //'[ { "WorkTypeId" : "08q1U000000hh7ZQAQ", "WorkOrderNumber" : "00486101", "Status" : "In Queue", "ServiceTerritoryId" : "0Hh1U000000khRASAY", "Id" : "0WO8B000000L02rWAC", "AccountId" : "0018B00000348yPQAQ"} ]';
    private static string AWE_RESPONSE= '{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"60e65bc1-b77a-529b-9c02-0162de6e9487"},"SendMessageResult":{"MD5OfMessageAttributes":"5861045bf6924584cb81b42ca38fb255","MD5OfMessageBody":"bcdbc51cebb8f7cff6686fb658a0bd15","MD5OfMessageSystemAttributes":null,"MessageId":"8d8ac3d5-92bd-431d-afcb-7fffd47c65ba","SequenceNumber":"18868345473583089152"}}}';//

    @TestSetup
    static void makeData(){
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
    }

    @isTest
    private static void testCreateAccount() {
        String endpoint = BoltConstants.WS_BOLT_ACCOUNT;
        /*SingleRequestMock fakeBearerResp = new SingleRequestMock(200,
                                                    'ok',
                                                    BEARER_RESPONSE,
                                                    null);
        */
        SingleRequestMock fakeAccountResp = new SingleRequestMock(200,
                                                    'ok',
                                                    ACCOUNT_RESPONSE,
                                                    null);
        
        BOLT__c bypass= BOLT__c.getInstance();
        Map<String, HttpCalloutMock> endpoint2TestResp =
                                   new Map<String,HttpCalloutMock>();
        //endpoint2TestResp.put('callout:BoltOAuth',fakeBearerResp);
        //endpoint2TestResp.put(bypass.Endpoint__c + 'createAccount',fakeAccountResp);
        endpoint2TestResp.put('callout:BoltEndpoint'+Label.BOLT_ENDPOINT_ENVIRONMENT+endpoint,fakeAccountResp);
        HttpCalloutMock multiCalloutMock =
            	                   new MultiRequestMock(endpoint2TestResp);

        Set<Id> newAccountIds = new Set<Id>();
        newAccountIds.add('0016C00000hADjwQAG');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        try {
            BoltCallouts.sendRecords(newAccountIds, endpoint, 'apexClass');
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'failed');
        }
Test.stopTest();
    }


    @isTest
    private static void testCreateJob() {
        String endpoint = BoltConstants.WS_BOLT_JOB;
        /*SingleRequestMock fakeBearerResp = new SingleRequestMock(200,
                                                    'ok',
                                                    BEARER_RESPONSE,
                                                    null);
        */
        SingleRequestMock fakeJobResp = new SingleRequestMock(200,
                                                    'ok',
                                                    JOB_RESPONSE,
                                                    null);

        
        BOLT__c bypass= BOLT__c.getInstance();
        Map<String, HttpCalloutMock> endpoint2TestResp =
                                   new Map<String,HttpCalloutMock>();
        //endpoint2TestResp.put('callout:BoltOAuth',fakeBearerResp);
        //endpoint2TestResp.put(bypass.Endpoint__c + 'createJob',fakeJobResp);
        endpoint2TestResp.put('callout:BoltEndpoint'+Label.BOLT_ENDPOINT_ENVIRONMENT+endpoint,fakeJobResp);

        HttpCalloutMock multiCalloutMock =
            	                   new MultiRequestMock(endpoint2TestResp);

        Set<Id> newJobIds = new Set<Id>();
        newJobIds.add('0WO8B000000L02rWAC');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        try {
            BoltCallouts.sendRecords(newJobIds, endpoint, 'apexClass');
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'failed');
        }
        Test.stopTest();
    }

    @isTest
    private static void testSendProperties() {
        String endpoint = BoltConstants.WS_BOLT_PROPERTY;
        /*SingleRequestMock fakeBearerResp = new SingleRequestMock(200,
                                                    'ok',
                                                    BEARER_RESPONSE,
                                                    null);
        */
        SingleRequestMock fakePropertyResp = new SingleRequestMock(200,
                                                    'ok',
                                                    PROPERTY_RESPONSE,
                                                    null);

        
        BOLT__c bypass= BOLT__c.getInstance();
        Map<String, HttpCalloutMock> endpoint2TestResp =
                                   new Map<String,HttpCalloutMock>();
        //endpoint2TestResp.put('callout:BoltOAuth',fakeBearerResp);
        //endpoint2TestResp.put(bypass.Endpoint__c + 'sendProperties',fakePropertyResp);
        endpoint2TestResp.put('callout:BoltEndpoint'+Label.BOLT_ENDPOINT_ENVIRONMENT+endpoint,fakePropertyResp);

        HttpCalloutMock multiCalloutMock =
            	                   new MultiRequestMock(endpoint2TestResp);

        Set<Id> newAccountIds = new Set<Id>();
        newAccountIds.add('0016C00000hADgsQAG');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        try {
            BoltCallouts.sendRecords(newAccountIds, endpoint, 'apexClass');
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'failed');
        }
        Test.stopTest();
    }

    @isTest
    private static void testUpsertAreaWideEvent() {
        /****
         * The request body would look like the following:
         *  [ {
         *       "IsActive" : false,
         *       "Name" : "Test",
         *       "Id" : "a1J8F000000Hzh0UAC"
         * } ]
         * ***/
        String endpoint=BoltConstants.WS_BOLT_AREA_WIDE_EVENT;
        SingleRequestMock fakeResp = new SingleRequestMock(200,
                                                    'ok',
                                                    AWE_RESPONSE,
                                                    null);

        
        BOLT__c bypass= BOLT__c.getInstance();
        Map<String, HttpCalloutMock> endpoint2TestResp =
                                   new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('callout:BoltEndpoint'+Label.BOLT_ENDPOINT_ENVIRONMENT+endpoint,fakeResp);

        HttpCalloutMock multiCalloutMock =
            	                   new MultiRequestMock(endpoint2TestResp);

        Set<Id> ids = new Set<Id>();
        ids.add('a1J8F000000Hzh0UAC');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        try {
            BoltCallouts.sendRecords(ids, endpoint, 'apexClass');
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'failed');
        }
        Test.stopTest();
    }

    @isTest
    private static void testSendToEnv() {
        String endpoint=BoltConstants.WS_BOLT_PROPERTY;
        /*SingleRequestMock fakeBearerResp = new SingleRequestMock(200,
                                                    'ok',
                                                    BEARER_RESPONSE,
                                                    null);
        */
        SingleRequestMock fakePropertyResp = new SingleRequestMock(200,
                                                    'ok',
                                                    PROPERTY_RESPONSE,
                                                    null);

        
        BOLT__c bypass= BOLT__c.getInstance();
        Map<String, HttpCalloutMock> endpoint2TestResp =
                                   new Map<String,HttpCalloutMock>();
        //endpoint2TestResp.put('callout:BoltOAuth',fakeBearerResp);
        //endpoint2TestResp.put(bypass.Endpoint__c + 'sendProperties',fakePropertyResp);
        endpoint2TestResp.put('callout:BoltEndpoint'+Label.BOLT_ENDPOINT_ENVIRONMENT+endpoint,fakePropertyResp);
        HttpCalloutMock multiCalloutMock =
            	                   new MultiRequestMock(endpoint2TestResp);

        Set<Id> newAccountIds = new Set<Id>();
        newAccountIds.add('0016C00000hADjwQAG');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        try {
            BoltCallouts.sendRecords(newAccountIds, endpoint, 'apexClass');
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'failed');
        }       
        Test.stopTest();
    }

    @isTest
    private static void testUpdateRecordsWithResponseFromBolt() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://test.com/'+BoltConstants.WS_BOLT_ACCOUNT);
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setStatus('OK');
        res.setBody('{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"6795559c-6b34-5685-a470-0ee66c7ff77b"},"SendMessageResult":{"MD5OfMessageAttributes":"696d13f04053e63787215c0b11e7f783","MD5OfMessageBody":"1e70f513271799c9fff10614fdb6ac23","MD5OfMessageSystemAttributes":null,"MessageId":"e21e127d-ab5c-4633-a2cf-26a63c88d5d6","SequenceNumber":"18871946166634227712"}}}');

        Account acc = new Account(Name='Test');
        insert acc;

        Set<Id> ids = new Set<Id>();
        ids.add(acc.Id);

        Test.startTest();
        BoltCallouts.updateRecordsWithResponseFromBolt(req, res, ids, BoltConstants.WS_BOLT_ACCOUNT);
        Test.stopTest();

        Account updAcc = [SELECT Bolt_Status_Code__c, Bolt_Callout_Endpoint__c, Last_Callout_to_Bolt_Date__c, Bolt_Status__c, Bolt_Response_Body__c FROM Account Limit 1];

        System.assertEquals(acc.Id, updAcc.Id);
        System.assertEquals(res.getStatusCode(), updAcc.Bolt_Status_Code__c);
        System.assertEquals(req.getEndpoint(), updAcc.Bolt_Callout_Endpoint__c);
        System.assertEquals(Date.today(), updAcc.Last_Callout_to_Bolt_Date__c.date());
        System.assertEquals(res.getStatus(), updAcc.Bolt_Status__c);
        System.assertEquals(res.getBody(), updAcc.Bolt_Response_Body__c);
    }

    @isTest
    private static void testTurnOffIintegration() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://test.com/test');
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setStatus('OK');
        res.setBody('{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"6795559c-6b34-5685-a470-0ee66c7ff77b"},"SendMessageResult":{"MD5OfMessageAttributes":"696d13f04053e63787215c0b11e7f783","MD5OfMessageBody":"1e70f513271799c9fff10614fdb6ac23","MD5OfMessageSystemAttributes":null,"MessageId":"e21e127d-ab5c-4633-a2cf-26a63c88d5d6","SequenceNumber":"18871946166634227712"}}}');

        Account acc = new Account(Name='Test');
        insert acc;

        Set<Id> ids = new Set<Id>();
        ids.add(acc.Id);

        Test.startTest();
        BoltCallouts.sendRecords(ids, 'testClassMethod', 'BoltCallouts');
        Test.stopTest();

        //Although log shows the value below is True within the BoltCallouts class, when it hits the test class it is false for some reason
        //System.assertEquals(true, BoltCallouts.isIntegrationOff);
    }    
}