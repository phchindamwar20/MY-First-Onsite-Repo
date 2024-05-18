/**
 * @description       : This is the selection criteria for creating campaign members based on the Campaign name set in th Maps Campaign Trigger field
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionMapCampaignMember extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for (Account newAcc : (List<Account>)newById.values()) {
            Account oldAcc = oldById != null && oldById.containsKey(newAcc.Id) ? (Account)oldById.get(newAcc.Id) : null;

            if (isSelectionCriteriaMet(newAcc, oldAcc)) {
                recIds.add(newAcc.Id);
            }
        }
    }

    @TestVisible
    private Boolean isSelectionCriteriaMet(Account newAcc, Account oldAcc) {
        Boolean isRecForSelection = false;
        if (newAcc != null && 
            oldAcc != null && 
            newAcc.Maps_Campaign_Trigger__c != oldAcc.Maps_Campaign_Trigger__c) {
            isRecForSelection = true;
        }       
        return isRecForSelection; 
    }
}