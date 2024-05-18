/**
 * @description       : 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 07-14-2023
 * @last modified by  : Terri Jiles
**/
public with sharing class FileLinkServiceEventTriggerHandler extends TriggerHandlerBase {
    protected final Integer MAX_BATCH_SIZE = 200;
    protected final String CLASS_NAME = 'FileLinkServiceTriggerHandler';
    protected final String METHOD_NAME = 'updateSObjectRecs';
    protected final Integer DELAY = 10000;

    public override void afterInsert(Map<Id, SObject> newItems) {
        updateSObjectRecs((List<FileLinkServiceEvent__e>)newItems.values());
    }

    private void updateSObjectRecs(List<FileLinkServiceEvent__e> sObjectEventRecLst) {
        try {
            Map<Id, SObject> parentRecById = new Map<Id, SObject>();

            Integer counter = 0;
            for (FileLinkServiceEvent__e flse : sObjectEventRecLst) {
                SObject rec = (SObject)JSON.deserialize(flse.SObject_Record__c, Sobject.class);
                parentRecById.put(rec.Id, rec);

                counter++;
                if (counter > MAX_BATCH_SIZE) {
                    break;
                }
            }  

            compareFileLinkCount(parentRecById);

        } catch (Exception e) {
            BoltLogPublisherService.publishBoltErrorEvent(500, 'Message: ' + e.getMessage() + ', Cause: ' + e.getCause() + ', Stack Trace: ' + e.getStackTraceString(), 'none', BoltConstants.SF_TO_BOLT, METHOD_NAME, null, CLASS_NAME);
        }        
    }

    private void compareFileLinkCount(Map<Id, SObject> newRecById) {
        //get recs
        //query number of content document links associated with recs and compare with actual count
        //-- need to get number of links field on object based on prefix
        Map<Id, Decimal> actualCountByParentId = new Map<Id, Decimal>();
        Set<Id> ids = newRecById.keySet();
        Set<Id> recallParentIds = new Set<Id>();
        List<SObject> recsToUpdateLst = new List<SObject>();
        
        //-- Map, record by actual count
        //delayProcess(); 
        for (AggregateResult cdl : [SELECT LinkedEntityId, Count(Id) recCount
                                        FROM ContentDocumentLink
                                        WHERE LinkedEntityId IN : ids
                                        GROUP BY LinkedEntityId]) {
            actualCountByParentId.put((Id)cdl.get('LinkedEntityId'), (Decimal)cdl.get('recCount'));
        }

        //-- build queries based on prefix; need to handle multiple object types for future scalability .. hence the double loop
        for (FileLinkServiceConfiguration__mdt flsc : FileLinkConfiguration.fileLinkConfigByRecPrefix.values()) {
            List<SObject> oldRecLst = Database.query(FileLinkConfiguration.buildQueryFromConfig(ids, flsc));
            for (SObject oldRec : oldRecLst) { //rec is old record, parentRecById is the new rec
                Decimal actualLinkCount = actualCountByParentId.containsKey(oldRec.Id) ? actualCountByParentId.get(oldRec.Id) : 0;
                Decimal linkLstCount = FileLinkConfiguration.getFileLinkNumberValue(newRecById.get(oldRec.Id));

                if (actualLinkCount == linkLstCount) {
                    if (DynamicApexService.isFieldExists(flsc.Object_API_Name__c, 'RecordTypeId')) {
                        newRecById.get(oldRec.Id).put('RecordTypeId',(Id)oldRec.get('RecordTypeId'));
                    }
                    recsToUpdateLst.add(newRecById.get(oldRec.Id));
                    System.debug('~~~~ FileLinkServiceEventTriggerHandler::compareFileLinkCount: added newRecById.get(oldRec.Id) to recsToUpdateLst = ' + newRecById.get(oldRec.Id));
                } else {
                    recallParentIds.add(oldRec.Id);
                    System.debug('~~~~ FileLinkServiceEventTriggerHandler::compareFileLinkCount: added oldRec.Id to recallParents = ' + oldRec.Id);
                }
            }
        }

        //-- loop through queries
        //-- compare link number to actual count
        //-- if count different, put in list to recall link service, else add to list of records to update
        //-- if records to update, update records
        saveParentRecordsWithFileLinks(recsToUpdateLst);
        recallFileLinkServiceForParentIds(recallParentIds);
    }

    @TestVisible
    private static void saveParentRecordsWithFileLinks(List<SObject> recsToUpdateLst) {
        List<Id> errorIdLst = new List<Id>();
        List<Integer> statusCodeLst = new List<Integer>();
        List<String> messageLst = new List<String>();
        List<String> recordLst = new List<String>();
        Integer i=0;
        
        if (!recsToUpdateLst.isEmpty()) {
            Database.SaveResult[] resultLst = Database.update(recsToUpdateLst, false);
            for (Database.SaveResult sr : resultLst) {
                System.debug('~~~~ FileLlinkEventTriggerHandler::saveParentRrecordWithFileLinks: recsToUpdateLst[i] - ' + recsToUpdateLst[i]);
                System.debug('~~~~ FileLlinkEventTriggerHandler::saveParentRrecordWithFileLinks: sr - ' + sr);
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        errorIdLst.add(sr.getId());
                        statusCodeLst.add(500);
                        messageLst.add('Status Code: ' + err.getStatusCode() + ', Message: ' + err.getMessage()+ '. The fields that impact this are ' + err.getFields());
                        recordLst.add((String)JSON.serialize(recsToUpdateLst[i]));
                    }
                }
                i++;
            }
        }

        if (!errorIdLst.isEmpty()) {
            BoltLogPublisherService.publishBoltMultipleErrorEvents(statusCodeLst,
                                                                    messageLst, 
                                                                    recordLst, 
                                                                    BoltConstants.SF_TO_BOLT, 
                                                                    'updateSObjectRecs',
                                                                    errorIdLst, 
                                                                    'FileLinkServiceTriggerHandler');
        }
    }

    @TestVisible
    private static void recallFileLinkServiceForParentIds(Set<Id> recallParentIds) {
        //-- if records to reprocess, reprocess records
        if (!recallParentIds.isEmpty()) {
            //Integer start = System.Now().millisecond();
            //while(System.Now().millisecond()< start+500){}
            FileLinkQueueable flq = new FileLinkQueueable([SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN: recallParentIds ]);
            String jobId = System.enqueueJob(flq);
        }        
    }
}