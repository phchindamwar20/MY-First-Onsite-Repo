/**
 * @description       : This is the selection criteria for determine what job records to update related contacts
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-21-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionJobRelatedContacts extends SelectionBase {
    private Map<Id, Set<String>> actionByJobId = new Map<Id, Set<String>>();
    
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for (WorkOrder job : (List<WorkOrder>)newById.values()) {
            WorkOrder oldJob = oldById != null && oldById.containsKey(job.Id) ? (WorkOrder)oldById.get(job.Id) : null;
            if (selectJob(job, oldJob)) {
                recIds.add(job.Id);
                actionByJobId.put(job.Id, new Set<String>());
                actionByJobId.get(job.Id).add(GeneralConstants.AFTER_INSERT);
            }
        }
    }

    public Map<Id, Set<String>>getActionByJobId() {
        return actionByJobId;
    }

    @TestVisible
    private Boolean selectJob(WorkOrder newJob, WorkOrder oldJob) {
        Boolean result = false;

        if (oldJob == null && newJob != null && newJob.Referred_By__c != null) {
            result = true;
        }

        return result;
    }
}