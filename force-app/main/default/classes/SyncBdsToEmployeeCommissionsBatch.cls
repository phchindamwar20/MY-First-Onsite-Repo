/**
 * @description       : STAR-6264 This batch syncs Sales Commissionable BDs=>ECs for job commissions that are NOT paid, where all the existing ECs are Sales Commissionable Users and ECs are NOT paid and EC count <= 3
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-02-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class SyncBdsToEmployeeCommissionsBatch extends ApexJobSettingsService implements Database.Batchable<SObject> {
    private static DataAdminService dataAdminConfig = new DataAdminService();

    public SyncBdsToEmployeeCommissionsBatch() {
        setJobName('SyncBdsToEmployeeCommissionsBatch');
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        //turn off everything except for flow... flow is needed for the batch to propertly sync BDs to ECs
        dataAdminConfig.modifyDataAdmin(true, true, true, true, false);

        Set<String> statuses = new Set<String>();
        statuses.add(SalesIncentivePlanConstants.JC_STATUS_OPEN);

        //get only open job commissions with no custom splits
        return Database.getQueryLocator([SELECT Id FROM Job_Commission__c WHERE Commission_Status__c IN : statuses AND Custom_Splits__c=:SalesIncentivePlanConstants.NO]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        CommissionService comServ = new CommissionService();
        comServ.syncBdECs((List<Job_Commission__c>)scope);
    }

    public void finish (Database.BatchableContext bc) {
        //revert to prior data admin settings
        dataAdminConfig.reverDataAdmin();
    }
}