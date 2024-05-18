/**
 * @description       : This gets the related invoices and updates the account when the job's account changes (as determined by the SselectionJobRelatedInvoices class)
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-25-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class JobRelatedInvoicesService {
    public String updateRelatedJobInvoices(Map<Id, Set<String>> actionByJobId) {
        String errorResult = '';
        Map<Id, Invoice__c> relatedInvoiceById = new Map<Id, Invoice__c>();
        
        for (Invoice__c invoice : [SELECT Id, Account__c, Job__r.AccountId FROM Invoice__c WHERE Job__c IN: actionByJobId.keySet()]) {
            if (invoice.Job__r.AccountId != null && actionByJobId.get(invoice.Job__c).contains(GeneralConstants.AFTER_UPDATE)) {
                if (!relatedInvoiceById.containsKey(invoice.Id)) {
                    relatedInvoiceById.put(invoice.Id, new Invoice__c(Id=invoice.Id));
                }
                relatedInvoiceById.get(invoice.Id).Account__c=invoice.Job__r.AccountId;
            }
        }

        errorResult = updateRecs(relatedInvoiceById.values());

        return errorResult;
    }

    private String updateRecs(List<Invoice__c> recLst) {
        String errorMsg = '';
        Database.SaveResult[] resultLst = Database.update(recLst, false);
        for (Database.SaveResult sr : resultLst) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    errorMsg += 'Error: Id - ' + sr.getId() + ', status code: ' + err.getStatusCode() + ',  messsage: ' + err.getMessage() + '\n';
                    //errorIds.add(sr.getId());
                }
            } 
        } 
        return errorMsg;
    }

    public class JobRelatedInvoicesServiceException extends Exception {}
}