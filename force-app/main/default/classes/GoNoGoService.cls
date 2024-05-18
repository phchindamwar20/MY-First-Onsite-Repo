/**
 * @description       : This updates the Go No Go for Accounts and Jobs
 * @TODOS             : Unified Error Handling framework... as of now, we just make errors available but don't really do anything with them if they occur on accounts since go/no go on account not sent to bolt
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-17-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class GoNoGoService {
    private List<String> errorMsgLst = new List<String>();
    //private Set<String> errorIds = new Set<String>();
    private Set<Id> allAccIds = new Set<Id>();

    public Set<Id> updateAccountsGoNoGo(Set<Id> accIds) {
        try {
            Map<Id, Account> accById = new Map<Id, Account>([SELECT Id, Go_No_Go__c, Go_No_Gox__c FROM Account WHERE Id IN: accIds]);
            Map<Id, Account> accUpdById = new Map<Id, Account>();

            for (Account acc : accById.values()) {
                if (acc.Go_No_Go__c != acc.Go_No_Gox__c) {
                    //allAccIds.add(acc.Id);
                    accUpdById.put(acc.Id, new Account(Id=acc.Id, Go_No_Gox__c=acc.Go_No_Go__c));
                    //System.debug('~~~~~ accUpdById - ' + accUpdById.get(acc.Id));
                }
            }

            if (!accUpdById.isEmpty()) {
                allAccIds.addAll(updateRecs(accUpdById.values()));
                updateAccountsGoNoGo((new Map<Id, Account>([SELECT Id FROM Account WHERE ParentId IN: accUpdById.keySet()])).keySet());
            } 
            /* removing from here because we get close to the CPU limits when calculating accounts alone in the record hierarchy
                job go/no go will be called in the handle next queueable class so it will have it's own transaction and corresponding govenor limits
            else {
                updateJobsGoNoGo((new Map<Id, WorkOrder>([SELECT Id FROM WorkOrder WHERE AccountId IN: accIds])).keySet());
            }*/
        } catch (Exception e) {
            errorMsgLst.add(' Error: Ids - ' + allAccIds + ', Type Name: ' + e.getTypeName() + ',  messsage: ' + e.getMessage() + ', stack trace: ' + e.getStackTraceString() + ', cause: ' + e.getCause() + ', line number: ' + e.getLineNumber());
        } 

        return allAccIds;
    }

    public Set<Id> updateJobsGoNoGo(Set<Id> jobIds) {
        Map<Id, WorkOrder> jobById = new Map<Id, WorkOrder>([SELECT Id, Go_No_Go__c, Go_No_Gox__c FROM WorkOrder WHERE Id IN : jobIds]);
        List<WorkOrder> jobUpdLst = new List<WorkOrder>();
        Set<Id> resultIds = new Set<Id>();

        for (WorkOrder job : jobById.values()) {
            if (job.Go_No_Go__c != job.Go_No_Gox__c) {
                jobUpdLst.add(new WorkOrder(Id=job.Id, Go_No_Gox__c=job.Go_No_Go__c));
            }
        }

        if (!jobUpdLst.isEmpty()) {
            System.debug('~~~~ GoNoGoService::updateJobsGoNoGo: BEFORE UPDATING JOBS TriggerDispatcher.tc - ' + TriggerDispatcher.tc);
            WorkOrderTriggerHandler.isDefaultOverride=true; //suppress the job trigger
            resultIds.addAll(updateRecs(jobUpdLst));
            System.debug('~~~~ GoNoGoService::updateJobsGoNoGo: AFTER UPDATING JOBS TriggerDispatcher.tc - ' + TriggerDispatcher.tc);
        }

        return resultIds;
    }

    public String getErrorMsgs() {
        String errorMsg = '';

        for (String errMsg : errorMsgLst) {
            errorMsg += errMsg +'\n';
        }
        
        return errorMsg;
    }

    /*public String getErrorIds() {
        return QueryBuilderService.getIdStringFromLst(errorIds);
    }*/

    private Set<Id> updateRecs(List<SObject> recLst) {
        Set<Id> ids = new Set<Id>();
        String errorMsg = '';
        Database.SaveResult[] resultLst = Database.update(recLst, false);
        for (Database.SaveResult sr : resultLst) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    errorMsgLst.add(' Error: Id - ' + sr.getId() + ', status code: ' + err.getStatusCode() + ',  messsage: ' + err.getMessage());
                    //errorIds.add(sr.getId());
                }
            } else {
                ids.add(sr.getId());
            }
        } 
        
        return ids;
    }

    public class GoNoGoServiceException extends Exception {}
}