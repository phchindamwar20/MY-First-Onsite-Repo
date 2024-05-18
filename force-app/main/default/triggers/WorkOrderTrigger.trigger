/**
 * @File Name          : WorkOrderTrigger.trigger
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 08-15-2023
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/19/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
trigger WorkOrderTrigger on WorkOrder (before insert, after insert, before update, after update, after delete, after undelete) {
    TriggerDispatcher.Run('WorkOrder', Trigger.operationType);
}