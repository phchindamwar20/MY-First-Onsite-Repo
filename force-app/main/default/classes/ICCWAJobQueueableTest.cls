/**
 * @description       : This is the test class for ICCWAJobQueueable, we will be testing here with one user record only as 
 *                      Icertis API's only accept one user at a time.
 * @author            : Arpit Vashishtha
 * @group             : 
 * @last modified on  : 03-18-2024
 * @last modified by  : Terri Jiles
**/
@isTest
private without sharing class ICCWAJobQueueableTest {
    private static final String ICERTIS_SEL_ICCWA_JOB = 'SelectionICCWAJobs';
    private static final String ICERTIS_QUEUEABLE_ICCWA_JOB = 'ICCWAJobQueueable';
    private static final Integer numRec = 1;
    
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
        
        IC_API__c customSettingObj = new IC_API__c();
        customSettingObj.Azure_Endpoint__c = 'https://www.loginmicrosoft.com/';
        customSettingObj.Client_Id__c = '1111111';
        customSettingObj.Client_Secret__c = 'XXXXXX';
        customSettingObj.Tenant_Id__c = 'TTTTTT';
        
        insert customSettingObj;
        
        List<Account> accLst  = (List<Account>)TestFactory.createSObjectList(new Account(GNG_Legal_Override__c=GeneralConstants.GO), numRec, 'TestFactoryDefaults.AccountDefaults', true);
        List<WorkOrder> jobLst = new List<WorkOrder>();

        for (Account acc : accLst) {
            jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id, Job_Name__c='Test Job', IC_Bolt_CWA__c = TRUE), 'TestFactoryDefaults.JobDefaults', false));
        }
        insert jobLst;
    }
    
    @isTest 
    private static void testICCWAJobQueueableSimple() {
        System.assertEquals(numRec, [SELECT Id FROM WorkOrder WHERE IC_Property_Owner_Name__c=''].size(), 'Fail:  Prevalidation check field, all jobs should have no Signatory Email'); 
        Map<Id, WorkOrder> oldJobsById = new Map<Id, WorkOrder>([SELECT Id, IC_Signatory_Email__c, IC_External_First_Name__c, 
                                                                 IC_External_Last_Name__c, IC_Property_Owner_Address_Different__c, 
                                                                 IC_Property_Owner_Name_Different__c, IC_Property_Owner_Address__c, 
                                                                 IC_Property_Owner_Name__c
                                                                 FROM WorkOrder WHERE IC_Property_Owner_Name__c =: '']);
        Map<Id, WorkOrder> newJobsById = new Map<Id, WorkOrder>();
        
        for (WorkOrder workOrderObj : [SELECT Id, IC_Bolt_CWA__c, IC_Property_Owner_Name__c FROM WorkOrder WHERE IC_Property_Owner_Name__c =: '']) {
            newJobsById.put(workOrderObj.Id, new WorkOrder(Id=workOrderObj.Id, IC_Property_Owner_Name__c='Test', IC_Bolt_CWA__c = TRUE, IC_Signatory_Email__c='test@gmail.com'));
        }
        update newJobsById.values();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IcertisHttpCalloutMockImpl());
        ExecutionService chainQueueableJobService = new ExecutionService();
        ExecutionItem ei = new ExecutionItem([SELECT Id, Object__c, Order__c, Queueable_Class_Name__c, Selection_Name__c, Trigger_Operation__c, Is_Delay__c, Delay_In_Minutes__c 
                                                FROM Execute_Item_Configuration__mdt
                                                WHERE Selection_Name__c=:ICERTIS_SEL_ICCWA_JOB LIMIT 1], newJobsById, oldJobsById);
        List<ExecutionItem> justMapWorkOrderItmLst = new List<ExecutionItem>();
        justMapWorkOrderItmLst.add(ei);

        chainQueueableJobService.executeInitialHandler(justMapWorkOrderItmLst);
        Test.stopTest();
        
        System.debug('~~~~ ei ' + ei);
        System.assertEquals(true, !ei.getSelection().getRecIds().isEmpty(),  'Fail:  WorkOrder did not happen.');
        System.debug('~~~~ WorkOrder: ' + [SELECT Id, IC_Property_Owner_Name__c FROM WorkOrder]);
        System.assertEquals(numRec, [SELECT Id FROM WorkOrder WHERE IC_Property_Owner_Name__c!=''].size(), 'Fail:  It did not update workorder.');   
    }
}