/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-09-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger ContentDocumentTrigger on ContentDocument (before delete, after delete, after undelete) {
    TriggerDispatcher.Run('ContentDocument', Trigger.operationType);
}