/**
 * @File Name          : JobSharingTriggerHandler.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 4/23/2020, 11:01:55 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/19/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public without sharing class JobSharingTriggerHandler extends TriggerHandlerBase {
    public JobSharingTriggerHandler() {}

    public override void beforeInsert(SObject[] newItems) {
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> userIdsToShare = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();

        //get user ids from job sharing
        for (Job_Sharing__c js : (List<Job_Sharing__c>)newItems) {
            ownerIds.add(js.User__c);
            jobIds.add(js.Job__c);
        }
        
        Map<Id, WorkOrder> jobById = new Map<Id, WorkOrder>([SELECT Id, OwnerId  FROM WorkOrder WHERE Id In: jobIds]);

        //Need to get Owners which could be users or group
        for (WorkOrder job : jobById.values()) {
            if (String.valueOf(job.OwnerId).startsWith('005') )
                ownerIds.add(job.OwnerId);
        }


        System.debug('~~~~~ ownerIds: ' + ownerIds);

        //get active users that have access to the job object
        for (PermissionSetAssignment psa : [SELECT AssigneeId FROM PermissionSetAssignment 
                                            WHERE Assignee.IsActive=true 
                                                AND AssigneeId IN (SELECT Id FROM User WHERE UserType='Standard' OR Profile.Name LIKE 'Customer Community Plus%')
                                                AND AssigneeId IN: ownerIds
                                                AND PermissionSetId IN (SELECT ParentId 
                                                                        FROM ObjectPermissions 
                                                                        WHERE SObjectType = 'WorkOrder' AND PermissionsRead = true)]) {
            userIdsToShare.add(psa.AssigneeId);
        }  
        System.debug('~~~~~ userIdsToShare: ' + userIdsToShare);



        for (Job_Sharing__c js : (List<Job_Sharing__c>)newItems) {
            if (!userIdsToShare.contains(js.User__c)) {
                js.addError('The user must be active AND have at least read access to the job object.  Please check the user profile and active status.  Chatter Free Users are not able to see jobs');
            } else if (jobById.containsKey(js.Job__c) && !userIdsToShare.contains(jobById.get(js.Job__c).OwnerID)) {
                js.addError('The job associated with this job sharing record has an inactive user.  Please change the owner of the job to an active user.  Then try creating this job sharing record.');
            }
        }
    }

    public override void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        for (Job_Sharing__c js : (List<Job_Sharing__c>)newItems.values()) {
            js.addError('You cannot update a Job Sharing record.  Please delete and create a new Job Sharing record');
        }
    }   

    public override void afterInsert(Map<Id, SObject> newItems) {
        JobSharingService jobService = new JobSharingService();
        jobService.shareInsertedJobSharing((Map<Id, Job_Sharing__c>)newItems);
    }

    public override void afterDelete(Map<Id, SObject> oldItems) {
        JobSharingService jobService = new JobSharingService();
        jobService.unshareDeletedJobSharing((Map<Id, Job_Sharing__c>)oldItems);        
    }

    public class JobSharingTriggerHandlerException extends Exception {}
}