/**
 * @description       : This is the test class for SeletionBoltIntegrationFormula and BoltIntegrationFormulaQueueable
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-20-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public with sharing class BoltIntegrationFormulaQueueableTest {
    private static Integer numAccRec = 2;
    private static Integer numJobPerAccRec = 100;
    private static String QUE_CLASS='BoltIntegrationFormulaQueueable';
    private static String SEL_CLASS = 'SelectionBoltIntegrationFormula';

    @TestSetup
    static private void makeData(){
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
        List<Account> accLst  = (List<Account>)TestFactory.createSObjectList(new Account(), numAccRec, 'TestFactoryDefaults.AccountDefaults', true);
        List<WorkOrder> jobLst = new List<WorkOrder>();

        for (Account acc : accLst) {
            jobLst.addAll((List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=acc.Id, Job_Name__c='Test Job'), numJobPerAccRec, 'TestFactoryDefaults.JobDefaults', false));
        }
        insert jobLst;        
    }

    @isTest
    private static void testFullBatch() {
        //setup data
        Map<Id,Account> accOldById = new Map<Id, Account>([SELECT Id, Client_WO_PO_Required__c FROM Account]);
        Map<Id, Account> accNewById = new Map<Id, Account>();
        for (Account acc : accOldById.values()) {
            accNewById.put(acc.Id, new Account(Id=acc.Id, Client_WO_PO_Required__c=true));
        }
        update accNewById.values();

        List<ExecutionItem> eiLst = new List<ExecutionItem>();
        eiLst.add(new ExecutionItem(QUE_CLASS, 1, SEL_CLASS, GeneralConstants.AFTER_UPDATE, GeneralConstants.OBJ_ACCOUNT, accNewById, accOldById));

        //test
        Test.startTest();
        ExecutionService es = new ExecutionService();
        es.executeInitialHandler(eiLst);
        Test.stopTest();
        
        //verify results... can't test the bolt callout portion
        System.assert([SELECT Id FROM WorkOrder WHERE BoltUpdateTrigger__c !=null].size() == numJobPerAccRec*2, 'Jobs not updated');
    }

    @isTest
    private static void testPartialBatch() {
        //setup data
        Integer numJobHalf = numJobPerAccRec;
        delete [SELECT Id FROM WorkOrder LIMIT : numJobHalf];
        Map<Id,Account> accOldById = new Map<Id, Account>([SELECT Id, Client_WO_PO_Required__c FROM Account]);
        Map<Id, Account> accNewById = new Map<Id, Account>();
        for (Account acc : accOldById.values()) {
            accNewById.put(acc.Id, new Account(Id=acc.Id, Client_WO_PO_Required__c=true));
        }
        update accNewById.values();

        List<ExecutionItem> eiLst = new List<ExecutionItem>();
        eiLst.add(new ExecutionItem(QUE_CLASS, 1, SEL_CLASS, GeneralConstants.AFTER_UPDATE, GeneralConstants.OBJ_ACCOUNT, accNewById, accOldById));

        //test
        Test.startTest();
        ExecutionService es = new ExecutionService();
        es.executeInitialHandler(eiLst);
        Test.stopTest();
        
        //verify results... can't test the bolt callout portion
        System.assert([SELECT Id FROM WorkOrder WHERE BoltUpdateTrigger__c !=null].size() == numJobHalf, 'Jobs not updated');
    }    
}