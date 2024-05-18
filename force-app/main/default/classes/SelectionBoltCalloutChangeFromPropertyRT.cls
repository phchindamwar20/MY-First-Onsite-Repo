/**
 * @description       : This is the selection criteria for the SF=>Bolt deleteProperties integration when the record type of an account changed from Property Record type
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionBoltCalloutChangeFromPropertyRT extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        //Check Bolt hierarchy custom setting to see if user is allowed to send records to bolt
        if (BoltCallouts.integrateWithBolt()) {
            for (Account newProp : (List<Account>)newById.values()) {
                Account oldProp = oldById != null && oldById.containsKey(newProp.Id) ? (Account)oldById.get(newProp.Id) : null;

                if (isChngFromPropAccToDeleteFromBolt(newProp, oldProp)) {
                    recIds.add(newProp.Id);
                }                
            }
        }
    }

    @TestVisible
    private Boolean isChngFromPropAccToDeleteFromBolt(Account newProp, Account oldProp) {
        Boolean isSendToBoltForDelete = false;

        if (newProp != null && 
            oldProp != null && 
            oldProp.RecordTypeId == GeneralConstants.RT_ID_ACC_PROPERTY && 
            newProp.RecordTypeId != GeneralConstants.RT_ID_ACC_PROPERTY) {
            isSendToBoltForDelete = true;
        } 

        return isSendToBoltForDelete;
    }
}