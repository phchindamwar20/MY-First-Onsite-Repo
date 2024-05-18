/**
 * @description       : This is the Selection Criteria for the Area Wide Event
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-06-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionBoltCalloutAreaWideEvent extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {

        //Check Bolt hierarchy custom setting to see if user is allowed to send records to bolt
        if (BoltCallouts.integrateWithBolt()) {
            for (Area_Wide_Event__c awe : (List<Area_Wide_Event__c>)newById.values()) {
                Area_Wide_Event__c oldAwe = oldById != null && oldById.containsKey(awe.Id) ? (Area_Wide_Event__c)oldById.get(awe.Id) : null;
                //System.debug('~~~~ SelectionBoltCalloutAccount::getRecordsToProcess: oldAcc - ' + oldAcc);  

                if (isBoltAWE(awe, oldAwe)) {
                    recIds.add(awe.Id);
                }
            }
        }
    }

    @TestVisible
    private Boolean isBoltAWE(Area_Wide_Event__c newAwe, Area_Wide_Event__c oldAwe){
        Boolean isBoltAwe = false;

        if (oldAwe == null) {
            //This is a new awe and should be sent to bolt
            isBoltAwe = true;
        } else if (oldAwe != null && BoltCallouts.isChangeInRecord(newAwe, oldAwe, BoltConstants.WS_BOLT_AREA_WIDE_EVENT)){
            //This is an update to an awe that is already integrated with bolt.  We only send the updated awe to Bolt if a field that we are integrating with has changed.
            isBoltAwe = true;
        }   
        
        return isBoltAwe;
    }
}