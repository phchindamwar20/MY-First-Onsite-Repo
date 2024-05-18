/**
 * @File Name          : JobTriggerHandler.cls
 * @Description        : 1. On creation of a new job, If job is associated with a bolt branch, sets the Job Integrate with Bolt = true
 *                       2. On creation of a new job, prevents a user from cloning a job associated with a bolt branch
 *                       3. On create or update of a job, replaces the owner if the owner is inactive
 *                              - IF the branch associated with the job has a general manager who is an active user, then the job's owner is set as that user
 *                              - ELSE IF It takes an active user from the Job Sharing custom metadata type and sets the job's owner from it
 *                       4. Shares jobs with KTMs and job shares on creation of new job or when owner on job changes
 *                       5. Clears out duplicate matching when the duplicate job is deleted from Salesforce.  This logic needs to go away when the Sage integration is disconnected
 *                       6. Queueable chain of responsibility jobs associated with the account trigger is built directly into the trigger framework.  If you
 *                          want to see the potential jobs chained together, look at the Execution Item Configuration custom metadata for account and the corresponding trigger event
 * 
 * @TODOS              : 
 * @Author             : Terri Jiles
 * @Group              : 
 * @Last Modified By   : Kiran K (CFS)
 * @Last Modified On   : 05-07-2024
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    2/19/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 * 2.0    05/07/2024  Kiran K (CFS)                 STAR-6569 removed unused Sage Fields
 * 2.0    05/10/2024  Kiran K (CFS)                 STAR-6591 remove default Ownership
*****************************************************************************************************
**/
public without sharing virtual class WorkOrderTriggerHandler extends TriggerHandlerBase{

    public static Boolean isDefaultOverride = false;
    private DataAdmin__c dataAdminBypass = DataAdmin__c.getInstance();
 
    //@TestVisible private static List<String> defaultOwnersLst = getDefaultOwners();
    private static Set<Id> boltBranchIds = new Set<Id>();
    @TestVisible

    public override void beforeInsert(SObject[] newItems) {
        List<WorkOrder> jobLst = (List<WorkOrder>)newItems;
        boltBranchIds = getBoltBranches(jobLst);
        //Bolt Items
        setBoltInfoOnJob(jobLst, null);          
        //replaceOwner(jobLst);
        //setBefores((List<WorkOrder>)newItems,  null);
    }

    public override void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        List<WorkOrder> jobLst = (List<WorkOrder>)newItems.values();
        boltBranchIds = getBoltBranches(jobLst);
        //replaceOwner(jobLst);
        //setBefores((List<WorkOrder>)newItems.values(),  (Map<Id, WorkOrder>)oldItems);
        //
        //Bolt Items
        setBoltInfoOnJob(jobLst, (Map<Id,WorkOrder>)oldItems);
    }

    public override void afterInsert(Map<Id, SObject> newItems) {
        Map<Id, WorkOrder> mapNewJobById = (Map<Id, WorkOrder>)newItems;
                
        JobSharingService jobService = new JobSharingService();
        jobService.shareUnShareJobChanges(mapNewJobById, null); 
    }


    public override void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, WorkOrder> mapNewJobById = (Map<Id, WorkOrder>)newItems; 
        Map<Id, WorkOrder> mapOldJobById = (Map<Id, WorkOrder>)oldItems; 

        JobSharingService jobService = new JobSharingService();
        jobService.deleteJobSharingRecsOfNewJobOwners(mapNewJobById, mapOldJobById); //STAR-4771
        jobService.shareUnShareJobChanges(mapNewJobById, mapOldJobById); 
    }    

    public override void afterDelete(Map<Id, SObject> oldItems) {
        Map<Id, WorkOrder> mapOldJobById = (Map<Id, WorkOrder>)oldItems;

    }   

    public static Set<Id> getBoltBranches(List<WorkOrder> newJobLst) {
        Set<Id> branchIds = new Set<Id>();

        if (boltBranchIds.isEmpty()) {
            for (WorkOrder job: newJobLst ) {
                if (!String.isBlank(job.ServiceTerritoryId)) {
                    branchIds.add(job.ServiceTerritoryId);
                }
            }

            for (ServiceTerritory branch : [SELECT Id FROM ServiceTerritory WHERE Id In: branchIds AND Integrate_With_Bolt__c=true]){
                boltBranchIds.add(branch.Id);
            }
        }
        return boltBranchIds;
    }  
    public override Boolean IsDisabled() {
        if (!isDefaultOverride) {
            try {
                DataAdmin__c bypass = DataAdmin__c.getInstance();
                return bypass.TurnOffTrigger__c;
            }
            // if custom setting doesn't exists, don't disable 
            catch (Exception e) {
                return false;
            }    
        } else {
            return false;
        }            
    }   
    
    private static void setBoltInfoOnJob(List<WorkOrder> newJobLst, Map<Id,WorkOrder> oldJobById) {      
        for (WorkOrder job : newJobLst) {
            //set as a bolt job only on create if job is associated with a bolt branch
            if ((oldJobById==null || oldJObById.isEmpty()) && boltBranchIds.contains(job.ServiceTerritoryId)) {
                job.Integrate_With_Bolt__c=true;
            }

            System.debug('~~~~ JobTriggerHandler::setBoltInfoOnJob: job isClone - ' + job.isClone() + ', boltBranchIds - ' + boltBranchIds.contains(job.ServiceTerritoryId) + ', Job Number - ' + job.Job_Number_Claim__c );
            //Bolt validations
            if( job.isClone() && boltBranchIds.contains(job.ServiceTerritoryId) && oldJobById == null) {
            //if(job.isClone() && boltBranchIds.contains(job.ServiceTerritoryId) && job.Job_Number_Claim__c != null && !String.isEmpty(job.Job_Number_Claim__c) && oldJobById == null) {
                job.addError(label.BOLT_EXCEPTION_CLONE);
            }

        }
    }
    
    
    /*private static void autoCreateICertisCWAContract(Map<Id, WorkOrder> newJobById, Map<Id, WorkOrder> oldJobById) {
    	if(!IcertisCLM.ICM_AutoCreateTriggerHandler.firstcall) {
            IcertisCLM.ICM_AutoCreateTriggerHandler.firstcall = true; 
            List<WorkOrder> cwaBoltJobLst = new List<WorkOrder>();

            for (WorkOrder newRec : newJobById.values()) {
                WorkOrder oldRec = oldJobById.get(newRec.Id);
                if (oldRec != null && oldRec.Icm_Auto_Create_context__c == newRec.Icm_Auto_Create_Context__c) {
                    cwaBoltJobLst.add(newRec);
                }
            }
            if(!cwaBoltJobLst.isEmpty()) {
                IcertisCLM.ICM_AutoCreateTriggerHandler.onAfterInsertorUpdate(cwaBoltJobLst);
            }
        }
	}*/
        
    /*public static Set<Id> getCWAJob(Map<Id, WorkOrder> newJobMap, Map<Id, WorkOrder> oldJobMap) {
        Set<Id> jobIdSet = new Set<Id>();
        for(Id jobId : newJobMap.keySet()) {
            if(oldJobMap != null && oldJobMap.containsKey(jobId) && newJobMap.get(jobId).IC_Bolt_CWA__c && oldJobMap.get(jobId).IC_Signatory_Email__c != newJobMap.get(jobId).IC_Signatory_Email__c) {
                jobIdSet.add(jobId);
            } else if(oldJobMap == null && newJobMap.get(jobId).IC_Bolt_CWA__c && String.isNotBlank(newJobMap.get(jobId).IC_Signatory_Email__c)) {
                jobIdSet.add(jobId);
            }//End of if(newJobMap.get(jobId).IC_Bolt_CWA__c)
        }//End of for(Id jobId : newJobMap.keySet())
        return jobIdSet;
    }//End of getCWAJob method
	*/

}