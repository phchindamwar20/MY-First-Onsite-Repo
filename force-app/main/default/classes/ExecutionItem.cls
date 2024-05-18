/**
 * @description       : This is the execution item derived from the Execute Item Configuration custom metadata types.  This is used to configure GenericQueuable class chainable jobs.
 *                      This framework built into the trigger allows a developer to add a queueable class in a trigger without modifying the trigger.
 *                      All one has to do is:
 *                      1.  Create a Selection Class that extends the Selection Base Class.  It is used to determine what records to process.
 *                      2.  Create a Queueable Class that extends the GenericQueueable Class.  It is used to process whatever business functionaity needs to be executed 'as a link in the chain'.
 *                              The GenericQueueable base class has a handleNext method that the developer needs to call in their extended class, so the class will know what 'link in the chain' to process next.
 *                              The developer will also need to implment the handleError class, based on whatever business requirement they may have to handle error, continue or stop processing the next link in the chain.
 *                              The developer can also choose to dynamically 'add links to the chain', by creating an ExecutionItem and adding it to the executionItemLst.
 *                              Instead of putting all the business logic directly in the queueable class, it is recommended to put it in a separate class so that business logic can be called from any context, if needed, outside of this framework.
 *                      3.  Create an Execution Cofniguration Item custom metadata type 'record' that specifies the object api name, trigger event, selection class name, and queueable class name, and the order
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
global without sharing class ExecutionItem implements Comparable{
    protected String queueableClassName;
    protected Decimal executionOrder;
    protected ISelection selection;
    protected String triggerOperation;
    protected String objectType;
    protected Boolean isDelay = false;
    protected Integer delayInMinutes = 0;

    public ExecutionItem(Execute_Item_Configuration__mdt executionItemConfig, Map<Id, SObject> newRecById, Map<Id, SObject> oldRecById) {
        //get selection
        Type selectionType = Type.forName(executionItemConfig.Selection_Name__c);
        this.selection = (ISelection)selectionType.newInstance();
        this.selection.setRecIdsToProcess(newRecById, oldRecById);
        this.selection.setSelectionName(executionItemConfig.Selection_Name__c);

        //get executionOrder
        this.executionOrder = executionItemConfig.Order__c;

        //get queueableClassName
        this.queueableClassName = executionItemConfig.Queueable_Class_Name__c;

        //get triggerOperation
        this.triggerOperation = executionItemConfig.Trigger_Operation__c;

        //get object
        this.objectType = executionItemConfig.Object__c;

        //get Is Delay?
        this.isDelay = executionItemConfig?.Is_Delay__c == null ? false : executionItemConfig.Is_Delay__c;

        //get Delay in Minutes
        this.delayInMinutes = executionItemConfig?.Delay_In_Minutes__c != null ? Integer.valueOf(executionItemConfig.Delay_In_Minutes__c) : 0;
    }

    //constructor for adding adding conditional ad hoc jobs to chains
    public ExecutionItem(String queueableClass, Decimal executionOrder, String selectionName, String triggerExecution, String objectName, Map<Id, SObject> newRecById, Map<Id, SObject> oldRecById) {
        //get selection
        Type selectionType = Type.forName(selectionName);
        this.selection = (ISelection)selectionType.newInstance();
        this.selection.setRecIdsToProcess(newRecById, oldRecById);
        this.selection.setSelectionName(selectionName);      
        
        //get executionOrder
        this.executionOrder = executionOrder;

        //get queueableClassName
        this.queueableClassName = queueableClass;

        //get triggerOperation
        this.triggerOperation = triggerExecution;

        //get object
        this.objectType = objectName;
    }

    //constructor for adding adding conditional ad hoc jobs to chains
    public ExecutionItem(String queueableClass, Decimal executionOrder, String selectionName, String triggerExecution, String objectName, Map<Id, SObject> newRecById, Map<Id, SObject> oldRecById, Integer delayInMinutes) {
        this(queueableClass, executionOrder, selectionName, triggerExecution, objectName, newRecById, oldRecById);
        this.isDelay=true;
        this.delayInMinutes=delayInMinutes;
    }    


    //get selection
    public ISelection getSelection() {
        return selection;
    }

    //get queueable class name
    public String getQueueableClassName() {
        return queueableClassName;
    }

    //get execution order
    public Decimal getExecutionOrder() {
        return executionOrder;
    }

    //get trigger operation
    public String getTriggerOperation() {
        return triggerOperation;
    }

    //get object type
    public String getObjectType() {
        return objectType;
    }

    //get is  delay
    public Boolean getIsDelay() {
        return isDelay;
    }

    //get Delay In Minutes
    public Integer getDelayInMinutes() {
        return delayInMinutes;
    }

    //compare execution items
    global Integer compareTo(Object compareTo) {
        ExecutionItem compareToExeItem = (ExecutionItem)compareTo;
        if (executionOrder == compareToExeItem.executionOrder) return 0;
        if (executionOrder > compareToExeItem.executionOrder) return 1;
        return -1;
    }
}