/**
 * @File Name          : AccountTrigger.trigger
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 4/15/2020, 10:41:11 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/15/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
trigger AccountTrigger on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerDispatcher.Run('Account', Trigger.operationType);
}