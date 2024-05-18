/**
 * @description  This is the interface to be implemented by all trigger handler classes.
 *               Simply complete the implemented methods which are required for the trigger. 
 *               Leave any events that you do not need blank.
 * @author Chris Aldridge, http://chrisaldridge.com/triggers/lightweight-apex-trigger-framework/
 * @date Jan 4, 2016
 * @author Mark H. Morrison, https://github.com/MarkHMorrison/Lightweight-Trigger-Framework
 * @date Sat Dec 29, 2018
 * 
 * @Changes:  Changes made by Terri Jiles to handle 1. recursion, 2. chain of responsibility queueable framework 
 */
public interface ITriggerHandler {
	
    void beforeInsert(SObject[] newItems);
  
    void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
  
    void beforeDelete(Map<Id, SObject> oldItems);
  
    void afterInsert(Map<Id, SObject> newItems);
  
    void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
  
    void afterDelete(Map<Id, SObject> oldItems);
  
    void afterUndelete(Map<Id, SObject> oldItems);

    void beforeInsert(SObject[] newItems, Integer executionNumber);
  
    void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems, Integer executionNumber);
  
    void beforeDelete(Map<Id, SObject> oldItems, Integer executionNumber);
  
    void afterInsert(Map<Id, SObject> newItems, Integer executionNumber);
  
    void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems, Integer executionNumber);
  
    void afterDelete(Map<Id, SObject> oldItems, Integer executionNumber);
  
    void afterUndelete(Map<Id, SObject> newItems, Integer executionNumber);  
    
    //This is for calling the chain of responsibility framework to handle async jobs
    void afterSync(String objectApiName, String triggerOperation, Map<Id, SObject> newRecById, Map<Id, SObject> oldRecById);
  
    // This method needs to be implemented to check whether or not trigger logic should run. You can remove this if this is not a requirement.
    Boolean IsDisabled();
  }