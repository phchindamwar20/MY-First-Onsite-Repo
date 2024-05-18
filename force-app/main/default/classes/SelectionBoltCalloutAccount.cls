/**
 * @description       : This is the selection criteria utlized to select records for the SF=>Bolt createAccount callout
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-06-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionBoltCalloutAccount extends SelectionBase{
    
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {

        if (BoltCallouts.integrateWithBolt()) {
            for (Account acc : (List<Account>)newById.values()) {
                //System.debug('~~~~ SelectionBoltCalloutAccount::getRecordsToProcess: acc - ' + acc);
                
                Account oldAcc = oldById != null && oldById.containsKey(acc.Id) ? (Account)oldById.get(acc.Id) : null;
                //System.debug('~~~~ SelectionBoltCalloutAccount::getRecordsToProcess: oldAcc - ' + oldAcc);
                
                if (isIntegrateWithBoltAccount(acc,oldAcc)) {
                    recIds.add(acc.Id);
                }
            }
        }
    }
    
    @TestVisible
    private Boolean isIntegrateWithBoltAccount(Account newAcc, Account oldAcc) {
        Boolean isBoltAccount = false;

        if (newAcc.RecordTypeId == GeneralConstants.RT_ID_ACC_ACCOUNT) {
            if (oldAcc == null && newAcc.ParentId == null) {
                //This is a new account and should be sent to bolt
                //New accounts that have Parent Ids need to go to Ultimate Parent for processing first, then Bolt
                isBoltAccount = true;
            } else if (oldAcc != null && 
                        newAcc.Name == oldAcc.Name && 
                        newAcc.ParentId == oldAcc.ParentId && 
                        oldAcc.RecordTypeId != GeneralConstants.RT_ID_ACC_PROPERTY && 
                        BoltCallouts.isChangeInRecord(newAcc, oldAcc, BoltConstants.WS_BOLT_ACCOUNT)){
                //This is an update to an account that is already integrated with bolt.  We only send the updated account to Bolt if a field that we are integrating with has changed.
                //The following special rules apply
                //- Name must be the same, else it needs to go to the Ultimate Parent for processing first then Bolt
                //- Parent must be the same, else it needs to go to the Ultimate Parent for processing first then Bolt
                //- Old Account's RecordTypeId must not be PropertyId, else it needs to go to the Ultimate Parent for first processing then Bolt
                isBoltAccount = true;
            }    
        } 

        return isBoltAccount;
    }
}