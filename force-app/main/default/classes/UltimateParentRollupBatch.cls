/**
 * @description       : This is the batch class that allows for initially calculating the ultimate parent for all accounts with the parent and account record types
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : Terri Jiles
**/
global without sharing class UltimateParentRollupBatch implements Database.Batchable<sObject> {
    private Set<String> recordTypeNames = new Set<String>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        recordTypeNames.add(BoltConstants.RT_ACC_PARENT);
        recordTypeNames.add(BoltConstants.RT_ACC_ACCOUNT);

        return Database.getQueryLocator([SELECT Id, ParentId FROM Account WHERE RecordType.DeveloperName IN:recordTypeNames ORDER BY ParentId]);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        Map<Id, Account> newAccById = new Map<Id, Account>(scope);
        UltimateParentRollupService uprs = new UltimateParentRollupService();
        Set<Id> ids = uprs.setUltimateParent(newAccById.keySet());
    }

    global void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            String query = 'SELECT Id, ParentId FROM Account WHERE RecordType.DeveloperName = \'' + GeneralConstants.RT_ACC_ACCOUNT + '\' ORDER BY ParentId';
            BoltCalloutBatch accountCallout = new BoltCalloutBatch(BoltConstants.WS_BOLT_ACCOUNT, query);
            Id result = Database.executeBatch(accountCallout, 200);
        }
    }
}