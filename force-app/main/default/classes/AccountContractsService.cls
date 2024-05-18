/**
 * @description       : This class takes a set of account ids to get all related client contract record types and update the related contracts if certain conditions are met
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-02-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class AccountContractsService  {
    public void updateClientContracts(Set<Id> accIds) {
        List<Contract> contractUpdLst = new List<Contract>();

        for (Contract contr : [SELECT Id, Active__c, Canceled__c, 
                                        Account.Status__c, Account.Contract_Type__c, Account_Contract_Type__c
                                FROM Contract
                                WHERE AccountId IN : accIds
                                        AND RecordTypeId =: GeneralConstants.RT_ID_CONTRACT_CLIENT
                                ORDER BY AccountId]) {
            Boolean isUpdateContract = false;
            Contract updContract = new Contract(Id=contr.Id);

            //IF contract's account status is Unqualified THEN set canceled = true
            if (contr.Account.Status__c == GeneralConstants.ACC_STATUS_UNQUALIFIED) {
                updContract.Canceled__c=true;
                isUpdateContract = true;
            }

            //IF Account's Contract Type Changes THEN update the contract's account contract to match the Account's Contract Type
            if (contr.Account.Contract_Type__c != contr.Account_Contract_Type__c) {
                updContract.Account_Contract_Type__c = contr.Account.Contract_Type__c;
                isUpdateContract = true;
            }

            if (isUpdateContract) {
                contractUpdLst.add(updContract);
            }
        }
        updateRecords(contractUpdLst);
    }

    private void updateRecords(List<Contract> contractLst) {
        if (!contractLst.isEmpty()) {
            String errorMsg = '';
            Database.SaveResult[] resultLst = Database.update(contractLst, false);
            for (Database.SaveResult sr : resultLst) {
                if(!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        errorMsg += ' Error: ' + sr.getId() + ', status code: ' + err.getStatusCode() + ',  messsage: ' + err.getMessage() + '\n';
                    }
                }
            }

            if (errorMsg.length() > 0 ) {
                System.debug('~~~~ AccountContractsService::setMatchNames: errorMsg - ' + errorMsg);
                throw new AccountContractsServiceException(errorMsg);
            }
        }
    }

    public class AccountContractsServiceException extends Exception {}
}