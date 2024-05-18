/**
 * @description       : After Delete of files, updates the html list of file links on the parent record
 *                    : After Undelete of files, restores the html list of file links on the parent record
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-04-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class ContentDocumentTriggerHandler extends TriggerHandlerBase {
    //
    /***** 
     * Our users utilize the lightning interface
     * ContentDocument and ContentDocumentLink trigger behavior in Classic and Lightning 
     * https://help.salesforce.com/s/articleView?id=000381623&type=1
     * Per Salesforce: 
     * ' The following behavior applies to the deletion of a file attached to a record:
     *   - In Classic, ContentDocument triggers do not fire, as Salesforce only deletes the associated ContentDocumentLink record, not the ContentDocument record.
     *   - In Lightning Experience, both the ContentDocument and related ContentDocumentLink records are deleted, and by design Salesforce only fires the trigger on ContentDocument, not the trigger on ContentDocumentLink.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_recovered_records.htm
     * 
     * The test class for this trigger is in apex class FileLinkServiceTest, method testFileLinksDelete
     *****
    */
    private static List<ContentDocumentLink> contentDocumentLinkLst = new List<ContentDocumentLink>();

    public override void beforeDelete(Map<Id, SObject> oldItems) {
        Set<Id> contentDocumentIds = oldItems.keySet();

        contentDocumentLinkLst = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: contentDocumentIds];
    }

    public override void afterDelete(Map<Id, SObject> oldItems) {
        FileLinkService.buildFileLinks(contentDocumentLinkLst);
    }

    public override void afterUndelete(Map<Id, SObject> oldItems) {
        Set<Id> contentDocumentIds = oldItems.keySet();

        System.debug('~~~~ ContentDocumentTriggerHandler::afterUndelete: Inside');
        contentDocumentLinkLst = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: contentDocumentIds];        
        System.debug('~~~~ ContentDocumentTriggerHandler::afterUndelete: Number of ContentDocumentLinks - ' + contentDocumentLinkLst.size());
        FileLinkService.buildFileLinks(contentDocumentLinkLst);
    }
}