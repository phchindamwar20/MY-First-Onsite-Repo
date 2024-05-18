/**
 * @description       : This is the selection criteria for the SF=>Bolt deleteAccounts integration when the record type of an account changed from Account Record type
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionBoltCalloutChangeFromAccountRT extends SelectionBase {

    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        //Check Bolt hierarchy custom setting to see if user is allowed to send records to bolt
        if (BoltCallouts.integrateWithBolt()) {
            for (Account newAcc : (List<Account>)newById.values()) {
                Account oldAcc = oldById != null && oldById.containsKey(newAcc.Id) ? (Account)oldById.get(newAcc.Id) : null;

                if (isBoltChngAccRtToDelete(newAcc, oldAcc)) {
                    recIds.add(newAcc.Id);
                }                
            }
        }
    }

    @TestVisible
    private Boolean isBoltChngAccRtToDelete(Account newAcc, Account oldAcc) {
        Boolean isSendToBoltForDelete = false;

        if (newAcc != null && oldAcc != null && 
            newAcc.RecordTypeId != GeneralConstants.RT_ID_ACC_ACCOUNT &&  
            oldAcc.RecordTypeId == GeneralConstants.RT_ID_ACC_ACCOUNT) {
            isSendToBoltForDelete = true;
        } 

        return isSendToBoltForDelete;
    }
}