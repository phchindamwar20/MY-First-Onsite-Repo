/**
 * @description       : 1. When a new file link comes in as an attachment associated with an email, if that email is related to a job or contract, 
 *                         it associates the file with the job or contract.  An admin can modify this to associate email files with other parent objects by
 *                         adding the object api name to the ParentEmailFileObject custom metadata type
 *                      2. Calls the file link service that builds a list of html file links on the parent object the file is associated with
 *                      3. Sets the file visibility to ALL Users for new Content Document Records that are associated with Object Types 
 *                          that are listed in the File Visibility Custom Metadata Types
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 10-02-2023
 * @last modified by  : Terri Jiles
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   08-02-2021   TJiles                               Initial Version
**/
public without sharing class ContentDocumentLinkTriggerHandler extends TriggerHandlerBase {
    private Set<String> objPrefixes = getFileVisibilityPrefixes();
    
    //STAR-5276
    public override void beforeInsert(SObject[] newItems) {
        updateFileVisibility((List<ContentDocumentLink>)newItems);
    }

    //STAR-5276
    public override void beforeInsert(SObject[] newItems, Integer executionNumber) {
        updateFileVisibility((List<ContentDocumentLink>)newItems);
    }

    public override void afterInsert(Map<Id, SObject> newItems) {
        List<ContentDocumentLink> parentFileLinkLst = createLinksToParents ((List<ContentDocumentLink>)newItems.values());
        if (parentFileLinkLst != null && !parentFileLinkLst.isEmpty()) {
            insert parentFileLinkLst;
        }
    }

    public override void afterInsert(Map<Id, SObject> newItems, Integer execution) {
        List<ContentDocumentLink> parentFileLinkLst = createLinksToParents ((List<ContentDocumentLink>)newItems.values());
        if (!parentFileLinkLst.isEmpty()) {
            insert parentFileLinkLst;
        }
    } 

    private void updateFileVisibility(List<ContentDocumentLink> fileLst) {

        if (!objPrefixes.isEmpty()) {
            for (ContentDocumentLink file : fileLst) {
                if (file.LinkedEntityId != null && objPrefixes.contains(((String)file.LinkedEntityId).left(3))) {
                    file.Visibility='AllUsers';
                }
            }
        }
    }

    private Set<String> getFileVisibilityPrefixes() {
        Set<String> objPrefixes = new Set<String>();
        for (File_Visibility__mdt fv : [SELECT 
                                            Record_Prefix__c, DeveloperName, Object_API_Name__c 
                                        FROM File_Visibility__mdt ]) {
            objPrefixes.add(fv.Record_Prefix__c);
        }

        return objPrefixes;
    }

    private List<ContentDocumentLink> createLinksToParents (List<ContentDocumentLink> fileLst) {
        Set<Id> emailMsgIds = new Set<Id>();
        Map<String, String> objectByRecordPrefix = new Map<String, String>();
        Map<Id, ContentDocumentLink> fileById = new Map<Id, ContentDocumentLink>();
        Map<Id, EmailMessage> emailMessageById = new Map<Id, EmailMessage>();
        List<ContentDocumentLink> parentFileLinkLst = new List<ContentDocumentLink>();

        System.debug('~~~~ ContentDocumentLiinkTriggerHandler::findParents: fileLst.size() - ' + fileLst.size());

        //Get prefixes of the parents we care about to create a link of an EmailMessage's file to an EmailMessage's parent (RelatedTo)
        //As of 8/2/2021, we care only about Jobs and Contracts
        for (ParentEmailFileObject__mdt prefix : [SELECT DeveloperName, Record_Prefix__c FROM ParentEmailFileObject__mdt]) {
            System.debug('~~~~ ContentDocumentLiinkTriggerHandler::findParents: prefix mapping: prefix - ' + prefix.Record_Prefix__c + ', Object - ' + prefix.DeveloperName);
            objectByRecordPrefix.put(prefix.Record_Prefix__c, prefix.DeveloperName);
        }

        for (ContentDocumentLink file : fileLst) {
            //if it is associated with an emailMessage, get record
            System.debug('~~~~ ContentDocumentLiinkTriggerHandler::findParents: file - ' + file);
            System.debug('~~~~ ContentDocumentLiinkTriggerHandler::findParents: file.LinkedEntityId - ' + file.LinkedEntityId);
            if (((String)file.LinkedEntityId).left(3) == '02s') {
                emailMsgIds.add(file.LinkedEntityId);
                fileById.put(file.Id, file);
                System.debug('~~~~ ContentDocumentLiinkTriggerHandler::findParents: Is an EmailMessage! - ');
            }
        }
        System.debug('~~~~ ContentDocumentLiinkTriggerHandler::findParents: emailMsgIds.size() - ' + emailMsgIds.size());

        if (!emailMsgIds.isEmpty()) {
            for (EmailMessage emailMsg : [SELECT Id, RelatedToId FROM EmailMessage WHERE Id In: emailMsgIds]) {
                //Get desirable relatedTos from EmailMessage's. As of 8/2/2021, we care about obtaining parents that are Jobs and Contracts only
                if (emailMsg.RelatedToId != NULL && objectByRecordPrefix.containsKey(((String)emailMsg.RelatedToId).left(3))) {
                    emailMessageById.put(emailMsg.Id, emailMsg);
                }
            }

            //As of 8/2/2021, create file links for parents that are Jobs and Contracts
            for (ContentDocumentLink file : fileLst) {
                if (fileById.containsKey(file.Id)) {
                    if (emailMessageById.containsKey(file.LinkedEntityId)) {
                        parentFileLinkLst.add(new ContentDocumentLink(ContentDocumentId=file.ContentDocumentId, LinkedEntityId=emailMessageById.get(file.LinkedEntityId).RelatedToId));
                    }
                }
            }
        }
        return parentFileLinkLst;
    }
    
}