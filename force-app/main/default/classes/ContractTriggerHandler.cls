/**
 * @File Name          : ContractTriggerHandler.cls
 * @Description        : 1. On creation of a new contract, If job is CWA job and contract is in Approved Status then send the contract to sign.
 * 
 * @TODOS              : 
 * @Author             : Arpit Vashishtha
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 01-09-2024
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    2/19/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public without sharing virtual class ContractTriggerHandler extends TriggerHandlerBase {
    /*
    public static Boolean isDefaultOverride = false;
    private DataAdmin__c dataAdminBypass = DataAdmin__c.getInstance();
    
    
    public override void afterInsert(Map<Id, SObject> newItems) {
        Map<Id, Contract> mapNewContractById = (Map<Id, Contract>)newItems;
        
        //STAR-5366
        Set<Id> contractIdSet = new Set<Id>();
        contractIdSet = getApprovedContract(mapNewContractById, null);
        if(contractIdSet.size() > 0) IcertisService.sendAgreementForSigning(contractIdSet);
    }
    
    public override void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, Contract> mapNewContractById = (Map<Id, Contract>)newItems;
        Map<Id, Contract> mapOldContractById = (Map<Id, Contract>)oldItems;
        
        //STAR-5366
        Set<Id> contractIdSet = new Set<Id>();
        contractIdSet = getApprovedContract(mapNewContractById, mapOldContractById);
        if(contractIdSet.size() > 0) IcertisService.sendAgreementForSigning(contractIdSet);
    }  
  
    
    public static Set<Id> getApprovedContract(Map<Id, Contract> newContractMap, Map<Id, Contract> oldItems) {
        Set<Id> contractIdSet = new Set<Id>();
        for(Id contractId : newContractMap.keySet()) {
            if((oldItems == null && newContractMap.get(contractId).Status == 'Approved') || (oldItems != null && oldItems.get(contractId).Status != newContractMap.get(contractId).Status && newContractMap.get(contractId).Status == 'Approved')) {
                contractIdSet.add(contractId);
            }//End of if(newContractMap.get(contractId).Status == 'Approved')
        }//End of for(Id contractId : newContractMap.keySet())
        return contractIdSet;
    }//End of getApprovedContract method
    */
}