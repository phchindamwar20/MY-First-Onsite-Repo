/**
 * @description       : This calls the iCertisService that for CWA Contracts 
 *                       1. makes a call out verifies an iCertis User exists based on the email adresss
 *                       2. if the user exists and/or the first name and last name has changed, make a callout to update the iCertis user
 *                       3. if the user doesn't exists then make a callout to create an iCertis User
 *                       4. for the jobs with no errors after the job update, 
 *                              a. update the job's External Signatory Title and IC Integration on the job
 *                              b. chain a queueable job to make execute the iCertis managed package 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-12-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class ICCWAJobQueueable extends GenericQueueable{
    //iCertis/Bolt chain of responsibiliity selections and queueable
    final public static String ICERTIS_SEL_AGREEMENT_AUTH_SIGN = 'SelectionIcertisAgreementAuthSign';
    final public static String ICERTIS_QUEUEABLE_AGREEMENT_AUTH_SIGN = 'IcertisAgreementAuthSignQueueable';

    public override void execute(QueueableContext context) {
        try {
            //call web service to verify create or update iCertis User

            List<WorkOrder> jobLst = IcertisService.verifyICIUserCallout(currentSelection.getRecIds());
            Map<Id, WorkOrder> jobById = new Map<Id, WorkOrder>();
        
            //for jobs that had a user successfully created/updated
        	for (WorkOrder job : jobLst) {
                if (job.Icertis_User_Id__c != null) {
                    job.IC_External_Signatory_Title__c=ICertisConstants.IC_EXTERNAL_SIGNATORY_TITLE;
                    job.IC_Integration__c=ICertisConstants.IC_FIELDS_UPDATE;
                    //TODO:  Add CWA Lifecycle Sent to ICertis to Auto Create Agreement
                }
                jobById.put(job.Id, job);
        	}
            
            //update records, get errors
            errorById = updateRecs(jobById);

            //dynmaically add execution item for auto creation of agreement
            if (!jobById.isEmpty()) {
                //exclude jobs without Icertis User Id, these don't have iCertis Users or there was a problem verifying, creating or updating the user
                for (WorkOrder job : jobById.values()) {
                    if (String.isBlank(job.Icertis_User_Id__c)) {
                        jobById.remove(job.Id);
                    }
                }
                //send records with Icertis Users to next job that creates the Auto Agreements
                if (!jobById.isEmpty()) {
                    addIcertisAgreeAuthSignToExecuteItems(jobById.keySet());
                }
            }
            
            //process errors
            if (errorById.isEmpty()) {
                handleNext(); 
            } else {
                throw new ICCWAJobQueueableException('An error occurred while updating CWA jobs after iCertis User Verification, Creation and/or Updates');
            }
        } catch (Exception e) {
            handleError(e);
        }
    }
    
    public override void handleError(Exception e) {
        String methodName = 'execute';
        Boolean isReProcess = false;
        
        if ((e.getMessage().contains(GeneralConstants.LOCK_ERROR) || e.getMessage().contains(GeneralConstants.QUERY_EXCEPTION)) && retryNumber<GeneralConstants.MAX_RETRIES) {
            //retry again
            retryNumber++;

            //TODO: Add logging, this has to be done before setupHandler because queue is enqueued within that method

            isReProcess = true;
            //add this back in the execution item list to reprocess 
            setUpHandler(executionItemLst, currentSelection, currentClassName, retryNumber, triggerEvent, objectName);
            
        } else if (!errorById.isEmpty()) {
            //log error
            String errorMsg ='Cause: ' + e.getCause() + '\nStackTrace: ' + e.getStackTraceString() + '\nMessage: '+ e.getMessage() + '\nType: ' + e.getTypeName() + '\nLine Number: ' + e.getLineNumber() +'\nRetry: ' + retryNumber;
            for (String msg : errorById.values()) {
                errorMsg += '\n'+msg;
            }
            //BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', ICertisConstants.SF_TO_ICERTIS , methodName, errorById.keySet(), currentClassName);
            //TODO: Add logging
        } else {
            //log error
            String errorMsg ='Cause: ' + e.getCause() + '\nStackTrace: ' + e.getStackTraceString() + '\nMessage: '+ e.getMessage() + '\nType: ' + e.getTypeName() + '\nLine Number: ' + e.getLineNumber() +'\nRetry: ' + retryNumber;
            //TODO: Add logging
            //BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', ICertisConstants.SF_TO_ICERTIS , methodName, currentSelection.getRecIds(), currentClassName);
        }
 
        //handle Next
        if (!Test.isRunningTest() && !isReProcess) {
                handleNext();
        }			              
    } 

    
    //add the 'link in the chain' to send to iCertis managed package to auto create agreements
    @TestVisible
    private void addIcertisAgreeAuthSignToExecuteItems(Set<Id> jobIds) {
        Decimal executionOrder=-1;
        //add to top of  execution items list
        ExecutionItem ei = new ExecutionItem(ICERTIS_QUEUEABLE_AGREEMENT_AUTH_SIGN, executionOrder, ICERTIS_SEL_AGREEMENT_AUTH_SIGN, GeneralConstants.AFTER_UPDATE, GeneralConstants.OBJ_JOB, null, null);
        ei.getSelection().addToRecIds(jobIds);
        executionItemLst.add(ei);          
    }

    public class ICCWAJobQueueableException extends Exception {}
}