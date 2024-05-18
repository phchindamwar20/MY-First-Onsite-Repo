/**
 * @description       : 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-04-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class MapsCampaignMemeberQueueable extends GenericQueueable {
    public override void execute(QueueableContext context) {
        try {
            Map<Id, Account> newAccById = new Map<Id, Account>([SELECT Id, Maps_Campaign_Trigger__c FROM Account WHERE Id IN : currentSelection.getRecIds()]);
            MapCampaignMemberService.createCampaignMembers(newAccById, null);
        } catch (Exception e) {
            handleError(e);
        } finally {        
            handleNext();
        }
    }

    public override void handleError(Exception e) {
        String errorMsg = 'Please log a ticket with Service Now if you are experiencing an error and provide the following details: ';
        errorMsg += '\n Message: ' + e.getMessage();
        errorMsg += '\n Cause: ' + e.getCause();
        errorMsg += '\n Line Number: ' + e.getLineNumber();
        errorMsg += '\n Stack Trace: ' + e.getStackTraceString();

        throw new MapCampaignMemberQueueableException(errorMsg);
    }    

    public class MapCampaignMemberQueueableException extends Exception {}
}