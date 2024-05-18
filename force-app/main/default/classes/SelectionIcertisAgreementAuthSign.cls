/**
 * @description       : This selection class is used to dynamically put iCertisAgreements for Authorized Signatory
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-08-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionIcertisAgreementAuthSign extends SelectionBase {
	public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        //do nothing this class is really used so we can dynamically add it to a chain
    }
}