/**
 * @description       : This selects records to create job sharing records.  It is refactored from Job_Updates process builder
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-21-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionJobSharing extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for (WorkOrder newJob : (List<WorkOrder>)newById.values()) {
            WorkOrder oldJob = oldById != null && oldById.containsKey(newJob.Id) ? (WorkOrder)oldById.get(newJob.Id) : null;
            if (selectJob(newJob, oldJob)) {
                recIds.add(newJob.Id);
            }
        }
    }

    @testVisible
    private Boolean selectJob(WorkOrder newJob, WorkOrder oldJob) {
        Boolean isSelectJob = false;
        if (newJob != null && oldJob == null) {
            isSelectJob = true;
        } else if (newJob != null && oldJob != null) {
            if (newJob.OwnerId != oldJob.OwnerId) {
                isSelectJob = true;
            } else if (newJob.AccountId != oldJob.AccountId) {
                isSelectJob = true;
            }
        }

        return isSelectJob;
    }
}