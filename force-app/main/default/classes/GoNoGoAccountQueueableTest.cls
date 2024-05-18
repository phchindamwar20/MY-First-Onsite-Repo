/**
 * @description       : This is the test class for GoNoGoAccountQueueable
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-19-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class GoNoGoAccountQueueableTest {
    private static final String ACC_GO_NO_GO_SELECTION = 'SelectionGoNoGoAccount';
    private static final String ACC_GO_NO_GO_CHAIN_OF_RESPONS_QUEUEABLE = 'GoNoGoAccountQueueable';
    //private static final Integer numRec = 200;
    private static final Integer numRec = 100; //STAR-6353

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
    private static void testGoNoGoAccountQueueableSimple() {
        System.assertEquals(numRec, [SELECT Id FROM Account WHERE Go_No_Gox__c=:GeneralConstants.NO_GO].size(), 'Fail:  Prevalidation check field, all accounts should be no go'); 
        Map<Id, Account> accById = new Map<Id, Account>([SELECT Id FROM Account]);

        List<ExecutionItem> eiLst = new List<ExecutionItem>(); 
        eiLst.add(new ExecutionItem(ACC_GO_NO_GO_CHAIN_OF_RESPONS_QUEUEABLE, 0, ACC_GO_NO_GO_SELECTION, GeneralConstants.AFTER_UPDATE, GeneralConstants.OBJ_ACCOUNT, accById, null));

        Test.startTest();
        ExecutionService es = new ExecutionService();
        es.executeInitialHandler(eiLst);
        Test.stopTest();

        System.assertEquals(numRec, [SELECT Id FROM Account WHERE Go_No_Gox__c=:GeneralConstants.GO].size(), 'Failed:  All accounts should be Go');        
    }

    @isTest
    private static void testGoNoGoAccountQueueableWithJobs() {
        System.assertEquals(numRec, [SELECT Id FROM Account WHERE Go_No_Gox__c=:GeneralConstants.NO_GO].size(), 'Failed:  Prevalidation failed, all accounts should be No Go');        
        System.assertEquals(numRec, [SELECT Id FROM WorkOrder WHERE Go_No_Gox__c=:GeneralConstants.NO_GO].size(), 'Failed:  Prevalidation failed, all jobs should be No Go');

        Map<Id, Account> accById = new Map<Id, Account>([SELECT Id FROM Account]);

        ExecutionItem nextEi = new ExecutionItem(ACC_GO_NO_GO_CHAIN_OF_RESPONS_QUEUEABLE, 0, ACC_GO_NO_GO_SELECTION, GeneralConstants.AFTER_UPDATE, GeneralConstants.OBJ_ACCOUNT, accById, null);

        GoNoGoAccountQueueable gngAcc = new GoNoGoAccountQueueable();
        gngAcc.setQueueableClassName(nextEi.getQueueableClassName());
        gngAcc.setISelection(nextEi.getSelection());
        gngAcc.setExecutionItemLst(new List<ExecutionItem>());
        gngAcc.setRetryNumber(0);
        gngAcc.setTriggerOperation(nextEi.getTriggerOperation());
        gngAcc.setObjectName(nextEi.getObjectType());

        Test.startTest();
        gngAcc.calculateGoNoGo(accById.keySet());
        Test.stopTest();

        System.assertEquals(numRec, [SELECT Id FROM Account WHERE Go_No_Gox__c=:GeneralConstants.GO].size(), 'Failed:  All accounts should be Go');        
        System.assertEquals(numRec, [SELECT Id FROM WorkOrder WHERE Go_No_Gox__c=:GeneralConstants.GO].size(), 'Failed:  All jobs should be Go');
    }
}