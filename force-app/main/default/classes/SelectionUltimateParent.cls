/**
 * @description       : This is the selection criteria for determining account records to calculate the ultimate parent hierarchy on the account,
 *                      If there are records available for, they will be sent to the UltimateParentRollupCalculationQueueable.  Then, the UltimateParentRollupCalculationQueueable 
 *                      will dynamically add the BoltEnigineQueueable dynamically to the Execution Item List to send the accounts to Bolt for processing
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionUltimateParent extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for (Account acc : (List<Account>)newById.values()) {
            //System.debug('~~~~ SelectionUltimateParent::getRecordsToProcess: acc - ' + acc);
            
            Account oldAcc = oldById != null && oldById.containsKey(acc.Id) ? (Account)oldById.get(acc.Id) : null;
            //System.debug('~~~~ SelectionUltimateParent::getRecordsToProcess: oldAcc - ' + oldAcc);

            if (isUltimateParentCalRequired(acc, oldAcc)) {
                recIds.add(acc.Id);
            }
        }
    }

    @TestVisible 
    private Boolean isUltimateParentCalRequired(Account acc, Account oldAcc) {
        Boolean isUltimateParentCalculationRequired = false;

        if (acc != null && (acc.RecordTypeId == GeneralConstants.RT_ID_ACC_PARENT || acc.RecordTypeId == GeneralConstants.RT_ID_ACC_ACCOUNT)) {
            if (oldAcc == null && acc.ParentId != null) {
                //this is a new account record with a parent account
                isUltimateParentCalculationRequired = true;
            } else if (oldAcc != null) {
                if (acc.ParentId != oldAcc.ParentId) {
                    //there has been a change in the parent account
                    isUltimateParentCalculationRequired = true;
                } else if (acc.Name != oldAcc.Name) {
                    //there has been a change in the name of a parent account
                    //these need to be re-calculated even though there is no change in hierarchy so we can later re-send to Bolt.
                    //formula fields don't cause field changes
                    isUltimateParentCalculationRequired = true;
                } else if (oldAcc.RecordTypeId == GeneralConstants.RT_ID_ACC_PROPERTY) {
                    // the record type changed from a property type, that means we need to calculate the ultimate parent for it
                    isUltimateParentCalculationRequired = true;
                }
            }
        }   
        
        return isUltimateParentCalculationRequired;
    }
}