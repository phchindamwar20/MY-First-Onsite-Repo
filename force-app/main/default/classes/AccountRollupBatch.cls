/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-12-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   11-20-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public without sharing class AccountRollupBatch implements Database.Batchable<sObject> {
    private Integer count = 1;

    public AccountRollupBatch(){}
    public AccountRollupBatch(Integer count) {
        this.count=count;
    }
    

   
    public Database.QueryLocator start(Database.BatchableContext BC){
        if (count == 1) {
            return Database.getQueryLocator([SELECT Id, Name, ParentId, Last_12_Months_Contracted_Sales__c, Last_12_Months_Contracted_Sales_Children__c, Last_12_Months_Contracted_Sales_All__c, Last_12_Months_Number_of_Jobs__c, Last_12_Months_Number_of_Jobs_Children__c, Last_12_Months_Number_of_Jobs_All__c, Tier__c, Tier_Override__c, Last_Modified_Tier_By__c, Last_Date_Tier_Set__c, RecordTypeId, RecordType.DeveloperName FROM Account WHERE RecordType.DeveloperName In ('Parent', 'Account')]);
        } else {
            return Database.getQueryLocator([SELECT Id, Name, ParentId FROM Account WHERE RecordType.DeveloperName IN ('Account', 'Parent')]);
        }
    }
   
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        if (count==1) {
            AccountLast12MonthsRollupService.rollUpJobsOnAccounts((List<Account>)scope);
        } else {
            AccountLifetimeRollupService.rollUpJobsOnAccounts((List<Account>)scope);
        }
    }
   
    public void finish(Database.BatchableContext BC){
        if (count<2) {
            AccountRollupBatch b = new AccountRollupBatch(count+1);
            database.executeBatch(b);
        }
    }
}