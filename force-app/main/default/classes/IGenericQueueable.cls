/**
 * @description       : The interface for GenericQueueable class used to dynamically chain queuable classes together 
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
 * @group             : 
 * @last modified on  : 08-04-2023
 * @last modified by  : Terri Jiles
**/
public interface IGenericQueueable {
    void handleNext();
    void handleError(Exception e);
    void setQueueableClassName(String newClassName);
    void setISelection(ISelection newSelection);
    void setExecutionItemLst(List<ExecutionItem> newExecutionItemLst);
    void setRetryNumber(Integer newRetryNumber);
    void setTriggerOperation(String triggerOperation);
    void setObjectName(String objectType);
    //void execute (QueueableContext context);
}