/**
 * @description       : This class is in the chain of responsibility framework of the account trigger and it calls the AccountContractsService to update contracts associated with the account ids.
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-01-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class AccountContractsQueueable extends GenericQueueable {
    public override void execute (QueueableContext context) {
        try {
            AccountContractsService acs = new AccountContractsService();
            acs.updateClientContracts(currentSelection.getRecIds());
            handleNext();
        } catch (Exception e) {
            handleError(e);
        }
    }

    public override void handleError(Exception e) {
        //TBD
        System.debug('~~~~ AccountContractsQueueable::handleError: e - ' + e);
        handleNext();
    }
}