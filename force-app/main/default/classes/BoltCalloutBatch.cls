/**
 * @description       : The purpose of this is to call Bolt via batch for mass processing of records
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : Terri Jiles
**/
global without sharing class BoltCalloutBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private String endpointName;
    private String query;

    public BoltCalloutBatch(String endpointName, String query) {
        this.endpointName=endpointName;
        this.query=query;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('~~~~ BoltCalloutBatch::start: query - ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        Map<Id, SObject> recById = new Map<Id, SObject>(scope);
        BoltCallouts.sendRecords(recById.keySet(), BoltConstants.SF_TO_BOLT, endpointName);
    }

    global void finish(Database.BatchableContext BC) {
        
    }
}