/**
 * @description       : This queueable class calls the iCertis managed package to auto create CWA agreements
 *                      This is the iCertis custom trigger refactored
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-08-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class IcertisAgreementAuthSignQueueable extends GenericQueueable {
    public override void execute (QueueableContext context) {
        try {
            List<WorkOrder> jobIdsToAutoCreateAgreeementLst = new List<WorkOrder>();
            for (WorkOrder job : [SELECT Id, IC_Integration__c, ICM_Auto_Create_Context__c FROM WorkOrder WHERE Id IN: currentSelection.getRecIds()]) {
                if (job.ICM_Auto_Create_Context__c == null) {
                	jobIdsToAutoCreateAgreeementLst.add(job);
                }
            }
            
            if (!jobIdsToAutoCreateAgreeementLst.isEmpty()){
                IcertisCLM.ICM_AutoCreateTriggerHandler.onAfterInsertorUpdate(jobIdsToAutoCreateAgreeementLst);
            }

            handleNext();
            
        } catch (Exception e) {
            handleError(e); 
        }
    }
    
    public override void handleError(Exception e) {
        String methodName = 'execute';
        
        if ((e.getMessage().contains(GeneralConstants.LOCK_ERROR) || e.getMessage().contains(GeneralConstants.QUERY_EXCEPTION)) && retryNumber<GeneralConstants.MAX_RETRIES) {
            //retry again
            retryNumber++;
            
            //TODO: add logging

            //add this back in the execution item list to reprocess 
            setUpHandler(executionItemLst, currentSelection, currentClassName, retryNumber, triggerEvent, objectName);
        } else {
            //log error
            String errorMsg ='Cause: ' + e.getCause() + '\nStackTrace: ' + e.getStackTraceString() + '\nMessage: '+ e.getMessage() + '\nType: ' + e.getTypeName() + '\nLine Number: ' + e.getLineNumber() +'\nRetry: ' + retryNumber;
            //BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', ICertisConstants.SF_TO_ICERTIS , methodName, currentSelection.getRecIds(), currentClassName);
            //TODO:  add logging

            if (!Test.isRunningTest()) {
                handleNext();
            }
        } 
    }   
}