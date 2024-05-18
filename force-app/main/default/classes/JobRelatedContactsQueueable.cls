/**
 * @description       : This is the chainable queueable class that updates jobs' related contacts
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-21-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class JobRelatedContactsQueueable extends GenericQueueable {
    public override void execute(QueueableContext context) {
        try {
            JobRelatedContactsService jrcs = new JobRelatedContactsService();
            String errorMsg = jrcs.updateRelatedJobContacts(((SelectionJobRelatedContacts)currentSelection).getActionByJobId());

            if (!String.isBlank(errorMsg)) {
                throw new JobRelatedContactsService.JobRelatedContactsServiceException(errorMsg); 
            }
            if (!Test.isRunningTest()) {
                handleNext();
            }
        } catch (Exception e) {
            handleError(e);
        }
    }

    public override void handleError(Exception e) {
        String errorMsg = 'Please log a ticket with Service Now if you are experiencing an error and provide the following details: ';
        errorMsg += '\n Message: ' + e.getMessage();
        errorMsg += '\n Cause: ' + e.getCause();
        errorMsg += '\n Line Number: ' + e.getLineNumber();
        errorMsg += '\n Stack Trace: ' + e.getStackTraceString();

        if (!Test.isRunningTest()) {
            handleNext();
        }
    }    
}