/**
 * @description       : This is the selection criteria for deleting properties from bolt if an account record is deleted from salesforce with a property record type.  These records are used in the SF=>Bolt deleteProperties callout
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionBoltCalloutDeleteProperties extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        if (BoltCallouts.integrateWithBolt()) {
            for (Account oldProp : (List<Account>)oldById.values()) {
                //System.debug('~~~~ SelectionBoltCalloutDeleteProperties::getRecordsToProcess: oldProp - ' + oldProp);
                
                if (isCriteriaMet(oldProp)) {
                    recIds.add(oldProp.Id);    
                } 
            }
        }
    }

    @TestVisible
    private Boolean isCriteriaMet(Account oldProp) {
        Boolean isRecForSelection = false;
        if (oldProp != null && oldProp.RecordTypeId == GeneralConstants.RT_ID_ACC_PROPERTY) {
            isRecForSelection = true;    
        } 
        return isRecForSelection;
    }
}