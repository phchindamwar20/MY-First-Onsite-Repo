/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-21-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger ServiceTerritoryTrigger on ServiceTerritory (after update) {
    TriggerDispatcher.Run('ServiceTerritory', Trigger.operationType);
}