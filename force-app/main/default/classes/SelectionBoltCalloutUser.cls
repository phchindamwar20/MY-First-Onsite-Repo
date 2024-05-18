/**
 * @description       : This is the selection criteria used to send users to Bolt when an admin creates a new user with an existing Bolt Key and ADP Associate OID
 *                      OR updates an existing user's record with the info
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 02-01-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionBoltCalloutUser extends SelectionBase{
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {

        if (BoltCallouts.integrateWithBolt()) {
            for (User newUser : (List<User>)newById.values()) {
                User oldUser = (User)oldById?.get(newUser.Id);
                if (selectBoltUser(newUser, oldUser)) {
                    recIds.add(newUser.Id);
                }
            }
        }
    }

    @TestVisible
    Boolean selectBoltUser(User newUser, User oldUser) {
        if (newUser.BOLT_Key__c != null && 
            newUser.ADP_Associate_OID__c != null && 
            BoltCallouts.isChangeInRecord(newUser, oldUser, BoltConstants.WS_BOLT_USER)) {
            return true;
        } else {
            return false;
        }
    }
}