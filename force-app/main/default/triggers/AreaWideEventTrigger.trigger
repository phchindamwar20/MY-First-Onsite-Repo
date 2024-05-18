/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-09-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger AreaWideEventTrigger on Area_Wide_Event__c (after insert, after update) {
    TriggerDispatcher.Run('Area_Wide_Event__c', Trigger.operationType);
}