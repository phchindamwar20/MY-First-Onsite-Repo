/**
 * @description       : This is the selection criteria utlized to select records for the SF=>Icertis CWA Jobs callout
 *                      STAR-6088 - needs to handle sending a PUT call to the iCertis User service, if there is an update that isn't a change in the email
 * @author            : Arpit Vashishtha
 * @group             : 
 * @last modified on  : 01-08-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionICCWAJobs extends SelectionBase{  


    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for(Id jobId : newById.keySet()) {
            WorkOrder newJob = (WorkOrder)newById.get(jobId);
            WorkOrder oldJob = oldById != null && oldById.containsKey(jobId) ? (WorkOrder)oldById.get(jobId) : null;
            
            if (selectJob(newJob, oldJob)) {
                recIds.add(jobId);
            }
        }
    }
    
    @TestVisible
    private Boolean selectJob(WorkOrder newJob, WorkOrder oldJob) {
        Boolean isSelectJob = false;

        if(oldJob != null && newJob.IC_Bolt_CWA__c) {
            if ((oldJob.IC_Signatory_Email__c != newJob.IC_Signatory_Email__c) 
                || (oldJob.IC_External_First_Name__c != newJob.IC_External_First_Name__c)
                || (oldJob.IC_External_Last_Name__c != newJob.IC_External_Last_Name__c)
                || (oldJob.IC_Property_Owner_Address_Different__c != newJob.IC_Property_Owner_Address_Different__c)
                || (oldJob.IC_Property_Owner_Name_Different__c != newJob.IC_Property_Owner_Name_Different__c)
                || (oldJob.IC_Property_Owner_Address__c != newJob.IC_Property_Owner_Address__c)
                || (oldJob.IC_Property_Owner_Name__c != newJob.IC_Property_Owner_Name__c)) {
                isSelectJob = true;
            } 
        }     
        return isSelectJob;  
    }
}