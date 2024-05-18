/**
 * @description       : The FileLinksService class 
 *                          1. takes content documents links associated with a given linked entity type specified by the FileLinkServiceConfiguration__mdt, 
 *                          2. creates a publically available link via Content Distribution, 
 *                          3. contructs a list of html url links
 *                          4. updates the Linked Entity's File Links Rich text field and other info specified by FileLinkServiceConfiguration__mdt
 *                          5. raises platform event to send records for processing
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-30-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class FileLinkService {    
    public static void  buildFileLinks(List<ContentDocumentLink> contentDocumentLinkOrgLst) {
        try {
            //build file link service configuration list
            //collect Content Document Link's Linked Entity Id if it is in the Set of Object Prefixes in the fileLinkConfigByRecPrefix
            Set<Id> linkedEntityIds = new Set<Id>();
            for (ContentDocumentLink cdl :  contentDocumentLinkOrgLst) {
                String recId = (String)cdl.LinkedEntityId;
                String objectPrefix = recId.left(3);
                if (FileLinkConfiguration.isValidFileLinkObjectType(recId)) {
                    linkedEntityIds.add(cdl.LinkedEntityId);
                }
            }

            if (!linkedEntityIds.isEmpty()) {
                //get all Content Document Link's record that are related to the identified Linked Entity Ids
                List<ContentDocumentLink> contentDocumentLinkLst = getRelatedLinkedEntityIds(linkedEntityIds); 
                //Get content document ids
                Set<Id> contentDocumentIds = new Set<Id>();
                for (ContentDocumentLink cd : contentDocumentLinkLst) {
                    contentDocumentIds.add(cd.ContentDocumentId);
                }
                //Get Content Versions
                Map<Id, ContentVersion> contentVersionByContentDocumentId = getRelatedContentVersionsFromContentDocumentIds(contentDocumentIds);
                //get or create content distributions
                Map<Id, ContentDistribution> contentDistributionByVersionId = getOrCreateContentDistributions(contentVersionByContentDocumentId);
                //make list of html links on parent records
                Map<Id, List<String>> urlLstByLinkedEntity = makeListOfLinks(contentDistributionByVersionId, contentDocumentLinkLst,  contentVersionByContentDocumentId);
                //add linkedEntityIds that don't have html links
                //this handles the case when we delete the only file associated with a given parent record and this would result in NO links on the record
                for (Id linkedEntityId : linkedEntityIds) {
                    if (!urlLstByLinkedEntity.containsKey(linkedEntityId)) {
                        urlLstByLinkedEntity.put(linkedEntityId, null);
                    }
                }

                //update parent records
                updateParentListWithLinks(urlLstByLinkedEntity);
            }
        } catch (Exception e) {
            //System.debug('~~~~ FileLinkService::buildFileLinks: Message - ' + e.getMessage());
            //System.debug('~~~~ FileLinkService::buildFileLinks: Cause - ' + e.getCause());
            //System.debug('~~~~ FileLinkService::buildFileLinks: Line Number - ' + e.getLineNumber());
            //System.debug('~~~~ FileLinkService::buildFileLinks: Stack trace - ' + e.getStackTraceString());
            throw new FileLinkService.FileLinkServiceException(Label.FILE_LINKS_ERROR);
        }
    }

    private static List<ContentDocumentLink>  getRelatedLinkedEntityIds(Set<Id> linkedEntityIds) {
        List<ContentDocumentLink> cdlLst = [SELECT LinkedEntityId, 
                                                    ContentDocumentId, 
                                                    ContentDocument.LatestPublishedVersionId, 
                                                    ContentDocument.Title, 
                                                    ContentDocument.FileExtension, 
                                                    ContentDocument.ContentSize 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId IN:linkedEntityIds 
                                            FOR UPDATE];


        /*
        for (ContentDocumentLink cdl : cdlLst) {
            System.debug('~~~~ FileLinkService::getRelatedLinkedEntityIds: cdl - ' + cdl);
        }
        */

        return cdlLst;
    }

    private static Map<Id, ContentVersion> getRelatedContentVersionsFromContentDocumentIds(Set<Id> contentDocumentIds) {
        Map<Id, ContentVersion> contentVersionByContentDocumentId = new Map<Id, ContentVersion>();
        
        for (ContentVersion cv : [SELECT Id, 
                                        ContentDocumentId, 
                                        Title, 
                                        FileExtension, 
                                        ContentSize 
                                    FROM ContentVersion 
                                    WHERE ContentDocumentId IN: contentDocumentIds]) {
            //System.debug('~~~~ FileLinkService::getRelatedContentVersionsFromContentDocumentIds: Get content version\'s Id using the content document rec cd - ' + cv);
            contentVersionByContentDocumentId.put(cv.ContentDocumentId, cv);
        }

        return contentVersionByContentDocumentId;
    }

    private static Map<Id, ContentDistribution>  getOrCreateContentDistributions(Map<Id, ContentVersion> contentVersionByContentDocumentId) {
        Map<Id, ContentDistribution> contentDistributionByVersionId = new Map<Id, ContentDistribution>();
        Set<Id> contentVersionIds = new Set<Id>();
        List<ContentDistribution> newContentDistributionLst = new List<ContentDistribution>();

        for (ContentVersion cv : contentVersionByContentDocumentId.values()) {
            //System.debug('~~~~ FileLinkService::getOrCreateContentDistributions: Get content version\'s Id cv - ' + cv);
            contentVersionIds.add(cv.Id);
        }

        //get existing content distributions
        for (ContentDistribution cd : [SELECT ContentVersionId, ContentDownloadURL, DistributionPublicUrl, ExpiryDate, PreferencesExpires 
                                        FROM ContentDistribution 
                                        WHERE ContentVersionId IN: contentVersionIds]) {
            //System.debug('~~~~ FileLinkService::getOrCreateContentDistributions: Add existing ContentDistribution rec to map cd - ' + cd);
            contentDistributionByVersionId.put(cd.ContentVersionId, cd);
        }

        //determine if content distribution doesn't exists for corresponding content document link's content version, if it doesn't create it
        for (ContentVersion cd : contentVersionByContentDocumentId.values()) {
            if (!contentDistributionByVersionId.containsKey(cd.Id)) {
                //System.debug('~~~~ FileLinkService::getOrCreateContentDistributions: creating new ContentDistribution rec');
                newContentDistributionLst.add(new ContentDistribution(Name=cd.Title, ContentVersionId=cd.Id, ExpiryDate=null, PreferencesExpires=false));
            }
        }

        //create content distributions and add to map
        if (!newContentDistributionLst.isEmpty()) {
            insert newContentDistributionLst;
            
            Set<Id> newCdIds = new Set<Id>();
            for (ContentDistribution cd : newContentDistributionLst) {
                //System.debug('~~~~ FileLinkService::getOrCreateContentDistributions: get inserted content distribution\'s rec id - ' + cd.Id);
                newCdIds.add(cd.Id);
            }

            for (ContentDistribution cd : [SELECT ContentVersionId, ContentDownloadURL, DistributionPublicUrl 
                                            FROM ContentDistribution 
                                            WHERE Id IN: newCdIds]) {
                //System.debug('~~~~ FileLinkService::getOrCreateContentDistributions: add new ContentDistribution rec to map: cd - ' + cd);
                contentDistributionByVersionId.put(cd.ContentVersionId, cd);
            }
        }

        return contentDistributionByVersionId;
    }

    private static Map<Id, List<String>> makeListOfLinks(Map<Id, ContentDistribution> contentDistributionByVersionId, List<ContentDocumentLink> contentDocumentLinkLst, Map<Id, ContentVersion> contentVersionByContentDocumentId) {
        Id linkedEntityId = null;
        Map<Id, List<String>> urlLstByLinkedEntity = new Map<Id, List<String>>();

        //construct list of html links for a given linked entity id
        for (ContentDocumentLink cdl :contentDocumentLinkLst) {
            //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords: beginning of for loop');
            //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords:linkedEntityId before if ' + linkedEntityId);
            if (cdl.LinkedEntityId != linkedEntityId && !urlLstByLinkedEntity.containsKey(cdl.LinkedEntityId)) {
                linkedEntityId = cdl.LinkedEntityId;
                List<String> htmlLinkLst = new List<String>();
                //htmlLinkLst.add(htmlLink);
                urlLstByLinkedEntity.put(linkedEntityId, htmlLinkLst);
                //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords:linkedEntityId after if ' + linkedEntityId);
            } 

            //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords: ContentDocumentLink - cdl ' + cdl);
            //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords: contentVersionByContentDocumentId.containsKey - ' + contentVersionByContentDocumentId.containsKey(cdl.ContentDocumentId));
            Id contentVersionId = contentVersionByContentDocumentId.get(cdl.ContentDocumentId).Id;
            String fileName = contentVersionByContentDocumentId.get(cdl.ContentDocumentId).Title + '.' + contentVersionByContentDocumentId.get(cdl.ContentDocumentId).FileExtension;
            //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecord: fileName - ' + fileName);
            String htmlLink = '<li><a href=\"' + 
                                contentDistributionByVersionId.get(contentVersionId).DistributionPublicUrl +
                                '\" target=\"_blank\">' +
                                fileName +
                                '</a></li>';
            urlLstByLinkedEntity.get(linkedEntityId).add(htmlLink);
            //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords: linked entity id - ' + linkedEntityId + ' and the htmlLink - ' + htmlLink);
            //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords: urlLstByLinkedEntity.get(linkedEntityId) - ' + urlLstByLinkedEntity.get(linkedEntityId));
            //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords: end of for loop');
        }

        return urlLstByLinkedEntity;
    }


    private static List<SObject> addListOfLinksToParentRecords(Map<Id, List<String>> urlLstByLinkedEntity) { 
        List<SObject> parentRecLst = new List<SObject>();
        Id lastUpdatedByUserId = UserInfo.getUserId();

        //construct html link list for a linked entity ids's field
        for (Id linkedEntityRecId : urlLstByLinkedEntity.keySet()) {
            String fileLinksValue = null;

            if (urlLstByLinkedEntity.get(linkedEntityRecId) != null && !urlLstByLinkedEntity.get(linkedEntityRecId).isEmpty()) {
                fileLinksValue = '<ol>';
                for (String htmlLink : urlLstByLinkedEntity.get(linkedEntityRecId)) {
                    //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords: htmlLink - ' + htmlLink);
                    fileLinksValue += htmlLink;
                }
                fileLinksValue +='</ol>';
            } else {
                //In this case, a delete of the only file associated with the parent record occurred, thus we should clear out the list of html links
                fileLinksValue = null;
            }
            //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords: html link list - ' + fileLinksValue);
            //System.debug('~~~~ FileLinkService::makeListOfLinksOnParentRecords: linked entity id - ' + linkedEntityRecId + ' and the html links field value - ' + fileLinksValue);
            Integer numberOfLinks = !urlLstByLinkedEntity.isEmpty() && urlLstByLinkedEntity.get(linkedEntityRecId) != null ? urlLstByLinkedEntity.get(linkedEntityRecId).size() : 0;
            
            //if (!String.isBlank(fileLinksValue)) {
                SObject thisRecord = FileLinkConfiguration.setParentRecord(linkedEntityRecId, fileLinksValue, numberOfLinks);
                
                parentRecLst.add(thisRecord);
            //}
        }

        return parentRecLst;
    }

    private static void updateParentListWithLinks(Map<Id, List<String>> urlLstByLinkedEntity) {
        //add list of links to parent records
        List<SObject> parentRecLst = addListOfLinksToParentRecords(urlLstByLinkedEntity);
        
        //call publisher
        List<FileLinkObject> fileLinkObjLst = new List<FileLinkObject>();
        for (SObject rec : parentRecLst) {
            fileLinkObjLst.add(new FileLinkObject(rec));
        }
    
        if (!fileLinkObjLst.isEmpty()) {
            FileLinkServicePublisher.publishFileLinkServiceEvents(fileLinkObjLst);
        }
    }

    public class FileLinkServiceException extends Exception {}
}