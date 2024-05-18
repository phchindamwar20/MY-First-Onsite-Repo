/**
 * @File Name          : JobSharingService.cls
 * @Description        : This logic handles all job sharing logic for sharing jobs with KTMs, a job's Branch's General Manager, related Job Sharing, and re-shares when the Owner is changed
 * @Author             : Terri Jiles
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 09-21-2023
 * @Modification Log   :  Change Construction Manager label and API name to  RM/CM/OM
 * Ver       Date            Author      		    Modification
 * 1.0      2/18/2020        TJiles                 
 * 2.0      3/6/2020         TJiles                 STAR-613   
 * 3.0    30/03/2021   Praveenbabu M                STAR-2199
**/
public without sharing class JobSharingService {

    private Map<Id, Id> oldOpportunityIdByJobId = new Map<Id, Id>();      
    private Map<Id, Set<Id>> newUserIdsToJobIds = new Map<Id, Set<Id>>();
    private Map<Id, Set<Id>> oldUserIdsToJobIds = new Map<Id, Set<Id>>();    
    private Map<Id, WorkOrder> newJobById = new Map<Id, WorkOrder>(); 
    private Map<Id, WorkOrder> oldJobById = new Map<Id, WorkOrder>();
    private Set<Id> userIdsToShare = new Set<Id>();
    private Set<Id> userIds = new Set<Id>();
    private List<WorkOrderShare> jobSharesToDeleteLst = new List<WorkOrderShare>();
    private List<WorkOrderShare> jobSharesToInsertLst = new List<WorkOrderShare>();

    //used in jobs trigger
    public void shareUnShareJobChanges(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap) {           
        newJobById = newMap;
        oldJobById = oldMap;

        getJobChanges();
        getJobSharing(); 
        getValidUserIdsToKey(); 
        filterOutInvalidUserIds();     
        rectifyShareChanges();
        
        deleteOldJobShares();
        System.debug('~~~~ JobSharingService::shareUnShareJobChanges: jobSharesToDeleteLst size ' + jobSharesToDeleteLst.size() + ' values ' + jobSharesToDeleteLst);
        if (!jobSharesToDeleteLst.isEmpty()) delete jobSharesToDeleteLst;
        
        createNewJobShares();
        System.debug('~~~~ JobSharingService::shareUnShareJobChanges: jobSharesToInsertLst size ' + jobSharesToInsertLst.size() + ' values ' + jobSharesToInsertLst);
        if (!jobSharesToInsertLst.isEmpty()) insert jobSharesToInsertLst;         
    }

    //used in Job Sharing trigger
    public void shareInsertedJobSharing(Map<Id, Job_Sharing__c> newMap) {
        //Get existing jobs and user
        for (Job_Sharing__c js : newMap.values()) {
            if (!newUserIdsToJobIds.containsKey(js.Job__c)) {
                newUserIdsToJobIds.put(js.Job__c, new Set<Id>());
            } 
            newUserIdsToJobIds.get(js.Job__c).add(js.User__c);
            userIds.add(js.User__c);
        }

        getValidUserIdsToKey(); 
        filterOutInvalidUserIds(); 
        for (WorkOrder job : [SELECT Id, OwnerId, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c, BD_Account_Manager_3__c, 
		                        //  STAR-2199
		                            RM_CM_OM__c,  Regional_Coordinator__c, 
                                //STAR-4435
                                    Senior_Project_Manager__c,
                                //  STAR-2754 Service Territory General Manager
                                    ServiceTerritoryId, ServiceTerritory.General_Manager__c
                                    FROM WorkOrder WHERE Id In: newUserIdsToJobIds.keySet()]) {
            Set<Id> removeUserIds = new Set<Id>();
            removeUserIds.add(job.BD_Account_Manager__c); removeUserIds.add(job.Project_Director__c); removeUserIds.add(job.Project_Manager__c);
            removeUserIds.add(job.AP_Approver__c); 
			
			removeUserIds.add(job.BD_Account_Manager_2__c);
			 //  STAR-2199
			removeUserIds.add(job.RM_CM_OM__c); removeUserIds.add(job.Regional_Coordinator__c);
            removeUserIds.add(job.BD_Account_Manager_3__c);

            //STAR-4435
            removeUserIds.add(job.Senior_Project_Manager__c);

            
            //  STAR-2754
            if (job.ServiceTerritoryId != null && job.ServiceTerritory.General_Manager__c != null) {
                removeUserIds.add(job.ServiceTerritory.General_Manager__c);
            }

            newUserIdsToJobIds.get(job.Id).removeAll(removeUserIds);
        }

        createNewJobShares();
        if (!jobSharesToInsertLst.isEmpty()) insert jobSharesToInsertLst;
    }

    //used in job sharing trigger
    public void unshareDeletedJobSharing(Map<Id, Job_Sharing__c> oldMap) {
        //Get existing jobs and user
        for (Job_Sharing__c js : oldMap.values()) {
            if (!oldUserIdsToJobIds.containsKey(js.Job__c)) {
                oldUserIdsToJobIds.put(js.Job__c, new Set<Id>());
            } 
            oldUserIdsToJobIds.get(js.Job__c).add(js.User__c);
        }
		    //  STAR-2199     //  STAR-2754 - Service Territory General Manager
            // STAR-4435 Senior Project Manager
        for (WorkOrder job : [SELECT Id, OwnerId, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c,
		                                RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c FROM WorkOrder WHERE Id In: oldUserIdsToJobIds.keySet()]) {
            Set<Id> removeUserIds = new Set<Id>();
            removeUserIds.add(job.BD_Account_Manager__c); removeUserIds.add(job.Project_Director__c); removeUserIds.add(job.Project_Manager__c);
            removeUserIds.add(job.AP_Approver__c);  removeUserIds.add(job.BD_Account_Manager_2__c); 
			 //  STAR-2199
			removeUserIds.add(job.RM_CM_OM__c);  removeUserIds.add(job.Regional_Coordinator__c); 
            removeUserIds.add(job.BD_Account_Manager_3__c);

            //STAR-4435
            removeUserIds.add(job.Senior_Project_Manager__c);

            //  STAR-2754
            if (job.ServiceTerritoryId != null && job.ServiceTerritory.General_Manager__c != null) {
                removeUserIds.add(job.ServiceTerritory.General_Manager__c);
            }

            oldUserIdsToJobIds.get(job.Id).removeAll(removeUserIds);
        }
        
        deleteOldJobShares();
        if (!jobSharesToDeleteLst.isEmpty()) delete jobSharesToDeleteLst;
    }   
    
    public void updateServTerrGmJobSharing(Map<Id, ServiceTerritory> oldMap, Map<Id, ServiceTerritory> newMap) {
        Set<Id> jobIds = new Set<Id>();
        Set<Id> stIds = new Set<Id>();
        //Get Service Territories with Change in General Manager
        for (ServiceTerritory st : newMap.values()) {
            if (st.General_Manager__c != oldMap.get(st.Id).General_Manager__c) {
                stIds.add(st.Id);
            }
        }
        //Get Jobs associated with Service Territory GM Changes, get ids and users
        for (WorkOrder job : [SELECT Id, OwnerId, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c, RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c FROM WorkOrder WHERE ServiceTerritoryId In: stIds]) {
            Set<Id> removeUserIds = new Set<Id>();
            removeUserIds.add(job.BD_Account_Manager__c); removeUserIds.add(job.Project_Director__c); removeUserIds.add(job.Project_Manager__c);
            removeUserIds.add(job.AP_Approver__c);  removeUserIds.add(job.BD_Account_Manager_2__c); 
			removeUserIds.add(job.RM_CM_OM__c);  removeUserIds.add(job.Regional_Coordinator__c); removeUserIds.add(job.BD_Account_Manager_3__c);
            //STAR-4435
            removeUserIds.add(job.Senior_Project_Manager__c);
            
            if (!oldUserIdsToJobIds.containsKey(job.Id)) {
                oldUserIdsToJobIds.put(job.Id, new Set<Id>());
            } 
            if (!newUserIdsToJobIds.containsKey(job.Id)) {
                newUserIdsToJobIds.put(job.Id, new Set<Id>());
            }             
            if (oldMap.containsKey(job.ServiceTerritoryId) && oldMap.get(job.ServiceTerritoryId).General_Manager__c != null) { oldUserIdsToJobIds.get(job.Id).add(oldMap.get(job.ServiceTerritoryId).General_Manager__c); }
            if (newMap.containsKey(job.ServiceTerritoryId) && newMap.get(job.ServiceTerritoryId).General_Manager__c != null) { newUserIdsToJobIds.get(job.Id).add(newMap.get(job.ServiceTerritoryId).General_Manager__c); }     
            oldUserIdsToJobIds.get(job.Id).removeAll(removeUserIds);
            newUserIdsToJobIds.get(job.Id).removeAll(removeUserIds);
            jobIds.add(job.Id);
            userIds.add(job.ServiceTerritory.General_Manager__c);
        }  
        //Get Job Sharing associating with Work Orders
        for (Job_Sharing__c js : [SELECT Id, User__c, Job__c FROM Job_Sharing__c WHERE Job__c IN: jobIds]){
            oldUserIdsToJobIds.get(js.Job__c).remove(js.User__c);
            newUserIdsToJobIds.get(js.Job__c).remove(js.User__c);
        }
        //validate and filter out invalid
        getValidUserIdsToKey(); 
        filterOutInvalidUserIds(); 
        //Delete Old Shares
        deleteOldJobShares();
        if (!jobSharesToDeleteLst.isEmpty()) delete jobSharesToDeleteLst;
        //Insert New Shares
        createNewJobShares();
        if (!jobSharesToInsertLst.isEmpty()) insert jobSharesToInsertLst;
    }

    private void getJobChanges() {
        Map<Id, ServiceTerritory> newServTerrById = getServiceTerritoryMap(newJobById.values());
        Map<Id, ServiceTerritory> oldServTerrById;
        if (oldJobById !=null) { 
            oldServTerrById = getServiceTerritoryMap(oldJobById.values());
        }
        for(Workorder jobRec : newJobById.values()){
            // if new job or change in ownership, opportunity or job assignments, then setup and remove old sharing
               //  STAR-2199
            if (oldJobById == null ||
                    ( jobRec.BD_Account_Manager__c != oldJobById.get(jobRec.Id).BD_Account_Manager__c ||
                      jobRec.Project_Director__c != oldJobById.get(jobRec.Id).Project_Director__c ||
                      jobRec.Project_Manager__c != oldJobById.get(jobRec.Id).Project_Manager__c ||
                      jobRec.AP_Approver__c != oldJobById.get(jobRec.Id).AP_Approver__c ||
                      jobRec.BD_Account_Manager_2__c != oldJobById.get(jobRec.Id).BD_Account_Manager_2__c ||
                      jobRec.RM_CM_OM__c != oldJobById.get(jobRec.Id).RM_CM_OM__c ||
                      jobRec.Regional_Coordinator__c != oldJobById.get(jobRec.Id).Regional_Coordinator__c ||
                      jobRec.OwnerId != oldJobById.get(jobRec.Id).OwnerId ||
                      jobRec.BD_Account_Manager_3__c != oldJobById.get(jobRec.Id).BD_Account_Manager_3__c  ||
                      jobRec.Senior_Project_Manager__c != oldJobById.get(jobRec.Id).Senior_Project_Manager__c ||
                      jobRec.ServiceTerritoryId != oldJobById.get(jobRec.Id).ServiceTerritoryId

                    ) 
                ) {

                //get new
                if (!newUserIdsToJobIds.containsKey(jobRec.Id)) {
                    newUserIdsToJobIds.put(jobRec.Id, new Set<Id>());    
                }
                if ( jobRec.BD_Account_Manager__c != null && jobRec.OwnerId != jobRec.BD_Account_Manager__c ) { 
                    newUserIdsToJobIds.get(jobRec.Id).add(jobRec.BD_Account_Manager__c); 
                    userIds.add(jobRec.BD_Account_Manager__c);
                }
                if ( jobRec.Project_Director__c != null  && jobRec.OwnerId != jobRec.Project_Director__c)   { 
                    newUserIdsToJobIds.get(jobRec.Id).add(jobRec.Project_Director__c);
                    userIds.add(jobRec.Project_Director__c);
                }                        
                if ( jobRec.Project_Manager__c != null  && jobRec.OwnerId != jobRec.Project_Manager__c)   { 
                    newUserIdsToJobIds.get(jobRec.Id).add(jobRec.Project_Manager__c ); 
                    userIds.add(jobRec.Project_Manager__c);
                }      
                if ( jobRec.AP_Approver__c != null  && jobRec.OwnerId != jobRec.AP_Approver__c)   { 
                    newUserIdsToJobIds.get(jobRec.Id).add(jobRec.AP_Approver__c); 
                    userIds.add(jobRec.AP_Approver__c);
                } 
                //  STAR-2199
                if ( jobRec.RM_CM_OM__c != null  && jobRec.OwnerId != jobRec.RM_CM_OM__c)   { 
                    newUserIdsToJobIds.get(jobRec.Id).add(jobRec.RM_CM_OM__c ); 
                    userIds.add(jobRec.RM_CM_OM__c);
                } 
                if ( jobRec.BD_Account_Manager_2__c != null  && jobRec.OwnerId != jobRec.BD_Account_Manager_2__c)   { 
                    newUserIdsToJobIds.get(jobRec.Id).add(jobRec.BD_Account_Manager_2__c); 
                    userIds.add(jobRec.BD_Account_Manager_2__c);
                } 
                if ( jobRec.Regional_Coordinator__c != null  && jobRec.OwnerId != jobRec.Regional_Coordinator__c )   { 
                    newUserIdsToJobIds.get(jobRec.Id).add(jobRec.Regional_Coordinator__c); 
                    userIds.add(jobRec.Regional_Coordinator__c);
                } 
                if ( jobRec.BD_Account_Manager_3__c != null  && jobRec.OwnerId != jobRec.BD_Account_Manager_3__c )   { 
                    newUserIdsToJobIds.get(jobRec.Id).add(jobRec.BD_Account_Manager_3__c); 
                    userIds.add(jobRec.BD_Account_Manager_3__c);
                } 
                //STAR-4435
                if ( jobRec.Senior_Project_Manager__c != null  && jobRec.OwnerId != jobRec.Senior_Project_Manager__c )   { 
                    newUserIdsToJobIds.get(jobRec.Id).add(jobRec.Senior_Project_Manager__c); 
                    userIds.add(jobRec.Senior_Project_Manager__c);
                } 

                //STAR-2754
                if ( jobRec.ServiceTerritoryId != null && newServTerrById.get(jobRec.ServiceTerritoryId).General_Manager__c != null && jobRec.OwnerId != newServTerrById.get(jobRec.ServiceTerritoryId).General_Manager__c )   { 
                    System.debug('~~~~ JobSharingService::getJobChanges: new ST General Manager - ' + newServTerrById.get(jobRec.ServiceTerritoryId).General_Manager__c);
                    newUserIdsToJobIds.get(jobRec.Id).add(newServTerrById.get(jobRec.ServiceTerritoryId).General_Manager__c); 
                    userIds.add(newServTerrById.get(jobRec.ServiceTerritoryId).General_Manager__c);
                }                 
                //get old, on updates
                if (oldJobById != null && oldJobById.containsKey(jobRec.Id)) {
                    if (!oldUserIdsToJobIds.containsKey(jobRec.Id)) 
                        oldUserIdsToJobIds.put(jobRec.Id, new Set<Id>()); 
                    if ( oldJobById.get(jobRec.Id).BD_Account_Manager__c != null ) { 
                        oldUserIdsToJobIds.get(jobRec.Id).add(oldJobById.get(jobRec.Id).BD_Account_Manager__c); 
                        userIds.add(oldJobById.get(jobRec.Id).BD_Account_Manager__c);
                    }
                    if ( oldJobById.get(jobRec.Id).Project_Director__c != null ) { 
                        oldUserIdsToJobIds.get(jobRec.Id).add(oldJobById.get(jobRec.Id).Project_Director__c); 
                        userIds.add(oldJobById.get(jobRec.Id).Project_Director__c);
                    }
                    if ( oldJobById.get(jobRec.Id).Project_Manager__c != null ) { 
                        oldUserIdsToJobIds.get(jobRec.Id).add(oldJobById.get(jobRec.Id).Project_Manager__c); 
                        userIds.add(oldJobById.get(jobRec.Id).Project_Manager__c);
                    }  
                    if ( oldJobById.get(jobRec.Id).AP_Approver__c != null )  { 
                        oldUserIdsToJobIds.get(jobRec.Id).add(oldJobById.get(jobRec.Id).AP_Approver__c); 
                        userIds.add(oldJobById.get(jobRec.Id).AP_Approver__c);
                    } 
                     //  STAR-2199
                    if ( oldJobById.get(jobRec.Id).RM_CM_OM__c != null ) { 
                        oldUserIdsToJobIds.get(jobRec.Id).add(oldJobById.get(jobRec.Id).RM_CM_OM__c);
                        userIds.add(oldJobById.get(jobRec.Id).RM_CM_OM__c); 
                    } 
                    if ( oldJobById.get(jobRec.Id).BD_Account_Manager_2__c != null ) { 
                        oldUserIdsToJobIds.get(jobRec.Id).add(oldJobById.get(jobRec.Id).BD_Account_Manager_2__c); 
                        userIds.add(oldJobById.get(jobRec.Id).BD_Account_Manager_2__c);
                    } 
                    if ( oldJobById.get(jobRec.Id).Regional_Coordinator__c != null ) { 
                        oldUserIdsToJobIds.get(jobRec.Id).add(oldJobById.get(jobRec.Id).Regional_Coordinator__c); 
                        userIds.add(oldJobById.get(jobRec.Id).Regional_Coordinator__c );
                    }   
                    if ( oldJobById.get(jobRec.Id).BD_Account_Manager_3__c != null ) { 
                        oldUserIdsToJobIds.get(jobRec.Id).add(oldJobById.get(jobRec.Id).BD_Account_Manager_3__c); 
                        userIds.add(oldJobById.get(jobRec.Id).BD_Account_Manager_3__c );
                    }  
                    //STAR-4435
                    if ( oldJobById.get(jobRec.Id).Senior_Project_Manager__c != null ) { 
                        oldUserIdsToJobIds.get(jobRec.Id).add(oldJobById.get(jobRec.Id).Senior_Project_Manager__c); 
                        userIds.add(oldJobById.get(jobRec.Id).Senior_Project_Manager__c );
                    }                     
                    //STAR-2754
                    System.debug('~~~~ JobSharingService::getJobChanges: oldJobById.get(jobRec.Id).ServiceTerritoryId - ' + oldJobById.get(jobRec.Id).ServiceTerritoryId);
                    System.debug('~~~~ JobSharingService::getJobChanges: oldServTerrById - ' + oldServTerrById);
                    if ( oldJobById.get(jobRec.Id).ServiceTerritoryId != null && oldServTerrById != null && oldServTerrById.get(oldJobById.get(jobRec.Id).ServiceTerritoryId) != null && oldServTerrById.get(oldJobById.get(jobRec.Id).ServiceTerritoryId).General_Manager__c != null ) { 
                        System.debug('~~~~ JobSharingService::getJobChanges: old ST General Manager - ' + oldServTerrById.get(oldJobById.get(jobRec.Id).ServiceTerritoryId).General_Manager__c);
                        oldUserIdsToJobIds.get(jobRec.Id).add(oldServTerrById.get(oldJobById.get(jobRec.Id).ServiceTerritoryId).General_Manager__c); 
                        userIds.add(oldServTerrById.get(oldJobById.get(jobRec.Id).ServiceTerritoryId).General_Manager__c );
                    }                                                         
                }
            }
        }
        System.debug('~~~~ JobSharingService::getJobChanges: userIds - ' + userIds);
        System.debug('~~~~ JobSharingService::getJobChanges: newUserIdsToJobIds.size() ' + newUserIdsToJobIds.size());
    }

    private void getJobSharing() {
        if (newUserIdsToJobIds != null && newUserIdsToJobIds.keySet().size() != 0) {
            for (Job_Sharing__c js : [Select User__c, Job__c From Job_Sharing__c Where Job__c In: newUserIdsToJobIds.keySet()]) {
                userIds.add(js.User__c);
                newUserIdsToJobIds.get(js.Job__c).add(js.User__c);
            }
        }
        System.debug('~~~~ JobSharingService::getJobChanges: newUserIdsToJobIds.size() ' + newUserIdsToJobIds.size());
    }

    private void getValidUserIdsToKey() {
        System.debug('~~~~ JobSharingService::getValidUserIdsToKey: userIds - ' + userIds);
        if (userIdsToShare == null || userIdsToShare.isEmpty()) {
            //build list of users to keep that have at least READ access to Jobs AND are active
            for (PermissionSetAssignment psa : [SELECT AssigneeId FROM PermissionSetAssignment 
                                                WHERE AssigneeId In: userIds
                                                    AND AssigneeId IN (SELECT Id FROM User WHERE UserType='Standard' OR Profile.Name Like 'Customer Community Plus%')
                                                    AND Assignee.IsActive=true
                                                    AND PermissionSetId IN (SELECT ParentId 
                                                                            FROM ObjectPermissions 
                                                                            WHERE SObjectType = 'WorkOrder' AND PermissionsRead = true)]) {
                userIdsToShare.add(psa.AssigneeId);
            }   
            System.debug('~~~~ JobSharingService::getValidUserIdsToKey: userIdsToShare - ' + userIdsToShare);
        }
    } 

    private void filterOutInvalidUserIds() {
        //filter out invalid users
        for (Id jobId : newUserIdsToJobIds.keySet()) {

            //get set of users to remove
            Set<Id> userIdsToRemove = new Set<Id>(newUserIdsToJobIds.get(jobId));
            userIdsToRemove.removeAll(userIdsToShare);
            System.debug('~~~~ JobSharingService::filterOUtInvalidUserIds: userIdsToRemove - ' + userIdsToRemove);
            
            //remove users for new job to exclude
            newUserIdsToJobIds.get(jobId).removeAll(userIdsToRemove);
            System.debug('~~~~ JobSharingService::filterOUtInvalidUserIds: newUserIdsToJobIds - jobId:' + jobId + ' userIds:' + newUserIdsToJobIds.get(jobId));

            //remove users for old job to exclude
            if (oldUserIdsToJobIds.containsKey(jobId)) {
                oldUserIdsToJobIds.get(jobId).removeAll(userIdsToRemove);
                System.debug('~~~~ JobSharingService::filterOUtInvalidUserIds: oldUserIdsToJobIds - jobId:' + jobId + ' userIds:' + oldUserIdsToJobIds.get(jobId));  
            }
        }
    }

    private void rectifyShareChanges() {
        //if there are overlaps between a user id to remove and add, remove from the remove list
        for (Id jobId : newUserIdsToJobIds.keySet()) {
            System.debug('~~~~ JobSharingService::rectifyShareChanges:  jobId:' + jobId); 
            if (oldUserIdsToJobIds != null && oldUserIdsToJobIds.containsKey(jobId)) {
                System.debug('~~~~ JobSharingService::rectifyShareChanges:  oldUserIdsToJobIds userIds:' + oldUserIdsToJobIds.get(jobId));     
                oldUserIdsToJobIds.get(jobId).removeAll(newUserIdsToJobIds.get(jobId));
            }
        }
    }

    
    private void deleteOldJobShares() {
        //identify existing shares to delete
        for (WorkOrderShare wsToDelete : [Select Id, ParentId, UserOrGroupId From WorkOrderShare Where ParentId In: oldUserIdsToJobIds.keySet() AND RowCause='Manual']) {
            if (oldUserIdsToJobIds.get(wsToDelete.ParentId).contains(wsToDelete.UserOrGroupId)) {
                jobSharesToDeleteLst.add(wsToDelete);
            }
        }

        System.debug('~~~~ JobSharingService::deleteOldJobShares: jobSharesToDeleteLst - ' + jobSharesToDeleteLst + ' size ' + jobSharesToDeleteLst.size());
    }

    private List<WorkOrderShare> createNewJobShares() {
        //identify existing shares that match new shares to insert and exclude them from creating new shares
        for (WorkOrderShare wsToInsert : [Select Id, ParentId, UserOrGroupId From WorkOrderShare Where ParentId In: newUserIdsToJobIds.keySet() AND RowCause='Manual']) {
            if (newUserIdsToJobIds.get(wsToInsert.ParentId).contains(wsToInsert.UserOrGroupId)) {
                newUserIdsToJobIds.get(wsToInsert.ParentId).remove(wsToInsert.UserOrGroupId);
                
            }
        }
        System.debug('~~~~ JobSharingService::createNewJobShares: newUserIdsToJobIds - ' + newUserIdsToJobIds + ' size ' + newUserIdsToJobIds.size());

        //Create jobShare Records
        for (Id jobId : newUserIdsToJobIds.keySet()) {
            for (Id userId : newUserIdsToJobIds.get(jobId)) {
                jobSharesToInsertLst.add(shareRecord(jobId, userId));
            }
        }

        return jobSharesToInsertLst;
    }

    public WorkOrderShare shareRecord(Id jobId, Id userId) {
        WorkOrderShare jobShareRec = new WorkOrderShare();

        jobShareRec.ParentId = jobId;
        jobShareRec.UserOrGroupId = userId;
        jobShareRec.AccessLevel = 'Edit';
        jobShareRec.RowCause = 'Manual';

        return jobShareRec;
    }  

    public Map<Id, ServiceTerritory> getServiceTerritoryMap(List<WorkOrder> jobLst) {
        Set<Id> servTerrIdLst = new Set<Id>();

        for (WorkOrder job : jobLst) {
            if (job.ServiceTerritoryId != null) {
                servTerrIdLst.add(job.ServiceTerritoryId);
            }
        }

        Map<Id, ServiceTerritory> servTerrByIdMap = new Map<Id, ServiceTerritory>([SELECT Id, Name, General_Manager__c, General_Manager__r.Name, General_Manager__r.IsActive FROM ServiceTerritory WHERE Id In: servTerrIdLst]);
        return servTerrByIdMap;
    }

    //STAR-4771 delete existing job sharing records for new job owners 
    public void deleteJobSharingRecsOfNewJobOwners(Map<Id, WorkOrder> newJobById, Map<Id, WorkOrder> oldJobById) {
        Set<Id> newOwnerIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();
        Map<Id, WorkOrder> jobById = new Map<Id, WorkOrder>();
        List<Job_Sharing__c> jobSharingLst = new List<Job_Sharing__c>();

        for (WorkOrder job : newJobbyId.values()) {
            if (job.OwnerId != oldJobById.get(job.Id).OwnerId) {
                newOwnerIds.add(job.OwnerId);
                jobIds.add(job.Id);
                jobById.put(job.Id, job);
            }
        }

        if (jobById != null) {
            for (Job_Sharing__c js : [SELECT Id, Job__c, User__c FROM Job_Sharing__c WHERE Job__c IN: jobIds AND User__c IN: newOwnerIds]) {
                if (jobById.containsKey(js.Job__c) && jobById.get(js.Job__c).OwnerId == js.User__c) {
                    jobSharingLst.add(js);
                }
            }
        }

        delete jobSharingLst;

    }

    //STAR-5298
    public String createJobSharesForAtms(Set<Id> jobIds) {
        String results = '';

        //get job sharing of existing jobs matching on job
        Map<Id, Set<Id>> userIdsByJobId = getJobSharingWithActiveUsers(jobIds);

        //get atms from job's account that doesn't match the owner that isn't matching an existing job sharing user
        Map<Id, Id> accIdByJobId = new Map<Id, Id>();
        for (WorkOrder job : [SELECT Id, AccountId FROM WorkOrder WHERE Id IN: jobIds]) {
            accIdByJobId.put(job.Id, job.AccountId);
        }

        Map<Id, Set<Id>> atmUserIdsByAccountId = getJobAccountTeamMembers(new Set<Id>(accIdByJobId.values()));
        
        //get active users matching atm
        //create job shares for atms that have active users 
        List<Job_Sharing__c> jobSharingLst = createJobSharesFromATM(jobIds, atmUserIdsByAccountId);

        //insert job sharing for atms
        Database.SaveResult[] resultLst = Database.insert(jobSharingLst, false);
        for (Database.SaveResult sr : resultLst) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    results +=' Error: Id - ' + sr.getId() + ', status code: ' + err.getStatusCode() + ',  messsage: ' + err.getMessage() + '\n';
                    //errorIds.add(sr.getId());
                }
            }             
        }
    
        return results;
    }

    private Map<Id, Set<Id>> getJobSharingWithActiveUsers(Set<Id> jobIds) {
        Map<Id, Set<Id>> userIdsByJobId = new Map<Id, Set<Id>>();

        for (Job_Sharing__c js : [SELECT Job__c, User__c FROM Job_Sharing__c WHERE Job__c IN: jobIds AND User__r.IsActive=true]) {
            if (!userIdsByJobId.containsKey(js.Job__c)) {
                userIdsByJobId.put(js.Job__c, new Set<Id>());
            } 
            userIdsByJobId.get(js.Job__c).add(js.User__c);
        }
        
        return userIdsByJobId;
    }

    private Map<Id, Set<Id>> getJobAccountTeamMembers(Set<Id> jobAccountIds) {
        Map<Id, Set<Id>> atmUserIdsByAccountId = new Map<Id, Set<Id>>();
        for (AccountTeamMember atm : [SELECT Id, UserId, AccountId FROM AccountTeamMember WHERE AccountId IN: jobAccountIds AND User.IsActive=true]) {
            if (!atmUserIdsByAccountId.containsKey(atm.AccountId)) {
                atmUserIdsByAccountId.put(atm.AccountId, new Set<Id>());
            }

            atmUserIdsByAccountId.get(atm.AccountId).add(atm.UserId);
        }
        
        return atmUserIdsByAccountId;
    }

    private List<Job_Sharing__c> createJobSharesFromATM(Set<Id> jobIds, Map<Id, Set<Id>> atmUserIdsByAccountId) {
        //get active users matching atm
        Map<Id, Set<Id>> userIdsByJobId = getJobSharingWithActiveUsers(jobIds);
        Map<Id, Set<Id>> atmUserIdsByJobId = new Map<Id, Set<Id>>();
        List<Job_Sharing__c> jobSharingLst = new List<Job_Sharing__c>();
        Map<Id, Id> userIdToDelByJob = new Map<Id, Id>();

        for (WorkOrder job : [SELECT Id, AccountId, OwnerId FROM WorkOrder WHERE Id IN: jobIds]) {
            atmUserIdsByJobId.put(job.Id, new Set<Id>());
            userIdToDelByJob.put(job.Id, job.OwnerId);

            //if there are account team members for jobs, then add them as potential job shares to create
            if (atmUserIdsByAccountId.containsKey(job.AccountId)) {
                //put all account atm users to the job
                atmUserIdsByJobId.get(job.Id).addAll(atmUserIdsByAccountId.get(job.AccountId));
                
                //remove all existing job sharing users from the group of atms to create as job shares
                if(userIdsByJobId.containsKey(job.Id)) {
                    atmUserIdsByJobId.get(job.Id).removeAll(userIdsByJobId.get(job.Id));
                }

                //remove the job's owner from list too so Job Sharing isn't created for the owner
                atmUserIdsByJobId.get(job.Id).remove(job.OwnerId);

                //create job sharing
                for (Id atmUserId : atmUserIdsByJobId.get(job.Id)) {
                    jobSharingLst.add(new Job_Sharing__c(Job__c=job.Id, User__c=atmUserId));
                }
            }
        }   
        deleteJobSharingMatchingOwner(userIdToDelByJob);
        return jobSharingLst;
    }

    private void deleteJobSharingMatchingOwner(Map<Id, Id> userIdToDelByJob ) {
        List<Job_Sharing__c> jobSharingToDeleteLst = new List<Job_Sharing__c>();
        for (Job_Sharing__c js : [SELECT Id, Job__c, User__c FROM Job_Sharing__c WHERE Job__c IN: userIdToDelByJob.keySet() AND User__c IN: userIdToDelByJob.values()]) {
            if ( userIdToDelByJob.get(js.Job__c) == js.User__c ) {
                jobSharingToDeleteLst.add(js);
            }
        }

        if (!jobSharingToDeleteLst.isEmpty()) {
            Database.DeleteResult[] resultLst = Database.delete(jobSharingToDeleteLst, false);
            for (Database.DeleteResult sr : resultLst) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('~~~~ JobSharingService::deleteJobSharingMatchingOwner:  Error: Id - ' + sr.getId() + ', status code: ' + err.getStatusCode() + ',  messsage: ' + err.getMessage() + '\n');
                        //errorIds.add(sr.getId());
                    }
                }             
            }            
        }
    }

    public class JobSharingServiceException extends Exception {}
}