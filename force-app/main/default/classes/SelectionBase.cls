/**
 * @description       : This is the selection base utilized by the GenericQueueable class.  The selection determines what records to process.  This utilizes the Bridge software design pattern
 *                      This framework built into the trigger allows a developer to add a queueable class in a trigger without modifying the trigger.
 * 
 *                      RECOMMENDATION ON GETTING SELECTED RECORD: In the class that extends the SelectionBase, it is suggested to create a private Boolean method with the @TestVisible annotation that has a 
 *                      newSObj and oldSObj input (or other info ) to determine if a record should be added to the recIds.  This makes unit testing the entire selection criteria easier in a test class
 * 
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
 * @last modified on  : 08-06-2023
 * @last modified by  : Terri Jiles
**/
public abstract without sharing class SelectionBase implements ISelection {
    protected Set<Id> recIds = new Set<Id>();
    protected String selectionName;

    public virtual Set<Id> getRecIds() {
        return recIds;
    }
    
    //If you need to create a query to query records instead or addition to using the input map parameters, 
    //please put your query outside the loop and inside of map.  
    //All though this temporarily increase the heap size, it should in theory reduce the chances of a cpu time out limit error
    //Given there could be many selection classes the code iterates though, the cpu time is the greater risk than the heap space
    //The heap space should be cleared when we exit the scope it is defined in, since these are NOT static 
    //If heap space size is a concern but cpu time out limit isn't a concern, then we should use sqol for loops instead of putting the sqol inside a map
    public abstract void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById);

    public virtual void setSelectionName(String iSelectionName) {
        selectionName=iSelectionName;
    }

    public virtual String getSelectionName() {
        return selectionName;
    }

    public virtual void addToRecIds(Set<Id> newRecIds) {
        recIds.addAll(newRecIds);
    }
}