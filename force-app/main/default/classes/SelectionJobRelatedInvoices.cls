/**
 * @description       : This class selects jobs to update the related invoices
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-25-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionJobRelatedInvoices extends SelectionBase {
    private Map<Id, Set<String>> actionByJobId = new Map<Id, Set<String>>();
    
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for (WorkOrder job : (List<WorkOrder>)newById.values()) {
            WorkOrder oldJob = oldById != null && oldById.containsKey(job.Id) ? (WorkOrder)oldById.get(job.Id) : null;
            if (selectJob(job, oldJob)) {
                recIds.add(job.Id);
            }
        }
    }

    public Map<Id, Set<String>> getActionByJobId() {
        return actionByJobId;
    }

    @TestVisible
    private Boolean selectJob(WorkOrder newJob, WorkOrder oldJob) {
        Boolean result = false;

        //change in accounts
        //refactor from process builder Job_Updates: D - Account Changed => A - Update on Account for Bolt Invoices
        if (oldJob != null && newJob != null && newJob.AccountId != oldJob.AccountId && newJob.CreatedById != GeneralConstants.USER_ID_SYSTEM_ADMIN) {
            actionByJobId.put(newJob.Id, new Set<String>());
            actionByJobId.get(newJob.Id).add(GeneralConstants.AFTER_UPDATE);
            result = true;
        }

        return result;
    }
}