/**
 * @description  This class runs the appropriate methods on the trigger handler based on the current trigger context.
 * @author Chris Aldridge, http://chrisaldridge.com/triggers/lightweight-apex-trigger-framework/
 * @date Dec 31, 2015
 * @author Sep 25 by krigi, https://github.com/krigi/Lightweight-Trigger-Framework , 
 *                          Updated by krigi to take advantage of Summer’18 features: Apex switch statement and Trigger.operationType context variable
 * @date Sep 25, 2018
 * @author Mark H. Morrison, https://github.com/MarkHMorrison/Lightweight-Trigger-Framework
 * @date Sat Dec 29, 2018
 * 
 * @Changes:  Changes made by Terri Jiles to handle 1. recursion, 2. chain of responsibility queueable framework 

 */
public class TriggerDispatcher {
    /*
      Call this method from your trigger, passing in an instance of a trigger handler which implements ITriggerHandler.
      This method will fire the appropriate methods on the handler depending on the trigger context.
    */
    public static Map<String, TriggerContext> tc = new Map<String, TriggerContext>();
    public static integer excution=0;
  
    public static void run(String objectName, System.TriggerOperation triggerEvent) {
        String objName  = objectName.remove('__c').remove('__e').remove('_');
        String event = String.valueOf(triggerEvent);
        String key = objName + '-' + event;
        //String key = event;
        Type t = Type.forName(objName + 'TriggerHandler');
        ITriggerHandler handler = (ITriggerHandler)t.newInstance();

        if (tc.containsKey(key)) {
            tc.get(key).execution++;
        } else {
            tc.put(key, new TriggerContext(objName, triggerEvent));

            //check if update on same object occurs after an insert on the same object, if so, increment execution
            String afterInsertKey = objName + '-' + 'AFTER_INSERT';
            if (
                    (
                        (key != afterInsertKey && tc.containsKey(afterInsertKey)) 
                        || System.isFuture() 
                        || System.isQueueable()
                    ) 
                    && key.contains(objName) 
                    && key.contains('UPDATE')
                ){
                tc.get(key).execution++;        
            }

        }

        TriggerContext currentContext = tc.get(key);
        System.debug('~~~~ TriggerDispatcher::Run: tc.get('+key+') = ' + tc.get(key));

        // Check to see if the trigger has been disabled. If it has, return
        if(handler.IsDisabled())
            return;
  
        // Detect the current trigger context and fire the relevant methods on the trigger handler:
    
        if (tc.get(key).execution == 0) {
            switch on tc.get(key).triggerEvent {
                when BEFORE_INSERT {
                    handler.beforeInsert(Trigger.new);
                } when BEFORE_UPDATE {
                    handler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
                } when BEFORE_DELETE {
                    handler.beforeDelete(Trigger.oldMap);
                } when AFTER_INSERT {
                    handler.afterInsert(Trigger.newMap);

                    //chain of responsibility queueable 
                    handler.afterSync(objectName, GeneralConstants.AFTER_INSERT, Trigger.newMap, null);
                } when AFTER_UPDATE {
                    handler.afterUpdate(Trigger.newMap, Trigger.oldMap);

                    //chain of responsibility queueable 
                    handler.afterSync(objectName, GeneralConstants.AFTER_UPDATE, Trigger.newMap, Trigger.oldMap);
                } when AFTER_DELETE {
                    handler.afterDelete(Trigger.oldMap);

                    //chain of responsibility queueable 
                    handler.afterSync(objectName, GeneralConstants.AFTER_DELETE, null, Trigger.oldMap);
                } when AFTER_UNDELETE {
                    handler.afterUndelete(Trigger.newMap);

                    //chain of responsibility queueable 
                    handler.afterSync(objectName, GeneralConstants.AFTER_UNDELETE, null, Trigger.oldMap);
                }
            }  
        } else {
            Integer execution = tc.get(key).execution;
            switch on tc.get(key).triggerEvent {
                when BEFORE_INSERT {
                    handler.beforeInsert(Trigger.new, execution);
                } when BEFORE_UPDATE {
                    handler.beforeUpdate(Trigger.newMap, Trigger.oldMap, execution);
                } when BEFORE_DELETE {
                    handler.beforeDelete(Trigger.oldMap, execution);
                } when AFTER_INSERT {
                    handler.afterInsert(Trigger.newMap, execution);
                } when AFTER_UPDATE {
                    handler.afterUpdate(Trigger.newMap, Trigger.oldMap, execution);
                } when AFTER_DELETE {
                    handler.afterDelete(Trigger.oldMap, execution);
                } when AFTER_UNDELETE {
                    handler.afterUndelete(Trigger.newMap, execution);
                }   
            }
        }
    }
  
    public class TriggerContext {
        public String handler;
        public System.TriggerOperation triggerEvent;
        public Integer execution = 0;

        TriggerContext(String handler, System.TriggerOperation triggerEvent) {
            this.handler = handler;
            this.triggerEvent = triggerEvent;
            this.execution = 0;
        }
    }
}