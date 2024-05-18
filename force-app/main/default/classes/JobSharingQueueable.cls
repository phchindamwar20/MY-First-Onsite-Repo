/**
 * @description       : STAR-5298:  This refactors Job_Updates process builder portion that creates job sharing records for a job's account's team members that are ACTIVE and NOT the job owner 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-21-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class JobSharingQueueable extends GenericQueueable{
    
    public override void execute(QueueableContext context) {
        createJobShares(currentSelection.getRecIds());
    }
    
    public override void handleError(Exception e) {
        String errorMsg ='Cause: ' + e.getCause() + '\nStackTrace: ' + e.getStackTraceString() + '\nMessage: '+ e.getMessage() + '\nType: ' + e.getTypeName() + '\nLine Number: ' + e.getLineNumber() +'\nRetry: ' + retryNumber;
        System.debug('~~~~ JobSharingQueueable::handleError - ErrorMessage - ' + errorMsg);
        //BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', '', 'createJobShares', currentSelection.getRecIds(), currentClassName);

        if (!Test.isRunningTest()) {
            handleNext();
        }
    }

    @TestVisible
    private void createJobShares(Set<Id> jobIds) {
        try {
            JobSharingService jss = new JobSharingService();
            String result = jss.createJobSharesForAtms(jobIds);

            if (!String.isBlank(result)) {
                throw new JobSharingService.JobSharingServiceException(result);
            }
            handleNext();
        } catch (Exception e) {
            handleError(e);
        }
    }   
}