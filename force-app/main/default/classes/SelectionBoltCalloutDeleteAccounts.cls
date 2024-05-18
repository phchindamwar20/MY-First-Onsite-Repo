/**
 * @description       : This is the selection criteria for deleting accounts from bolt if an account record is deleted from salesforce with an account record type.  These records are used in the deleteAccounts SF=>Bolt callout
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionBoltCalloutDeleteAccounts extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        //Check Bolt hierarchy custom setting to see if user is allowed to send records to bolt
        if (BoltCallouts.integrateWithBolt()) {
            for (Account oldAcc : (List<Account>)oldById.values()) {
                //System.debug('~~~~ SelectionBoltCalloutDeleteAccounts::getRecordsToProcess: acc - ' + oldAcc);
                
                if (isDeleteAccFromBolt(oldAcc)) {
                    recIds.add(oldAcc.Id);    
                } 
            }
        }
    }

    @TestVisible
    private Boolean isDeleteAccFromBolt(Account oldAcc) {
        Boolean isDelete = false;

        if (oldAcc != null && oldAcc.RecordTypeId == GeneralConstants.RT_ID_ACC_ACCOUNT) {
            isDelete = true;    
        } 

        return isDelete;
    }
}