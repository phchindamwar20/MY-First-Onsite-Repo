/**
 * @description       : This is the chainable queueable job that sets the match name on all account record types 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class MatchNameQueueable extends GenericQueueable {
    public override void execute(QueueableContext context) {
        try {
            MatchNameService mns = new MatchNameService();
            mns.setMatchNames(currentSelection.getRecIds());
            handleNext();
        } catch (Exception e) {
            handleError(e);
        }
    }

    public override void handleError(Exception e) {
        System.debug('~~~~~ MatchNameQueueable:: execute: exception e - ' + e);
        //TBD
        if (!Test.isRunningTest()) {
            handleNext();
        }
    }
}