/**
 * @description       : This class updates related job contacts
 *                      1.  If contact has a referred by at time of creation, update the Referred By's Contact record's Last Referral Date to today
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-21-2023
 * @last modified by  : Terri Jiles
**/

public without sharing class JobRelatedContactsService {

    public String updateRelatedJobContacts(Map<Id, Set<String>> actionByJobId) {
        String errorResult = '';
        Map<Id, Contact> relatedContactById = new Map<Id, Contact>();
        
        for (WorkOrder job : [SELECT Id, Referred_By__c FROM WorkOrder WHERE Id IN: actionByJobId.keySet()]) {
            if (job.Referred_By__c != null && actionByJobId.get(job.Id).contains(GeneralConstants.AFTER_INSERT)) {
                if (!relatedContactById.containsKey(job.Referred_By__c)) {
                    relatedContactById.put(job.Referred_By__c, new Contact(Id=job.Referred_By__c));
                }
                relatedContactById.get(job.Referred_By__c).Last_Referral_Date__c = Date.today();
            }
        }

        errorResult = updateRecs(relatedContactById.values());

        return errorResult;
    }

    private String updateRecs(List<Contact> recLst) {
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

    public class JobRelatedContactsServiceException extends Exception {}
}