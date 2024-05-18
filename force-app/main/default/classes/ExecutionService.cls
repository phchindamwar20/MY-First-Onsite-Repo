/**
 * @description       : This execution service gets and chains queueable jobs for a given object/trigger operation based on configuration setting Execute_Item_Configuration__mdt
 *                      Call this in a trigger in each of the events, where needed to dynamically chain jobs.
 *                      This utlizes the chain of responsibility software design pattern
  *                      This framework built into the trigger allows a developer to add a queueable class in a trigger without modifying the trigger.
 *                      All one has to do is:
 *                      1.  Create a Selection Class that extends the Selection Base Class.  It is used to determine what records to process.
 *                      2.  Create a Queueable Class that extends the GenericQueueable Class.  It is used to process whatever business functionaity needs to be executed 'as a link in the chain'.
 *                              The GenericQueueable base class has a handleNext method that the developer needs to call in their extended class, so the class will know what 'link in the chain' to process next.
 *                              The developer will also need to implment the handleError class, based on whatever business requirement they may have to handle error, continue or stop processing the next link in the chain.
 *                              The developer can also choose to dynamically 'add links to the chain', by creating an ExecutionItem and adding it to the executionItemLst.
 *                              Instead of putting all the business logic directly in the queueable class, it is recommended to put it in a separate class so that business logic can be called from any context, if needed, outside of this framework.
 *                      3.  Create an Execution Configuration Item custom metadata type 'record' that specifies the object api name, trigger event, selection class name, and queueable class name, and the order
 *                      4.  Create a Test class for the Queueable Class that test both the Queueable class and the Selection Class.  If a separate class contains the business logic utilized by the queueable class, create a separate test class for it also to do more extensive testing.
 *                      If you want to learn more about the patterns used in this queueable chain of responsibility design pattern, 
 *                      Please read 'Apex Design Patterns' by Jitendra Zaa, Anshul Verma.
 *                      In particular, read the 
 *                          1. Creational Patterns - Factory method pattern
 *                          2. Structural Patterns - The bridge pattern
 *                          3. Behavior Patterns - The chain of responsibility pattern
 *                      The following classes and Interfaces make up the queueable chain of repsonsibility framework utilized in the trigger
 *                          - ExecutionItem
 *                          - ExecutionService
 *                          - GenericQueueable
 *                          - IGenericQueueable (interface)
 *                          - ISelection (interface)
 *                          - ITriggerHandler (interface)
 *                          - SelectionBase
 *                          - TriggerDispatcher
 *                          - TriggerHandlerBase
 *                      The Execution Configuration Item custom metadata type is used to configure the initial 'links' in the chain
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-18-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class ExecutionService {

    public static Boolean isExecutionItemConfigAvailable(String objectApiName, String triggerOperation) {
        Map<String, Object> valueByName = new Map<String, Object>();
        valueByName.put('objectApiName', objectApiName);
        valueByName.put('triggerOperation', triggerOperation);
        
        String queryCount = 'SELECT count() FROM Execute_Item_Configuration__mdt WHERE Object__c=:objectApiName AND Trigger_Operation__c=:triggerOperation';

        Integer numExeItemConfig = Database.countQueryWithBinds(queryCount, valueByName, AccessLevel.SYSTEM_MODE);

        if (numExeItemConfig > 0) {
            return true;
        } else {
            return false;
        }
    }

    public void buildAndKickoffQueueableJobs(String objectApiName, String triggerOperation, Map<Id, SObject> newRecById, Map<Id, SObject> oldRecById) {
        if (!String.isBlank(objectApiName) && !String.isBlank(triggerOperation)) {
            List<ExecutionItem> executionItemLst = buildExecutionItemsList(objectApiName, triggerOperation, newRecById, oldRecById);
            executeInitialHandler(executionItemLst);
        }
    }
    
    @TestVisible
    private List<ExecutionItem> buildExecutionItemsList(String objectApiName, String triggerOperation, Map<Id, SObject> newRecById, Map<Id, SObject> oldRecById) {
        List<ExecutionItem> executionItemLst = new List<ExecutionItem>();

        for (Execute_Item_Configuration__mdt eic : [SELECT Id, Object__c, Order__c, Queueable_Class_Name__c, Selection_Name__c, Trigger_Operation__c, Is_Active__c,
                                                    Is_Delay__c, Delay_In_Minutes__c 
                                                    FROM Execute_Item_Configuration__mdt
                                                    WHERE Object__c =: objectApiName AND Trigger_Operation__c =: triggerOperation
                                                    ORDER BY Order__c]) {
            
            Boolean isProcessSelection = false;
            if (eic.Is_Active__c == true) {
                //Only process the active selections when test classes aren't running
                //An Admin can easily disable a selection from processing by setting Active to false on the execution item configuration
                isProcessSelection = true;
            } else if (eic.Is_Active__c == false && Test.isRunningTest()) {
                //if active is false but salesforce is running the test class for this, go ahead and process the selection so the test classes won't break!  
                //The Execution Item Configuration shouldn't be deleted from the org until the classes referenced in the Execution Item Configuration are deleted.
                isProcessSelection = true;
            }
                                                        
            if (isProcessSelection == true) {
                ExecutionItem ei = new ExecutionItem(eic, newRecById, oldRecById);

                if (!ei.getSelection().getRecIds().isEmpty()) {
                    executionItemLst.add(ei); 
                    //System.debug('~~~~ ExecutiveService::buildAndKickoffQueueableJobs: ei - ' + ei);                  
                } else {
                    ei = null;
                }
            }
        }

        return executionItemLst;
    }

    @TestVisible
    private void executeInitialHandler(List<ExecutionItem> executionItemLst) {
        //System.debug('~~~~ ExecutionService::executeInitialHandler: executionItemLst.size() - ' + executionItemLst.size());
        if (executionItemLst != null && !executionItemLst.isEmpty()) {
            executionItemLst.sort();  //sort by order

            ExecutionItem nextEi = executionItemLst[0]; //get next one
            //System.debug('~~~~ ExecutionService::executeInitialHandler: nextEi - ' + nextEi);
            executionItemLst.remove(0); //remove next one

            Type queueableType = Type.forName(nextEi.getQueueableClassName());
            GenericQueueable queueableClass = (GenericQueueable)queueableType.newInstance();
            queueableClass.setQueueableClassName(nextEi.getQueueableClassName());
            queueableClass.setISelection(nextEi.getSelection());
            queueableClass.setExecutionItemLst(executionItemLst);
            queueableClass.setRetryNumber(0);
            queueableClass.setTriggerOperation(nextEi.getTriggerOperation());
            queueableClass.setObjectName(nextEi.getObjectType());

            if (nextEi.getIsDelay()) {
                queueableClass.setIsDelay(true);
                queueableClass.setDelayInMinutes(nextEi.getDelayInMinutes());
                String jobId = System.enqueueJob(queueableClass, nextEi.getDelayInMinutes());
            } else { 
                String jobId = System.enqueueJob(queueableClass);
            }
        }
    }

}