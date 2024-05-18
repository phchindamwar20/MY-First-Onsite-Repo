/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-26-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public class InvoiceManagerTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/Invoice';

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
    private static void testUpsertInvoice(){   
        //Get parent records
        WorkOrder job = [SELECT Id FROM WorkOrder Limit 1];

        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{'+
        '    "BoltInvoiceUniqueID": "ksdflkjs",'+
        '    "AmountDue": 100.00,'+
        '    "AmountInvoiced": 100.00,'+
        '    "DueDate": "2022-12-25",'+
        '    "InvoiceDate": "2022-11-05", '+
        '    "InvoiceNumber": "INV123453",'+   
        '    "JobId": "'+job.Id+'",'+
        '    "LastModifiedDate": "2022-10-25T12:05:00.00Z",'+
        '    "LastPaymentDate": "2022-10-25T12:05:00.00Z",'+
        '    "Status":"Open",'+
        '    "TaxBilled": 1.50,'+
        '    "Type": "Invoice"'+
        '}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        InvoiceManager.upsertInvoice();
        Test.stopTest();
        
        // Verify record was updated
        Invoice__c invoiceRec = [SELECT Id FROM Invoice__c Limit 1];
        System.assert(invoiceRec != null);
        System.debug('~~~~ InvoiceManagerTest::testUpsertInvoice responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('BoltInvoiceUniqueID'));
        System.assert(response.responseBody.toString().contains('Id'));
    } 
}