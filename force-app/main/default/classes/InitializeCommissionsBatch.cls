/**
 * @description       : STAR-6037 This batch class creates commission records for jobs that don't have related job commissions related to it and it isn't related to a job commission
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-26-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class InitializeCommissionsBatch implements Database.Batchable<sObject> {
    Datetime createDate = Datetime.newInstanceGmt(2024, 1, 1);
    public InitializeCommissionsBatch() {}

    public InitializeCommissionsBatch(Datetime createDate) {
        this.createDate = createDate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM WorkOrder WHERE CreatedDate >=: createDate]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        /*List<WorkOrder> jobLst = new List<WorkOrder>();
        for (WorkOrder job : [SELECT Id, Job_Commission__c, (SELECT Id FROM Job_Commissions__r) FROM WorkOrder WHERE Id IN: scope]) {
            if (job.Job_Commission__c == null && job.Job_Commissions__r.isEmpty()) {
                jobLst.add(job);
            }
        }*/

        CommissionService comSer = new CommissionService();
        comSer.createJobCommissions((List<WorkOrder>)scope);
    }

    public void finish(Database.BatchableContext bc) {}
}