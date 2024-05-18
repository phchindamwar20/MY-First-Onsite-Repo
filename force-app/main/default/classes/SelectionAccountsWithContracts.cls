/**
 * @description       : This selection class gets all account ids that have client contract ids
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-06-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionAccountsWithContracts extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for (Account acc : [SELECT Id, Status__c, Contract_Type__c, 
                                    (SELECT Id FROM Contracts WHERE RecordTypeId =: GeneralConstants.RT_ID_CONTRACT_CLIENT ) 
                                    FROM Account 
                                    WHERE Id IN: newById.values()]) {

            Account oldAcc = oldById != null && oldById.containsKey(acc.Id) ? (Account)oldById.get(acc.Id) : null;

            //get all acc ids that have client record types associated with them
            if (isCriteriaMet(acc, oldAcc)) {            
                recIds.add(acc.Id);
            }
        }
    }

    @TestVisible
    private Boolean isCriteriaMet(Account newAcc, Account oldAcc) {
        Boolean criteriaMet = false;

        if (!newAcc.Contracts.isEmpty()) {
            if (oldAcc == null) {
                criteriaMet = true;
            } else if (
                        (
                            newAcc.Status__c != oldAcc.Status__c && 
                            newAcc.Status__c == GeneralConstants.ACC_STATUS_UNQUALIFIED
                        ) ||
                        newAcc.Contract_Type__c != oldAcc.Contract_Type__c
                    ) {
                criteriaMet = true;
            }
        }

        return criteriaMet;
    }
}