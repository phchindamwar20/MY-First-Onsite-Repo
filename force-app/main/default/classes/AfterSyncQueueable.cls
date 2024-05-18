/**
 * @description       : 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-09-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class AfterSyncQueueable implements Queueable {
    private String objectApiName;
    private String triggerOperation;
    private Map<Id, SObject> newRecById;
    private Map<Id, SObject> oldRecById;

    public AfterSyncQueueable(String objectApiName, String triggerOperation, Map<Id, SObject> newRecById, Map<Id, SObject> oldRecById) {
        this.objectApiName=objectApiName;
        this.triggerOperation=triggerOperation;
        this.newRecById=newRecById;
        this.oldRecById=oldRecById;
    }

    public void execute (QueueableContext context) {
        try {
            ExecutionService chainQueueableJobService = new ExecutionService();
            chainQueueableJobService.buildAndKickoffQueueableJobs(objectApiName, triggerOperation, newRecById, oldRecById);
        } catch (Exception e) {
            //log error
            String errorMsg ='Cause: ' + e.getCause() + '\nStackTrace: ' + e.getStackTraceString() + '\nMessage: '+ e.getMessage() + '\nType: ' + e.getTypeName() + '\nLine Number: ' + e.getLineNumber();
            BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', BoltConstants.SF_TO_BOLT , 'execute', newRecById.keySet(), 'AfterSyncQueueable');
        }
    }
}