/**
 * @description       : This is a batch class that allows an admin to run the file link service in a one time run
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-04-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class FileLinkBatch implements Database.Batchable<SObject> {
    private String objectApiName = 'Account';

    public FileLinkBatch() {}

    public FileLinkBatch(String objectApiName) {
        this.objectApiName=objectApiName;
    }
    
    public Database.QueryLocator start (Database.BatchableContext bc) {
        String query = 'SELECT Id FROM ' + objectApiName;
        return Database.getQueryLocator(query);
    }
    
    public void execute (Database.BatchableContext bc, List<SObject> scope){
        Set<Id> recIds = new Set<Id>();
        for(SObject rec : (List<SObject>)scope){
            recIds.add(rec.Id);
        }

        List<ContentDocumentLink> cdlLst = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN: recIds];

        if (!cdlLst.isEmpty()) {
            FileLinkService.buildFileLinks(cdlLst);
        }
    }
    
    public void finish(Database.BatchableContext bc){}
}