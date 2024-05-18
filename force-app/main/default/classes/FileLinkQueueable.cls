/**
 * @description       : This calls the FilLinkService in a Queueable class.  
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-10-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class FileLinkQueueable extends GenericQueueable {
    public List<ContentDocumentLink> cdlLst = new List<ContentDocumentLink>();

    public FileLinkQueueable(List<ContentDocumentLink> cdlLst) {
        this.cdlLst = cdlLst;
    }

    public FileLinkQueueable(){}

    public override void execute (QueueableContext context) {
        try {
            if (cdlLst.isEmpty() && !currentSelection.getRecIds().isEmpty()) {
                cdlLst = new List<ContentDocumentLink>([SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE Id IN : currentSelection.getRecIds()]);
            } 

            FileLinkService.buildFileLinks(cdlLst);
        } catch (FileLinkService.FileLinkServiceException e) {
            throw new FileLinkService.FileLinkServiceException(e.getMessage());
        } finally {
            handleNext();
        }
    }
    
    public override void handleError(Exception e) {
        throw new FileLinkService.FileLinkServiceException(e.getMessage());
    }
}