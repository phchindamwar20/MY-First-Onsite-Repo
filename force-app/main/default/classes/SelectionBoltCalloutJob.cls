/**
 * @description       : This is the selection class for making callout to Bolt Jobs
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionBoltCalloutJob extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        //Check Bolt hierarchy custom setting to see if user is allowed to send records to bolt, but only for Updates!
        Boolean isNotBoltSyncUser = BoltCallouts.integrateWithBolt();
        
        for (WorkOrder job : (List<WorkOrder>)newById.values()) {
            //System.debug('~~~~ SelectionBoltCalloutAccount::getRecordsToProcess: acc - ' + acc);
            
            WorkOrder oldJob = oldById != null && oldById.containsKey(job.Id) ? (WorkOrder)oldById.get(job.Id) : null;
            //System.debug('~~~~ SelectionBoltCalloutAccount::getRecordsToProcess: oldAcc - ' + oldAcc); 

            if (isBoltJob(isNotBoltSyncUser, job, oldJob)) {
                recIds.add(job.Id);
            }
        }
    }

    @TestVisible
    private Boolean isBoltJob(Boolean isNotBoltSyncUser, WorkOrder newJob, WorkOrder oldJob) {
        Boolean isBoltJob = false;

        //the job must be marked as a bolt job where Integrate with Bolt = true
        if (newJob != null && newJob.Integrate_with_Bolt__c) {
            if (oldJob == null) {
                //This is a new job and should be sent to bolt
                //STAR-4806 - When Bolt creates a job in Salesforce, send the New Job Back to Bolt 
                //so that Bolt will have the job protocols saved to it 
                //this change should not impact the sandboxTestData Script, given it sets data admin to turn off the trigger 
                isBoltJob = true;
            } else if (isNotBoltSyncUser && oldJob != null && BoltCallouts.isChangeInRecord(newJob, oldJob, BoltConstants.WS_BOLT_JOB)){
                //This is an update to an job that is already integrated with bolt.  We only send the updated job to Bolt if a field that we are integrating with has changed.
                isBoltJob = true;
            }    
        }  
        
        return isBoltJob;
    }
}