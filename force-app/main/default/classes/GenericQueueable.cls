/**
 * @description       : This is the template queueable class used to chain Executeable jobs that use this as a base class.  
 *                      The configuration for this is controlled in the Execute Item Configurations custom metadata types
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
public without sharing abstract class GenericQueueable implements Queueable, Database.AllowsCallouts, IGenericQueueable {
    protected ISelection currentSelection;
    protected String currentClassName='';
    protected List<ExecutionItem> executionItemLst = new List<ExecutionItem>();
    protected Integer retryNumber=0;
    protected String objectName='';
    protected String triggerEvent='';
    protected Map<Id, String> errorById = new Map<Id, String>();
    protected Boolean isDelay=false;
    protected Integer delayInMinutes=0;

    public abstract void execute(QueueableContext context); 


    public virtual void handleNext() {
        if (!executionItemLst.isEmpty()) {
            executionItemLst.sort();  //sort by order

            ExecutionItem nextEi = executionItemLst[0]; //get next one
            executionItemLst.remove(0); //remove next one

            //setup next handler
            Boolean nextIsDelay = nextEi.getIsDelay();
            if (nextIsDelay) {
                setUpHandler(executionItemLst, nextEi.getSelection(), nextEi.getQueueableClassName(), 0, nextEi.getTriggerOperation(), nextEi.getObjectType(), nextEi.getDelayInMinutes());
            } else {
                setUpHandler(executionItemLst, nextEi.getSelection(), nextEi.getQueueableClassName(), 0, nextEi.getTriggerOperation(), nextEi.getObjectType());
            }
        }
    }

    public virtual void handleNext(Integer delayInMinutes) {
        if (!executionItemLst.isEmpty()) {
            executionItemLst.sort();  //sort by order

            ExecutionItem nextEi = executionItemLst[0]; //get next one
            executionItemLst.remove(0); //remove next one

            //setup next handler
            setUpHandler(executionItemLst, nextEi.getSelection(), nextEi.getQueueableClassName(), 0, nextEi.getTriggerOperation(), nextEi.getObjectType(), delayInMinutes);
        }
    }
    
    public abstract void handleError(Exception e);

    public void setQueueableClassName(String newClassName) {
        currentClassName = newClassName;
    }
    
    public void setISelection(ISelection newSelection) {
        currentSelection = newSelection;
    }

    public void setExecutionItemLst(List<ExecutionItem> newExecutionItemLst) {
        executionItemLst=newExecutionItemLst;
    }

    public void setRetryNumber(Integer newRetryNumber) {
        retryNumber=newRetryNumber;
    }

    public void setTriggerOperation(String triggerOperation) {
        triggerEvent=triggerOperation;
    }
    
    public void setObjectName(String objectType) {
        objectName=objectType;
    }

    public void setIsDelay(Boolean shouldDelay) {
        isDelay=shouldDelay;
    }

    public void setDelayInMinutes(Integer delayMinutes) {
        delayInMinutes=delayMinutes;
    }
    
    protected void setUpHandler(List<ExecutionItem> executionItemLst, ISelection currentSelection, String currentClassName, Integer currentRetryNumber, String triggerOperation, String objectType) {
        Type queueableType = Type.forName(currentClassName);
        GenericQueueable queueableClass = (GenericQueueable)queueableType.newInstance();
        queueableClass.setQueueableClassName(currentClassName);
        queueableClass.setISelection(currentSelection);
        queueableClass.setExecutionItemLst(executionItemLst);
        queueableClass.setRetryNumber(currentRetryNumber);
        queueableClass.setTriggerOperation(triggerOperation);
        queueableClass.setObjectName(objectType);
        String jobId = System.enqueueJob(queueableClass);
    }  

    protected void setUpHandler(List<ExecutionItem> executionItemLst, ISelection currentSelection, String currentClassName, Integer currentRetryNumber, String triggerOperation, String objectType, Integer delayInMinutes) {
        Type queueableType = Type.forName(currentClassName);
        GenericQueueable queueableClass = (GenericQueueable)queueableType.newInstance();
        queueableClass.setQueueableClassName(currentClassName);
        queueableClass.setISelection(currentSelection);
        queueableClass.setExecutionItemLst(executionItemLst);
        queueableClass.setRetryNumber(currentRetryNumber);
        queueableClass.setTriggerOperation(triggerOperation);
        queueableClass.setObjectName(objectType);
        queueableClass.setIsDelay(true);
        queueableClass.setDelayInMinutes(delayInMinutes);
        String jobId = System.enqueueJob(queueableClass, delayInMinutes);
    }

    protected virtual Map<Id, String> updateRecs(Map<Id, SObject> recById) {
        return DynamicApexService.updateRecs(recById);
    }    
}