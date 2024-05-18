/**
 * @description       : The selection criteria for Content Document Link records
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-09-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionFileLinksContentDocumentLinks extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        recIds.addAll(newById.keySet());
    }
}