/**
 * @description       : This is the test class for IcertisAgreementAuthSignQueueable, we will be testing here with one user record only as 
 * 						Icertis API's only accept one user at a time.
 * @author            : Arpit Vashishtha
 * @group             : 
 * @last modified on  : 03-18-2024
 * @last modified by  : Terri Jiles
**/
@isTest
private without sharing class IcertisAgreementAuthSignQueueableTest {
	private static final String ICERTIS_SEL_ICCWA_AUTH_SIGN = 'SelectionIcertisAgreementAuthSign';
    private static final String ICERTIS_QUEUEABLE_ICCWA_AUTH_SIGN = 'IcertisAgreementAuthSignQueueable';
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
    private static void testIcertisAgreementAuthSignQueueableSimple() {
        System.assertEquals(numRec, [SELECT Id FROM WorkOrder WHERE ICM_Auto_Create_Context__c=null].size(), 'Fail:  Prevalidation check field, all jobs should have no Signatory Email'); 
        Map<Id, WorkOrder> oldJobsById = new Map<Id, WorkOrder>([SELECT Id, ICM_Auto_Create_Context__c FROM WorkOrder WHERE ICM_Auto_Create_Context__c = null]);
		Map<Id, WorkOrder> newJobsById = new Map<Id, WorkOrder>();
        
        for (WorkOrder workOrderObj : [SELECT Id, IC_Bolt_CWA__c, IC_Property_Owner_Name__c FROM WorkOrder WHERE ICM_Auto_Create_Context__c = null]) {
            newJobsById.put(workOrderObj.Id, new WorkOrder(Id=workOrderObj.Id, IC_Property_Owner_Name__c='Test', IC_Bolt_CWA__c = TRUE, IC_Signatory_Email__c='test@gmail.com'));
        }
        update newJobsById.values();
        
        List<ExecutionItem> eiLst = new List<ExecutionItem>();
        eiLst.add(new ExecutionItem(ICERTIS_QUEUEABLE_ICCWA_AUTH_SIGN, 1, ICERTIS_SEL_ICCWA_AUTH_SIGN, GeneralConstants.AFTER_UPDATE, GeneralConstants.OBJ_JOB, newJobsById, oldJobsById, 1));
        eiLst[0].getSelection().addToRecIds(newJobsById.keySet());

        Test.startTest();
        ExecutionService es = new ExecutionService();
        es.executeInitialHandler(eiLst);
        Test.stopTest(); 
    }

    @isTest
    private static void testSelectionCriteria() {
        WorkOrder job = [SELECT Id, IC_Bolt_CWA__c, AccountId FROM WorkOrder LIMIT 1];
        Contract contract1 = new Contract(Job__c=job.Id, Status=ICertisConstants.CS_DRAFT, AccountId=job.AccountId);
        insert contract1;

        SelectionIcertisAGreementsForSigning selection = new SelectionIcertisAGreementsForSigning();

        //insert new contract
        Assert.areEqual(false, selection.selectApproveContract(contract1, null), 'Fail: should be false for new contract');

        //change contract status to Send for Approval
        Contract contract2 = new Contract(Id=contract1.Id, Status=ICertisConstants.CS_SEND_FOR_APPROVAL);
        update contract2;
        Assert.areEqual(false, selection.selectApproveContract(contract2, contract1), 'Fail: should be true, status changed to Approved');

        //change contract status to approved
        Contract contract3 = new Contract(Id=contract1.Id, Status=ICertisConstants.CS_APPROVED);
        update contract3;
        Assert.areEqual(true, selection.selectApproveContract(contract3, contract2), 'Fail: should be true, status changed to Send for Approval');

        //no change in status
        Assert.areEqual(false, selection.selectApproveContract(contract3, contract3), 'Fail: should be false, no change in status');
    }
}