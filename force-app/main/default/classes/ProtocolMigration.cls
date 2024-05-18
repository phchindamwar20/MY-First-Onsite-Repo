/**
 * @description       : Updates protocols
**/

global without sharing class ProtocolMigration implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Protocols_ACM_Testing__c, Protocols_Adjusters__c, Protocols_Billing__c, Protocols_Broker__c, Protocols_DFRs__c, Protocols_Portal__c, Protocols_Pricing__c, Protocols_Special_Concerns__c, Protocols_Work_Auth_PO__c, 
            Account.Protocols_ACM_Testing__c, Account.Protocols_Adjusters__c, Account.Protocols_Billing__c, Account.Protocols_Broker__c, Account.Protocols_DFRs__c, Account.Protocols_Portal__c, Account.Protocols_Pricing__c, Account.Protocols_Special_Concerns__c, Account.Protocols_Work_Auth_PO__c FROM WorkOrder ORDER BY AccountId]);
    }

    global void execute(Database.BatchableContext BC, List<WorkOrder> scope) {
        List<WorkOrder> jobLst = new List<WorkOrder>();

        for (WorkOrder job : scope) {
            if (String.isBlank(job.Protocols_ACM_Testing__c) &&
                String.isBlank(job.Protocols_Adjusters__c) &&
                String.isBlank(job.Protocols_Billing__c) &&
                String.isBlank(job.Protocols_Broker__c) &&
                String.isBlank(job.Protocols_DFRs__c) &&
                String.isBlank(job.Protocols_Portal__c) &&
                String.isBlank(job.Protocols_Pricing__c) &&
                String.isBlank(job.Protocols_Special_Concerns__c) &&
                String.isBlank(job.Protocols_Work_Auth_PO__c)) {
                    jobLst.add(new WorkOrder(Id=job.Id, 
                        Protocols_ACM_Testing__c=job.Account.Protocols_ACM_Testing__c,
                        Protocols_Adjusters__c=job.Account.Protocols_Adjusters__c,
                        Protocols_Billing__c=job.Account.Protocols_Billing__c,
                        Protocols_Broker__c=job.Account.Protocols_Broker__c,
                        Protocols_DFRs__c=job.Account.Protocols_DFRs__c,
                        Protocols_Portal__c=job.Account.Protocols_Portal__c,
                        Protocols_Pricing__c=job.Account.Protocols_Pricing__c,
                        Protocols_Special_Concerns__c=job.Account.Protocols_Special_Concerns__c,
                        Protocols_Work_Auth_PO__c=job.Account.Protocols_Work_Auth_PO__c));
                }
        }

        update jobLst;
    }

    global void finish (Database.BatchableContext BC) {

    } 
}