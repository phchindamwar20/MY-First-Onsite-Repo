/**
 * @description       : This is the selection criteria utlized to select records for the SF=>Bolt sendProperties callout
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-07-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionBoltCalloutProperty extends SelectionBase{
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {

        if (BoltCallouts.integrateWithBolt()) {
            for (Account prop : (List<Account>)newById.values()) {
                //System.debug('~~~~ SelectionBoltCalloutProperty::getRecordsToProcess: prop - ' + prop);
                
                Account oldProp = oldById != null && oldById.containsKey(prop.Id) ? (Account)oldById.get(prop.Id) : null;
                //System.debug('~~~~ SelectionBoltCalloutProperty::getRecordsToProcess: oldProp - ' + oldProp);

                if (isBoltPropertyRec(prop, oldProp)) {
                    recIds.add(prop.Id);
                }
            }
        }
    }

    @TestVisible
    private Boolean isBoltPropertyRec(Account newProp, Account oldProp) {
        Boolean isBoltProperty = false;

        if (newProp.RecordTypeId == GeneralConstants.RT_ID_ACC_PROPERTY) {
            if (oldProp == null ) {
                //This is a new account and should be sent to bolt
                isBoltProperty = true;
            } else if (oldProp != null && BoltCallouts.isChangeInRecord(newProp, oldProp, BoltConstants.WS_BOLT_PROPERTY)){
                //This is an update to an account that is already integrated with bolt.  We only send the updated account to Bolt if a field that we are integrating with has changed.
                isBoltProperty = true;
            }    
        } 
        
        return isBoltProperty;
    }
}