/**
 * @description       : This is the selection criteria for calculating the match name used to prevent creation of duplicate accounts
 *                      Only after updates are handled.  New accounts are handled in the flow because this needs to be set before the record is saved.  
 *                      Unfortunately, because match name is dependent on the ultimate parent, we can only do that calculation after save for updates.
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionMatchNameAccount extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for (Account acc : (List<Account>)newById.values()) {
            Account oldAcc = oldById != null && oldById.containsKey(acc.Id) ? (Account)oldById.get(acc.Id) : null;

            if (addIdForMatchName(acc, oldAcc) == true) {
                recIds.add(acc.Id);
            }
        }
    }

    @TestVisible
    private Boolean addIdForMatchName(Account newAcc, Account oldAcc) {
        Boolean result = false;
        if (newAcc != null) {
            if (oldAcc == null) {
                //this is a new account that needs a match name
                result = true;
            } else if (newAcc != null && oldAcc != null && 
                (
                    newAcc.Name != oldAcc.Name ||
                    newAcc.RecordTypeId != oldAcc.RecordTypeId ||
                    newAcc.Active__c != oldAcc.Active__c ||
                    newAcc.ShippingStateCode != oldAcc.ShippingStateCode ||
                    newAcc.ShippingCity != oldAcc.ShippingCity ||
                    newAcc.ShippingStreet != oldAcc.ShippingStreet ||
                    newAcc.ParentId != oldAcc.ParentId ||
                    newAcc.The_Ultimate_Parent_Account__c != oldAcc.The_Ultimate_Parent_Account__c ||
                    newAcc.Inactive_Date__c != oldAcc.Inactive_Date__c
                )
            ) {
                result = true;
            }
        }
        return result;
    }
}