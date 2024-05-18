/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-20-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class ServiceTerritoryJobSharingService implements Queueable{
    private Map<Id, ServiceTerritory> newMap = new Map<Id, ServiceTerritory>();
    private Map<Id, ServiceTerritory> oldMap = new Map<Id, ServiceTerritory>();

    public ServiceTerritoryJobSharingService(Map<Id, ServiceTerritory> oldMap, Map<Id, ServiceTerritory> newMap) {
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public void execute(QueueableContext context) {
        JobSharingService js = new JobSharingService();
        js.updateServTerrGmJobSharing(oldMap, newMap);
    }
}