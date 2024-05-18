/**
 * @description       : 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 07-11-2023
 * @last modified by  : Terri Jiles
**/
trigger FileLinkServiceEventTrigger on FileLinkServiceEvent__e (after insert) {
    TriggerDispatcher.Run('FileLinkServiceEvent__e', Trigger.operationType);
}