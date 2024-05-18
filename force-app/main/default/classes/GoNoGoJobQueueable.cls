/**
 * @description       : 1. This sets the go/no go for jobs using the GoNoGoService class. 
 *                      2. It checks to see if there is a bolt execution item for jobs
 *                      3.  If there is, it add the successfully processed job ids to the existing bolt execution items selection
 *                      4.  Else, it dynamically adds a bolt execution item for processing the job ids in the executionItemsLst
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-09-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class GoNoGoJobQueueable extends GenericQueueable {
    //These settings are used to dynamically add processing job ids to Bolt
    private final String BOLT_JOB_SELECTION = 'SelectionBoltCalloutJob'; //Name of the Job's Bolt Callout Selection Class
    private final String BOLT_CHAIN_OF_RESPONS_QUEUEABLE = 'BoltCalloutEngineQueueable'; //Name of the Bolt Callout Engine Chain of responsibility queueable class

    public override void execute (QueueableContext context) {
        try {
            GoNoGoService gngsJob = new GoNoGoService();
            Set<Id> jobIds = gngsJob.updateJobsGoNoGo(currentSelection.getRecIds());
            addBoltToQueue(jobIds);

            //get and log errors
            String errMsg = gngsJob.getErrorMsgs();
            if (!String.isBlank(errMsg)) {
                throw new GoNoGoService.GoNoGoServiceException(errMsg);
            } else {
                handleNext();
            }
        } catch (Exception e) {
            handleError(e);
        }
    }

    public override void handleError(Exception e) {
        if ((e.getMessage().contains(GeneralConstants.LOCK_ERROR) || e.getMessage().contains(GeneralConstants.QUERY_EXCEPTION)) && retryNumber<GeneralConstants.MAX_RETRIES) {
            //retry again
            retryNumber++;
            setUpHandler(executionItemLst, currentSelection, currentClassName, retryNumber, triggerEvent, objectName);
        } else {
            //log error
            String errorMsg ='Cause: ' + e.getCause() + '\nStackTrace: ' + e.getStackTraceString() + '\nMessage: '+ e.getMessage() + '\nType: ' + e.getTypeName() + '\nLine Number: ' + e.getLineNumber() +'\nRetry: ' + retryNumber;
            BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', BoltConstants.SF_TO_BOLT , 'execute', currentSelection.getRecIds(), currentClassName);
            //handle next, even if job's go/no-go wasn't populated
            
            if (!Test.isRunningTest()){
                handleNext();
            }
        } 
    }

    private void addBoltToQueue(Set<Id> jobIds) {
        //If Callout to Bolt isn't already in the execute items list, dynamically add it so the updated job's Go/No Go can go to Bolt
        if (!currentSelection.getRecIds().isEmpty()) {
            Boolean isBoltInQueue = false;
            for (ExecutionItem ei : executionItemLst) {
                //Bolt is already in the execution items list for processing, no need to re-add it to queue, just add the rec Ids to existing selection
                //There should be no more than 200 records in here, even when adding the ids, because it was put in the queue by the trigger
                if (ei.getSelection().getSelectionName() == BOLT_JOB_SELECTION) {
                    isBoltInQueue=true;
                    ei.getSelection().addToRecIds(jobIds);  //it doesn't matter if the set already has the ids in there, since it is a set!
                    break;
                }
            }
            
            if (!isBoltInQueue) {
                Decimal executionOrder=-1;
                //for each chuck of approx 200 job records, add an excutionItem for job bolt
                for (WorkOrder[] jobLst : [SELECT Id, Go_No_Go__c, Go_No_Gox__c, Integrate_with_Bolt__c FROM WorkOrder WHERE Id IN : currentSelection.getRecIds() AND Integrate_with_Bolt__c=true]) {
                    ExecutionItem ei = new ExecutionItem(BOLT_CHAIN_OF_RESPONS_QUEUEABLE, executionOrder, BOLT_JOB_SELECTION, triggerEvent, GeneralConstants.OBJ_JOB, new Map<Id, WorkOrder>(jobLst), null);

                    //send add bolt processing to the execution items list
                    if (!ei.getSelection().getRecIds().isEmpty()) {
                        executionItemLst.add(ei);
                        executionOrder += -1;
                    }
                }
            }
        }
    }    
}