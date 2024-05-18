/**
 * @description       : The test class for TransactionManager
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-23-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public class TransactionManagerTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/Transaction';

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
    private static void testUpsertTransaction(){ 
        //Get parent records
        WorkOrder job = [SELECT Id FROM WorkOrder Limit 1];

        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{'+
        '    "AccountingPeriod": "October 2022",'+
        '    "JobId": "'+job.Id+'",'+
        '    "NewValue": 300,'+
        '    "OldValue": 485,'+
        '    "StatusChangeDate": "2022-10-25T12:05:00.00Z",'+
        //'    "TransactionDate": "2022-10-25",'+
        '    "Type":"Margin",'+
        '    "UniqueId": "XYZ",'+
        '    "User": "TEST"'+
        '}');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        TransactionManager.upsertTransaction();
        Test.stopTest();
        
        // Verify record was updated
        Transaction__c transactionRec = [SELECT Id FROM Transaction__c Limit 1];
        System.assert(transactionRec != null);
        System.debug('~~~~ TransactionManagerTest::testUpsertTransaction responseBody - ' + response.responseBody.toString());
        System.assertEquals(200, response.statusCode);
        System.assert(response.responseBody.toString().contains('UniqueId'));
        System.assert(response.responseBody.toString().contains('Id'));
    }    
}