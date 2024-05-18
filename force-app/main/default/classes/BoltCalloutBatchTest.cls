/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-31-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public without sharing class BoltCalloutBatchTest {
    //private static string BEARER_RESPONSE = '{"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjRQaFVma1NkcGwxeU5uUU00RWhVSiJ9.eyJpc3MiOiJodHRwczovL2prb2RlLnVzLmF1dGgwLmNvbS8iLCJzdWIiOiJUeG9STnJYY3lSVVJxWDBTMGh5ZnRrT0VQUEJjZWd4aEBjbGllbnRzIiwiYXVkIjoiUHJvamVjdEphcnZpc1Jlc3RBUEkiLCJpYXQiOjE2Mzg5MTc3MDQsImV4cCI6MTYzOTAwNDEwNCwiYXpwIjoiVHhvUk5yWGN5UlVScVgwUzBoeWZ0a09FUFBCY2VneGgiLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbHMifQ.Kr_bArvmul7t2G5bWNXqDhRCXW2a1jIzyIRG8kG03d6gT_p_R8YsykoThtA7vHBnxiqMzHiqyOeyPFuUqmUGBKICwGzdDnoeMRfUs9i-eQWs9Tfm"}';
    private static string ACCOUNT_RESPONSE = '{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"60e65bc1-b77a-529b-9c02-0162de6e9487"},"SendMessageResult":{"MD5OfMessageAttributes":"5861045bf6924584cb81b42ca38fb255","MD5OfMessageBody":"bcdbc51cebb8f7cff6686fb658a0bd15","MD5OfMessageSystemAttributes":null,"MessageId":"8d8ac3d5-92bd-431d-afcb-7fffd47c65ba","SequenceNumber":"18868345473583089152"}}}';//'[ { "BillingState" : "TX", "BillingCountry" : "US", "AccountNumber" : "00000099", "RecordTypeId" : "0121U000000b3ytQAA", "Phone" : "8888888888", "Name" : "Alma\'s Account", "Id" : "0016C00000hADjwQAG", "BillingStreet" : "5401 North Mays Street", "BillingPostalCode" : "78626", "BillingCity" : "Georgetown" } ]';
    private static string DEL_RESPONSE = '';
    private static string PROPERTY_RESPONSE = '{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"60e65bc1-b77a-529b-9c02-0162de6e9487"},"SendMessageResult":{"MD5OfMessageAttributes":"5861045bf6924584cb81b42ca38fb255","MD5OfMessageBody":"bcdbc51cebb8f7cff6686fb658a0bd15","MD5OfMessageSystemAttributes":null,"MessageId":"8d8ac3d5-92bd-431d-afcb-7fffd47c65ba","SequenceNumber":"18868345473583089152"}}}';//[ { "Zip": "78613", "State": "TX", "Country": "US", "Ciy": "Georgetown", "Address1": "8234 University Palace", "Address2": "Unit 4", "Active": true, "AccountId": "0017h00000dDe5UAAS", "PropertyName" : "Time Job", "Id" : "0016C00000hADgsQAG"} ]';
    private static string JOB_RESPONSE = '{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"60e65bc1-b77a-529b-9c02-0162de6e9487"},"SendMessageResult":{"MD5OfMessageAttributes":"5861045bf6924584cb81b42ca38fb255","MD5OfMessageBody":"bcdbc51cebb8f7cff6686fb658a0bd15","MD5OfMessageSystemAttributes":null,"MessageId":"8d8ac3d5-92bd-431d-afcb-7fffd47c65ba","SequenceNumber":"18868345473583089152"}}}'; //'[ { "WorkTypeId" : "08q1U000000hh7ZQAQ", "WorkOrderNumber" : "00486101", "Status" : "In Queue", "ServiceTerritoryId" : "0Hh1U000000khRASAY", "Id" : "0WO8B000000L02rWAC", "AccountId" : "0018B00000348yPQAQ"} ]';
    private static string AWE_RESPONSE= '{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"60e65bc1-b77a-529b-9c02-0162de6e9487"},"SendMessageResult":{"MD5OfMessageAttributes":"5861045bf6924584cb81b42ca38fb255","MD5OfMessageBody":"bcdbc51cebb8f7cff6686fb658a0bd15","MD5OfMessageSystemAttributes":null,"MessageId":"8d8ac3d5-92bd-431d-afcb-7fffd47c65ba","SequenceNumber":"18868345473583089152"}}}';//

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
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        try {
            String query = 'SELECT Id, ParentId FROM Account WHERE RecordType.DeveloperName = \'' + BoltConstants.RT_ACC_ACCOUNT + '\' ORDER BY ParentId';
            BoltCalloutBatch accountCallout = new BoltCalloutBatch(BoltConstants.WS_BOLT_ACCOUNT, query);
            Id result = Database.executeBatch(accountCallout, 200);            
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'failed');
        }
    }
}