/**
 * @description       : Selection Criteria for icertis approved contracts contracts to send to iCertis agreements for signing
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-18-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionIcertisAgreementsForSigning extends SelectionBase {
	public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for (Contract newContract : [SELECT Id, Status FROM Contract WHERE Id IN: newById.keySet() AND Job__r.IC_Bolt_CWA__c = true]) {
            Contract oldContract = oldById != null && oldById.containsKey(newContract.Id) ? (Contract)oldById.get(newContract.Id) : null;

            if (selectApproveContract(newContract, oldContract)) {
                recIds.add(newContract.Id);
            }
        }
    }

    @TestVisible
    private Boolean selectApproveContract(Contract newContract, Contract oldContract) {
        Boolean selection = false;

        if (oldContract != null && newContract.Status == ICertisConstants.CS_APPROVED && oldContract.Status != newContract.Status) {
            selection = true;
        }

        return selection;
    }
}