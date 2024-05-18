/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-21-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class ServiceTerritoryTriggerHandler extends TriggerHandlerBase {
    public override void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Id jobId = System.enqueueJob(new ServiceTerritoryJobSharingService((Map<Id, ServiceTerritory>)oldItems, (Map<Id, ServiceTerritory>)newItems));
        System.debug('~~~~ ServiceTerritoryTriggerHandler::afterUpdate: jobID - ' + jobId);
    }
}