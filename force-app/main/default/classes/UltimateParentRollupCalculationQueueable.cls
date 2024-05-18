/**
 * @description       : This chainable class is utilized to call the UltimateParentRollupService to calculate the ulimate parent.  It extends the GenericQueueable class
 *                      The UtltimateParentRollupService sets the Ultimate Parent on all child and descendant accounts.  After this is done,
 *                      This class Then, the UltimateParentRollupCalculationQueueable 
 *                      will dynamically adds the BoltEnigineQueueable  to the Execution Item List to send the accounts and descendant accounts to Bolt for processing
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-07-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class UltimateParentRollupCalculationQueueable extends GenericQueueable {

    private final String BOLT_QUEUEABLE_CLASS = 'BoltCalloutEngineQueueable';
    private final String BOLT_ACC_SELECTION = 'SelectionBoltCalloutAccount'; //without parents

    
    public override void execute(QueueableContext context) {
        Set<Id> ids = new Set<Id>();
        try {
            if (!currentSelection.getRecIds().isEmpty()) {
                Map<Id, Account> recById = new Map<Id, Account>([SELECT Id, RecordTypeId, ParentId, The_Ultimate_Parent_Account__c FROM Account WHERE Id IN : currentSelection.getRecIds()]);
                UltimateParentRollupService uprs = new UltimateParentRollupService();
                ids = uprs.setUltimateParent(recById.keySet());
                addBoltProcessingToExecutionChain(ids);

                if (!String.isBlank(uprs.getErrors())) {
                    throw new UltimateParentRollupCalQueueException(uprs.getErrors()); 
                }
            }
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
            System.debug('~~~~ UltimateParentRollupCalculationQueueable::handleError: errorMsg - ' + errorMsg);
            BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', BoltConstants.SF_TO_BOLT , 'setUltimateParent', currentSelection.getRecIds(), currentClassName + '.UltimateParentRollupService');
            
            if (!Test.isRunningTest()) {
                handleNext();
            } 
        }
    }

    private void addBoltProcessingToExecutionChain(Set<Id> processedIds) {
        //create a 'link in the chain' to send ultimate account updates to Bolt
        //Map<Id, Account> recById = new Map<Id, Account>([SELECT Id, ParentId, The_Ultimate_Parent_Account__c FROM Account WHERE Id IN : processedIds]);
        //System.debug('~~~~ UltimateParentRollupCalculationQueueable::addBoltProcessingToExecutionChain: BEFORE executionItemLst.size() - ' + executionItemLst.size());

        if (!processedIds.isEmpty()) {
            Decimal executionOrder = -1;

            //send batches of records in groups of 200 so Bolt isn't getting more than 200 records at a time
            for (List<Account> accLst : [SELECT Id, Name, ParentId, The_Ultimate_Parent_Account__c, RecordTypeId 
                                            FROM Account 
                                            WHERE Id IN : processedIds 
                                            AND RecordTypeId =: GeneralConstants.RT_ID_ACC_ACCOUNT
                                            ORDER BY The_Ultimate_Parent_Account__c, ParentId ]) {
                
                //We only need one bolt queue per approx 200 records
                //The Bolt queueable selection crtieria won't select jobs with parent ids, but the ultimate parent one will accept jobs with parent ids but not select accounts without parent ids
                //Ultimate parent is triggered on change of parent id, which includes if a parent id was removed
                //The Bolt selection doesn't process changes in parents directly, because that is for the ultimate parent
                //This is why we add ALL the ids to it so we aren't creating another bolt execution item
                //processes the ones without parents to Bolt
                if (!accLst.isEmpty()) {
                    ExecutionItem ei1 = new ExecutionItem(BOLT_QUEUEABLE_CLASS, executionOrder, BOLT_ACC_SELECTION, triggerEvent, objectName, new Map<Id, Account>(accLst), null);
                    executionItemLst.add(ei1);
                    ei1.getSelection().addToRecIds(new Set<Id>((new Map<Id, Account>(accLst)).keySet())); // add the rest of the ids, which is ALL the ids since not all of them would be selected by the selection criteria
                    executionOrder += -1;
                }
            }

            System.debug('~~~~ UltimateParentRollupCalculationQueueable::addBoltProcessingToExecutionChain: AFTER executionItemLst.size() - ' + executionItemLst.size());
        }
    }

    public class UltimateParentRollupCalQueueException extends Exception {}
}