/**
 * @description       : 1. This updates the Go/No Go for accounts and the child in the hierarchy accounts and 
 *                      2. it dynamically adds a chainable queuable service to update Go/No Go for the jobs of the accounts and child hierarchy accounts
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-07-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class GoNoGoAccountQueueable extends GenericQueueable {
    //These settings are used to dynamically add processing the account's job's Go/No Go calculation to the queueable chain of responsibility framework
    private final String JOB_GO_NO_GO_SELECTION = 'SelectionGoNoGoJob'; //Name of the Job's Go/No Go Selection Class
    private final String JOB_GO_NO_GO_CHAIN_OF_RESPONS_QUEUEABLE = 'GoNoGoJobQueueable'; //Name of the Job's Go/No Go Chain of responsibility queueable class

    public override void execute (QueueableContext context) {
        calculateGoNoGo(currentSelection.getRecIds()); 
    }

    @TestVisible
    private void calculateGoNoGo(Set<Id> inputAccIds) {
        try {
            Set<Id> accIds = new Set<Id>();
            GoNoGoService gngsAcc = new GoNoGoService();
            accIds = gngsAcc.updateAccountsGoNoGo(inputAccIds);
            addJobGoNoGoToExecutionItems(accIds);
            
            //get and log errors
            String errMsg = gngsAcc.getErrorMsgs();
            if (!String.isBlank(errMsg)) {
                throw new GoNoGoService.GoNoGoServiceException('This error is related to calculating account go/no-go and it indirectly impacts bolt jobs:  \n' + errMsg);
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

    private void addJobGoNoGoToExecutionItems(Set<Id> accIds) {
        if (!accIds.isEmpty()) {
            
            Decimal executionOrder=-1;
            //for each chuck of approx 200 job records, add an excutionItem for job go/no go calculation
            for (WorkOrder[] jobLst : [SELECT Id, Go_No_Go__c, Go_No_Gox__c FROM WorkOrder WHERE (AccountId IN : accIds OR Property__c IN: accIds) AND Status IN : GeneralConstants.OPEN_JOB_STATUSES]) {
                ExecutionItem ei = new ExecutionItem(JOB_GO_NO_GO_CHAIN_OF_RESPONS_QUEUEABLE, executionOrder, JOB_GO_NO_GO_SELECTION, GeneralConstants.AFTER_UPDATE, GeneralConstants.OBJ_JOB, new Map<Id, WorkOrder>(jobLst), null);
                if (!ei.getSelection().getRecIds().isEmpty()) {
                    executionItemLst.add(ei);
                    executionOrder += -1;
                }
            }
        }
    }
}