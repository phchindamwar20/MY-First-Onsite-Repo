/**
 * @description  This is the interface to be implemented by all trigger handler classes.
 *               Simply complete the implemented methods which are required for the trigger. 
 *               Leave any events that you do not need blank.
 * @author Chris Aldridge, http://chrisaldridge.com/triggers/lightweight-apex-trigger-framework/
 * @date Jan 4, 2016
 * @author Mark H. Morrison, https://github.com/MarkHMorrison/Lightweight-Trigger-Framework
 * @date Sat Dec 29, 2018
 * @modified Fri Dec 13, 2019 by TJiles
 * 
 * @Changes:  Changes made by Terri Jiles to 1. handle recursion 2. Data Admin bypass, 3. chain of responsibility queueable framework 

 */
public abstract class TriggerHandlerBase implements ITriggerHandler{
	
    public virtual void beforeInsert(SObject[] newItems) {}
  
    public virtual void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
  
    public virtual void beforeDelete(Map<Id, SObject> oldItems) {}
  
    public virtual void afterInsert(Map<Id, SObject> newItems) {}
  
    public virtual void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
  
    public virtual void afterDelete(Map<Id, SObject> oldItems) {}
  
    public virtual void afterUndelete(Map<Id, SObject> oldItems) {}

    public virtual void beforeInsert(SObject[] newItems, Integer executionNumber) {}
  
    public virtual void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems, Integer executionNumber) {}
  
    public virtual void beforeDelete(Map<Id, SObject> oldItems, Integer executionNumber) {}
  
    public virtual void afterInsert(Map<Id, SObject> newItems, Integer executionNumber) {}
  
    public virtual void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems, Integer executionNumber) {}
  
    public virtual void afterDelete(Map<Id, SObject> oldItems, Integer executionNumber) {}
  
    public virtual void afterUndelete(Map<Id, SObject> newItems, Integer executionNumber) {}

    public virtual void afterSync(String objectApiName, String triggerOperation, Map<Id, SObject> newRecById, Map<Id, SObject> oldRecById) {
        if (ExecutionService.isExecutionItemConfigAvailable(objectApiName, triggerOperation)) {
            AfterSyncQueueable asq = new AfterSyncQueueable(objectApiName, triggerOperation, newRecById, oldRecById);
            String jobId = System.enqueueJob(asq);
        }
    }
  
    public virtual Boolean IsDisabled() {

        try {
            DataAdmin__c bypass = DataAdmin__c.getInstance();
            return bypass.TurnOffTrigger__c;
        }
        // if custom setting doesn't exists, don't disable 
        catch (Exception e) {
            return false;
        }                
    }
  }