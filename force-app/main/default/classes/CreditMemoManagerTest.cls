/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-14-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class CreditMemoManagerTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/CreditMemo';

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
        Account acc = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.AccountDefaults', true);
        Account propertyNew = (Account)TestFactory.createSObject(new Account(ParentId=acc.Id), 'TestFactoryDefaults.PropertyDefaults', true);
        WorkOrder job = (WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id, Property__c=propertyNew.Id), 'TestFactoryDefaults.JobDefaults', true);
    }

    @isTest
    private static void testUpsertCreditMemo(){   
        //Get parent records
        WorkOrder job = [SELECT Id, AccountId FROM WorkOrder Limit 1];
        Invoice__c inv = new Invoice__c(Job__c=job.Id, Bolt_Invoice_Number__c='4345433', Invoice_Number__c='abcdefg');
        insert inv;

        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{'+
        '    "AccountId": "'+job.AccountId+'",'+
        '    "BillingBackup": "http://www.salesforce.com",'+
        '    "BillingPhone": "739-746-9475",'+
        '    "BoltUniqueID": "8347yfagafg",'+
        '    "CreditMemoNumber": "23849",'+
        '    "Description": "Description",'+
        '    "JobId": 345.00,'+
        '    "InvoiceDate": "2022-11-05",'+
        '    "InvoiceKey": "'+inv.Bolt_Invoice_Number__c+'",'+    
        '    "JobId": "'+job.Id+'",'+
        '    "JobType": "Migration",'+
        '    "LastModifiedDate": "2022-11-05T12:05:00.00Z",'+    
        '    "Quantity": 2,'+
        '    "Status": "Open",'+
        '    "Total": 1000'+
        '}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        CreditMemoManager.upsertCreditMemo();
        Test.stopTest();
        
        // Verify record was updated
        Credit_Memo__c creditMemoRec = [SELECT Id FROM Credit_Memo__c  Limit 1];
        System.assert(creditMemoRec != null);
        System.debug('~~~~ CreditMemoManagerTest::testUpsertCreditMemo responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('BoltUniqueID'));
        System.assert(response.responseBody.toString().contains('Id'));
    } 
}