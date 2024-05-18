/**
 * @description       : 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 02-19-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class ICertisUserProviReProviQueueable extends GenericQueueable {
    public override void execute (QueueableContext context) {
        try {
            ProvisionUserClass.deProvisionOrReProvisionUser(currentSelection.getRecIds());
            handleNext();
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
            BoltLogPublisherService.generateNewExceptionLogEntries(currentClassName, 'ProvisionUserClass.deProvisionOrReProvisionUser', e, currentSelection.getRecIds());
            //handle next, even if job's go/no-go wasn't populated
            
            if (!Test.isRunningTest()){
                handleNext();
            }
        } 
    }
}