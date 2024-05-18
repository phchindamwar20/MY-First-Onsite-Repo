/**
 * @description       : This is the selection criteria for updating job's go/no go
 *                         Open job statuses are maintained in a custom metadata type Open Job Statues so an admin can maintain that
 *                         if the job statues changes without getting a developer involved
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionGoNoGoJob extends SelectionBase{
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        //need to re-query this because I am comparing a formula field (Go No Go) with a text field (Go No Gox)
        //this way and admin can maintain the formula for the logic for (Go No Go) without getting a developer involved
        //we don't need to check the 'old' record because of this
        //putthing this in a Map query instead of within the loop reduce chances of CPU Timeout limit.
        //note:  putting in map, increases heap space but because this is not static, it should clear out of the heap when the control exits this method
        //note:  
        Map<Id, WorkOrder> jobById = new Map<Id, WorkOrder>([SELECT Id, Go_No_Go__c, Go_No_Gox__c FROM WorkOrder WHERE Id IN: newById.keySet() AND Status IN: GeneralConstants.OPEN_JOB_STATUSES]);
        for (WorkOrder newJob : jobById.values()) {            
            if (isSelectionCriteriaMet(newJob)) {
                recIds.add(newJob.Id);
            }
        }
    }  
    
    @TestVisible
    private Boolean isSelectionCriteriaMet(WorkOrder newJob) {
        Boolean isRecForProcessing = false; 
        if (newJob.Go_No_Go__c != newJob.Go_No_Gox__c) {
            isRecForProcessing = true;
        }

        return isRecForProcessing;
    }
}