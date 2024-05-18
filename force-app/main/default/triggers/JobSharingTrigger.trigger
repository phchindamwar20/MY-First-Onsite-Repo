/**
 * @File Name          : JobSharingTrigger.trigger
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 3/3/2020, 12:38:26 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/19/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
trigger JobSharingTrigger on Job_Sharing__c (before insert, after insert, before update, after delete) {
    TriggerDispatcher.Run('Job_Sharing__c', Trigger.operationType);
}