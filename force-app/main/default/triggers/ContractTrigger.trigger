/**
 * @File Name          : ContractTrigger.trigger
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Arpit Vashishtha
 * @Last Modified On   : 10-23-2023
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/19/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
trigger ContractTrigger on Contract (before insert, after insert, before update, after update, after delete, after undelete) {
	TriggerDispatcher.Run('Contract', Trigger.operationType);
}