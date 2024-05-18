/**
 * @description       : If there are approved agreements for signing on the contract, send the agreements for signing to iCertis
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-12-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class IcertisAgreementsForSigningQueueable extends GenericQueueable {
    public override void execute(QueueableContext context) {
        try { 

            //get iCertis agreements and change status to Waiting for Signatory via callout
            Map<Id, Contract> contractById = IcertisService.sendAgreementForSigning(currentSelection.getRecIds());
            
            //update records with eSign Datetime
            errorById = updateRecs(contractById);

            //process errors
            if (errorById.isEmpty()) {
                handleNext();
            } else {
                //TODO:  future make error message translatable for Canada french
                throw new IcertisAgreementsForSigningQueueableException('One or more errors occured while attempting to update the contracts with the eSign Date');
            }
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
        } else if (!errorById.isEmpty()) {
            //log error
            String errorMsg ='Cause: ' + e.getCause() + '\nStackTrace: ' + e.getStackTraceString() + '\nMessage: '+ e.getMessage() + '\nType: ' + e.getTypeName() + '\nLine Number: ' + e.getLineNumber() +'\nRetry: ' + retryNumber;
            for (String msg : errorById.values()) {
                errorMsg += '\n'+msg;
            }
            //TODO: Add logging

            handleNext();
        } else {
            //log error
            String errorMsg ='Cause: ' + e.getCause() + '\nStackTrace: ' + e.getStackTraceString() + '\nMessage: '+ e.getMessage() + '\nType: ' + e.getTypeName() + '\nLine Number: ' + e.getLineNumber() +'\nRetry: ' + retryNumber;
            //BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', ICertisConstants.SF_TO_ICERTIS , methodName, currentSelection.getRecIds(), currentClassName);
            //TODO:  add logging

            handleNext();
        } 
    }   
    
    private class IcertisAgreementsForSigningQueueableException extends Exception{}
}