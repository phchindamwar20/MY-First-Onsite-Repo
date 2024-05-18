/**
 * @description       : This queueable class triggers target related records to send to bolt when the source object/fields change that are used in a formula on the target object.
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-15-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class BoltIntegrationFormulaQueueable extends GenericQueueable {
    public override void execute (QueueableContext context) {
        try {
            updateAndAddToBoltQueue(); 
            //System.debug('~~~~ BoltIntegrationFormulaQueueable::execute: before handleNext');
            if (!Test.isRunningTest()){
                handleNext();
            }
            //System.debug('~~~~ BoltIntegrationFormulaQueueable::execute: after handleNext');          
        } catch (Exception e) {
            handleError(e);
        }
    }

    private void updateAndAddToBoltQueue() {
        String randomNumber = String.valueOf((Math.ceil(Math.random()) * 1000));

        //System.debug('~~~~ BoltIntegrationFormulaQueueable::updateAndAddtoBoltQueue: ((SelectionBoltIntegrationFormula)currentSelection).getIdsByTrgObjParFlds() ' + ((SelectionBoltIntegrationFormula)currentSelection).getIdsByTrgObjParFlds());


        for (String trgObjParRel: ((SelectionBoltIntegrationFormula)currentSelection).getIdsByTrgObjParFlds().keySet()) {
            //get target object and target parent field
            String[] trgObjParFldLst = trgObjParRel.split('-');

            //build query to get target records to send to bolt
            String ids = QueryBuilderService.getIdStringFromLst((Set<String>)JSON.deserialize(JSON.serialize(((SelectionBoltIntegrationFormula)currentSelection).getIdsByTrgObjParFlds().get(trgObjParRel)), Set<String>.class));
            List<SObject> resultLst = Database.query('SELECT Id FROM ' + trgObjParFldLst[0] + ' WHERE ' + trgObjParFldLst[1] + ' IN(' + ids + ')');
            
            if (!resultLst.isEmpty()) {
                //setup bolt engine callout parameters
                String boltSelectionClass = ((SelectionBoltIntegrationFormula)currentSelection).getBoltSelClassByTrgObjParFld().get(trgObjParRel);
                Integer maxRec=200, i=1, batchMaxNum=Integer.valueOf(Math.ceil(resultLst.size()/maxRec)), leftOverNum=resultLst.size()-(batchMaxNum*maxRec), currBatch=0;
                Decimal executionOrder=-1;
                Map<Id, SObject> boltBatchById = new Map<Id, SObject>();

                for (SObject rec : resultLst) {
                    //set bolt update trigger
                    SObject updRec = DynamicApexService.createObject(trgObjParFldLst[0]);
                    updRec.put('Id', rec.get('Id'));
                    updRec.put(BoltConstants.BOLT_UPDATE_TRIGGER_FIELD, String.valueOf(Datetime.now())+'-'+randomNumber);
                    boltBatchById.put(updRec.Id, updRec);

                    //Need to process batch of 200 records.  The last batch maybe less than 200 records, so need to account for that.
                    //System.debug('~~~~ BoltIntegrationFormulaQueuable::updateAndAddToBoltQueue: i='+i+', maxRec='+maxRec+', currBatch='+currBatch+', batchMaxNum='+batchMaxNum+', leftOverNum='+leftOverNum);
                    if (Math.mod(i, maxRec)==0 || (currBatch==batchMaxNum && leftOverNum==i)) {
                        //System.debug('~~~~ BoltIntegrationFormulaQueuable::updateAndAddToBoltQueue: inside processing batch before');

                        //update recs
                        Map<Id, String> errMsgById = updateRecs(boltBatchById);

                        //if errors, publish errors to bolt log
                        publishError(errMsgById);

                        //add callout to Bolt to execution item
                        ExecutionItem ei = new ExecutionItem(BoltConstants.BOLT_CHAIN_OF_RESPONS_QUEUEABLE, executionOrder, boltSelectionClass, GeneralConstants.AFTER_UPDATE, trgObjParFldLst[0], boltBatchById, null);
                        ei.getSelection().addToRecIds(boltBatchById.keySet());
                        executionItemLst.add(ei);
                        //System.debug('~~~~ BoltIntegrationFormulaQueuable::updateAndAddToBoltQueue: ei.getSelection() - ' + ei.getSelection());
                        
                        //reset 
                        i=1;
                        boltBatchById.clear();

                        //increment counter for tracking batches and execution order
                        currBatch++;
                        executionOrder--;
                        //System.debug('~~~~ BoltIntegrationFormulaQueuable::updateAndAddToBoltQueue: inside processing batch after');
                    } else {
                        i++;
                    }
                }
            }
            resultLst.clear();
        }
    }

    public override void handleError(Exception e) {
        if ((e.getMessage().contains(GeneralConstants.LOCK_ERROR) || e.getMessage().contains(GeneralConstants.QUERY_EXCEPTION)) && retryNumber<GeneralConstants.MAX_RETRIES) {
            //retry again
            retryNumber++;
            setUpHandler(executionItemLst, ((SelectionBoltIntegrationFormula)currentSelection), currentClassName, retryNumber, triggerEvent, objectName);
        } else {
            //log error
            String errorMsg ='Cause: ' + e.getCause() + '\nStackTrace: ' + e.getStackTraceString() + '\nMessage: '+ e.getMessage() + '\nType: ' + e.getTypeName() + '\nLine Number: ' + e.getLineNumber() +'\nRetry: ' + retryNumber;
            BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', BoltConstants.SF_TO_BOLT , 'execute', ((SelectionBoltIntegrationFormula)currentSelection).getRecIds(), currentClassName);
            //handle next, even if job's go/no-go wasn't populated
            
            if (!Test.isRunningTest()){
                handleNext();
            }
        } 
    }

    /*private Map<Id, String> updateRecs(Map<Id, SObject> recById) {
        Map<Id, String> errorMsgById = new Map<Id, String>();
        Database.SaveResult[] resultLst = Database.update(recById.values(), false);
        for (Database.SaveResult sr : resultLst) {
            if (!sr.isSuccess()) {
                recById.remove(sr.getId());
                for (Database.Error err : sr.getErrors()) {
                    errorMsgById.put(sr.getId(), ' Error: Id - ' + sr.getId() + ', status code: ' + err.getStatusCode() + ',  messsage: ' + err.getMessage() + '\n');
                }
            } 
        } 
        
        return errorMsgById;
    } */  
    
    private void publishError(Map<Id, String> errorMsgById) {
        String errorMsg = '';
        for (String err : errorMsgById.values()) {
            errorMsg += err + '\n';
        }

        if (!errorMsgById.isEmpty())
            BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', BoltConstants.SF_TO_BOLT , 'execute', errorMsgById.keySet(), 'BoltIntegrationFormulaQueueable');
    }

}