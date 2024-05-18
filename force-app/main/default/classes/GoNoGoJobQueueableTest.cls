/**
 * @description       : This is the test class for GoNoGoJobQueueable
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class GoNoGoJobQueueableTest {
    private static final String JOB_GO_NO_GO_SELECTION = 'SelectionGoNoGoJob';
    private static final String JOB_GO_NO_GO_CHAIN_OF_RESPONS_QUEUEABLE = 'GoNoGoJobQueueable';
    private static final Integer numRec = 200;

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
        List<Account> accLst  = (List<Account>)TestFactory.createSObjectList(new Account(GNG_Legal_Override__c=GeneralConstants.GO), numRec, 'TestFactoryDefaults.AccountDefaults', true);
        List<WorkOrder> jobLst = new List<WorkOrder>();

        for (Account acc : accLst) {
            jobLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(AccountId=acc.Id, Job_Name__c='Test Job'), 'TestFactoryDefaults.JobDefaults', false));
        }
        insert jobLst;
    }

    @isTest 
    private static void testGoNoGoJobQueueableSimple() {
        System.assertEquals(numRec, [SELECT Id FROM WorkOrder WHERE Go_No_Gox__c=:GeneralConstants.NO_GO].size(), 'Fail:  Prevalidation check field, all jobs should be no go'); 
        Map<Id, WorkOrder> jobById = new Map<Id, WorkOrder>([SELECT Id FROM WorkOrder]);

        List<ExecutionItem> eiLst = new List<ExecutionItem>(); 
        eiLst.add(new ExecutionItem(JOB_GO_NO_GO_CHAIN_OF_RESPONS_QUEUEABLE, 0, JOB_GO_NO_GO_SELECTION, GeneralConstants.AFTER_UPDATE, GeneralConstants.OBJ_JOB, jobById, null));

        Test.startTest();
        ExecutionService es = new ExecutionService();
        es.executeInitialHandler(eiLst);
        Test.stopTest();

        System.assertEquals(numRec, [SELECT Id FROM WorkOrder WHERE Go_No_Gox__c=:GeneralConstants.GO].size(), 'Failed:  All jobs should be Go');        
    }
}