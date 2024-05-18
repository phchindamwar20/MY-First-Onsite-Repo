/**
 * @description       : This is the test calss for DynamicApexService
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-03-2024
 * @last modified by  : Terri Jiles
**/
@isTest(seeAllData=false)
public with sharing class DynamicApexServiceTest {
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
    private static void testGetFieldValue() {
        Account accNew = (Account)TestFactory.createSObject(new Account(Name='Test Test'), 'TestFactoryDefaults.AccountDefaults', true);
        Account property = (Account)TestFactory.createSObject(new Account(ParentId=accNew.Id), 'TestFactoryDefaults.PropertyDefaults', true);
        Contact adjusterNew = (Contact)TestFactory.createSObject(new Contact(AccountId=accNew.Id, LastName='Adjuster', FirstName='Contact', Email='adjuster@test.com'), 'TestFactoryDefaults.ContactDefaults', true);


        WorkOrder job =  (WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=accNew.Id, Property__c=property.Id, Insurance_Adjuster_Contactx__c=adjusterNew.Id), 'TestFactoryDefaults.JobDefaults', true);
        List<WorkOrder> jobLst = [SELECT Id, AccountId, Property__c, Insurance_Adjuster_Contactx__r.Name FROM WorkOrder];

        System.assertEquals(jobLst[0].Insurance_Adjuster_Contactx__r.Name, (String)DynamicApexService.getFieldValue('Insurance_Adjuster_Contactx__r.Name', jobLst[0]));
        
    }

    @isTest
    private static void testGetFieldNameByRelationshipInfo(){
        Map<String, Schema.sObjectField> fieldNameByRelationshipInfoMap = new Map<String, Schema.sObjectField>();

        Test.startTest();
        fieldNameByRelationshipInfoMap = DynamicApexService.getFieldNameByRelationshipInfo('WorkOrder');
        Test.stopTest();

        System.assertEquals(true, fieldNameByRelationshipInfoMap.containsKey('BD_Account_Manager__r'));
    }

    @isTest
    private static void getValueType() {
        SObject objectType = Schema.getGlobalDescribe().get('WorkOrder').newSObject();
        Map<String, Schema.sObjectField> targetFieldSchemaByField = objectType.getSObjectType().getDescribe().fields.getMap();
        Datetime thisdt = Datetime.now();
        Date thisd = Date.today();
        //System.assertEquals(thisd, BoltService.getValueType(targetFieldSchemaByField, 'Start_Date__c', String.valueOf(thisd))); //Date
        System.assertEquals(thisdt, DynamicApexService.getValueType(targetFieldSchemaByField, 'CreatedDate', String.valueOf(thisdt))); //Datetime
        System.assertEquals(100.0, DynamicApexService.getValueType(targetFieldSchemaByField, 'GrandTotal', String.valueOf(100.0))); //Currency=>Decimal
        System.assertEquals(1.2, DynamicApexService.getValueType(targetFieldSchemaByField, 'Duration', String.valueOf(1.2))); //Double
        System.assertEquals(30.2, DynamicApexService.getValueType(targetFieldSchemaByField, 'Initial_Margin__c', String.valueOf(30.2))); //Percent =>Decimal
        System.assertEquals(true, DynamicApexService.getValueType(targetFieldSchemaByField, 'Bid__c', 'true')); //Boolean
        System.assertEquals(2, DynamicApexService.getValueType(targetFieldSchemaByField, 'MinimumCrewSize', String.valueOf(2))); //Integer
        System.assertEquals('Test Name', DynamicApexService.getValueType(targetFieldSchemaByField, 'Job_Name__c', 'Test Name')); //else String
        System.assertEquals(null, DynamicApexService.getValueType(targetFieldSchemaByField, 'Running_Margin__c', null));
    }
    
    @isTest 
    private static void testIsFieldExists() {
        Boolean isFieldExist = DynamicApexService.isFieldExists('Account', 'Name');
        Assert.areEqual(true, isFieldExist, 'Field exist.');
    }
    
    @isTest 
    private static void testCreateObject() {
        SObject sObj = DynamicApexService.createObject('Account');
        Assert.areNotEqual(null, sObj, 'SObject created.');
    }
    
    @isTest 
    private static void testUpdateRecs() {
        Map<Id, Account> recIdMap = new Map<Id, Account>([SELECT Id FROM ACCOUNT LIMIT 1]);
        Map<Id, String> recAccIdMap = DynamicApexService.updateRecs(recIdMap);
        Assert.areNotEqual(null, recAccIdMap, 'Records Updated.');
    }

    /*
    @isTest
    private static void testGetErrorsFromDelResult() {
        WorkOrder job = (WorkOrder)TestFactory.createSObject(new WorkOrder(), 'TestFactoryDefaults.JobDefaults', true);
        List<Employee_Commission__c> empComDelLst = new List<Employee_Commission__c>();
        //String empComPrefix = Employee_Commission__c.SObjectType.getDescribe().getKeyPrefix();
        //Id empComFakeId = empComPrefix + 'Oy00000036X7IAX';
        Id empComFakeId=null;
        empComDelLst.add(new Employee_Commission__c(Job__c=job.Id));
        Map<Id, List<Database.Error>> errorLstByJobId = new Map<Id, List<Database.Error>>();
        
        Test.startTest();
        Database.DeleteResult[] delEcResultLst =  Database.delete(empComDelLst, false);
        errorLstByJobId = DynamicApexService.getErrorsFromDelResult(delEcResultLst,  empComDelLst, 'Job__c', errorLstByJobId);
        Test.stopTest();

        Assert.areEqual(1, errorLstByJobId.size(), 'Failed:  need map of errors');
    }
    */

    @isTest
    private static void testGetErrorsFromResult() {
        WorkOrder job = (WorkOrder)TestFactory.createSObject(new WorkOrder(), 'TestFactoryDefaults.JobDefaults', true);
        List<Employee_Commission__c> empComUpdLst = new List<Employee_Commission__c>();
        empComUpdLst.add(new Employee_Commission__c(Job__c=job.Id));
        Map<Id, List<Database.Error>> errorLstByJobId = new Map<Id, List<Database.Error>>();
        
        Test.startTest();
        Database.SaveResult[] updEcResultLst =  Database.update(empComUpdLst, false);
        errorLstByJobId = DynamicApexService.getErrorsFromResult(updEcResultLst,  empComUpdLst, 'Job__c', errorLstByJobId);
        Test.stopTest();

        Assert.areEqual(1, errorLstByJobId.size(), 'Failed:  need map of errors');
    }    
}