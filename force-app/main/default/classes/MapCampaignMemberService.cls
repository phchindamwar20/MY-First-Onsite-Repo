/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-27-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class MapCampaignMemberService {
    //Get list of accounts to exclude
    private static Set<String> accountNamesToExclude = getAccountNamesToExclude();

    //we never delete or update campaign members, we only add on detection of the change in Campaign Name on the Account
    public static void createCampaignMembers(Map<Id, Account> newAccById, Map<Id, Account> oldAccById){
        Set<Id> accIds = new Set<Id>();

        //Get list of accounts where there has been a change in the Campaign Name and the Campaign Name is not null
        for (Account newAcc : newAccById.values()) {
            Account oldAcc = oldAccById != null && oldAccById.containsKey(newAcc.Id) ? oldAccById.get(newAcc.Id) : null;
            //Account oldAcc = oldAccById == null || !oldAccById.containsKey(newAcc.Id) ? null : oldAccById.get(newAcc.Id);

            if (!String.isBlank(newAcc.Maps_Campaign_Trigger__c) &&  
                (
                    (oldAcc != null && newAcc.Maps_Campaign_Trigger__c != oldAcc.Maps_Campaign_Trigger__c) 
                    || oldAcc == null
                )
            ) {
                accIds.add(newAcc.Id);
            }
        }

        if (!accIds.isEmpty()) {
            //Create Account Campaign Members
            Map<Id, Id> campaignIdByAccountId =  createCampaignMembersForAccounts(accIds);

            //Create Contact Campaign Members
            createCampaignMembersForContacts(campaignIdByAccountId);

        }
    }

    private static Map<Id, Id> createCampaignMembersForAccounts(Set<Id> accIds){
        //Loop through accounts and get account id and Maps Campaign Trigger key value pairs, excluding the accounts to exclude
        Map<Id, String> campaignNameByAccountId = getCampaignNameByAccountId(accIds);

        //Get campaign Maps Campaign Trigger / campaign Id Key - Value Pairs
        Map<String, Id> campaignIdByCampaignName = getCampaignIdByCampaignName(new Set<String>(campaignNameByAccountId.values()));
        
        //Get existing Account Campaign Members 
        Map<Id, Id> campaignIdByAccountId = getExistingCampaignMemberAccounts(campaignNameByAccountId, campaignIdByCampaignName);

        //create Account campaign Members excluding the ones that already exists;
        List<CampaignMember> accountCampaignMemberLst = createNewAccountCampaignMembers(campaignNameByAccountId, campaignIdByCampaignName, campaignIdByAccountId);

        //save and get successful account id/ campaign id key value pairs
        campaignIdByAccountId = saveNewAccountCampaignMembers(accountCampaignMemberLst, campaignIdByAccountId);

        return campaignIdByAccountId;
    }

    private static void createCampaignMembersForContacts(Map<Id, Id> campaignIdByAccountId){
        //get contacts associated with the accounts and then the corresponding campaignId
        //note:  one contact can be associated with multiple accounts via AccountContactRelation

        //System.debug('~~~~ MapCampaignMemberService::createCampaignMembersForContacts: campaignIdByAccountId - ' + campaignIdByAccountId);
        
        Map<Id, Set<Id>> campaignIdsByContactId = getCampaignIdsByContactId(campaignIdByAccountId);
        //System.debug('~~~~ MapCampaignMemberService::createCampaignMembersForContacts: campaignIdsByContactId - ' + campaignIdsByContactId);


        List<CampaignMember> contactCampaignMemberLst = new List<CampaignMember>();

        //get contacts associated with the campaigns
        // if there is a contact associated with the campaign, don't add to list of contact campaign members to create
        campaignIdsByContactId = removeExistingCampaignMemberContacts(campaignIdByAccountId, campaignIdsByContactId);
        //System.debug('~~~~ MapCampaignMemberService::createCampaignMembersForContacts: AFTER removal campaignIdsByContactId - ' + campaignIdsByContactId);

        
        //create contact campaign members
        createAndSaveContactCampaignMembers(campaignIdsByContactId);
    }

    private static Set<String> getAccountNamesToExclude(){
        Set<String> accountNamesToExclude = new Set<String>();
        
        //Query the Custom Metadata for ContactCampaignMemberProcessConfig__mdt to return set of Excluded Account Name for all records
        for (ContactCampaignMemberProcessConfig__mdt config : [SELECT Id, Excluded_Account_Name__c FROM ContactCampaignMemberProcessConfig__mdt]) {
    		accountNamesToExclude.add(config.Excluded_Account_Name__c);
		}
        return accountNamesToExclude;
    }

    private static Map<Id, String>  getCampaignNameByAccountId(Set<Id> accIds) {
        Map<Id, String> campaignNameByAccountId = new Map<Id, String>();

        for (Account acc : [SELECT Id, Name, ParentId, Parent.Name, Maps_Campaign_Trigger__c 
                            FROM Account 
                            WHERE Id IN: accIds]) {
            if (!accountNamesToExclude.contains(acc.Name)) {
                campaignNameByAccountId.put(acc.Id, acc.Maps_Campaign_Trigger__c);
            }
        }

        return campaignNameByAccountId;
    }

    private static Map<String, Id> getCampaignIdByCampaignName(Set<String> campaignNames){
        Map<String, Id> campaignIdByCampaignName = new Map<String, Id>();

        for (Campaign camp : [SELECT Id, Name FROM Campaign WHERE Name IN : campaignNames]) {
            campaignIdByCampaignName.put(camp.Name, camp.Id);
        }

        return campaignIdByCampaignName;
    }

    private static Map<Id, Id> getExistingCampaignMemberAccounts(Map<Id, String> campaignNameByAccountId, Map<String, Id> campaignIdByCampaignName){
        Map<Id, Id> existingCampaignIdByAccountId = new Map<Id, Id>();

        for (CampaignMember cm : [SELECT Id, AccountId, CampaignId, Campaign.Name 
                                    FROM CampaignMember 
                                    WHERE AccountId IN : campaignNameByAccountId.keySet() AND CampaignId IN : campaignIdByCampaignName.keySet()]) {

            if (campaignNameByAccountId.containsKey(cm.AccountId)) {
                String campaignName = campaignNameByAccountId.get(cm.AccountId);
                if (campaignIdByCampaignName.containsKey(campaignName) && campaignIdByCampaignName.get(campaignName) == cm.CampaignId) {
                    existingCampaignIdByAccountId.put(cm.AccountId, cm.CampaignId);
                }
            }
        }

        return existingCampaignIdByAccountId;
    }

    private static List<CampaignMember> createNewAccountCampaignMembers(Map<Id, String> campaignNameByAccountId, Map<String, Id> campaignIdByCampaignName, Map<Id, Id> existingCampaignIdByAccountId) {
        List<CampaignMember> accountCampaignMemberLst = new List<CampaignMember>();
        //exclude account ids that already have campaign members
        Set<Id> accIds = campaignNameByAccountId.keySet();
        accIds.removeAll(existingCampaignIdByAccountId.keySet());
        
        //create Account campaign Members excluding the ones that already exists;
        for (Id accId :  accIds) {
            String campaignName = campaignNameByAccountId.containsKey(accId) ? campaignNameByAccountId.get(accId) : null;
            Id campaignId = campaignName != null && campaignIdByCampaignName.containsKey(campaignName) ? campaignIdByCampaignName.get(campaignName) : null;

            if (campaignId != null) {
                accountCampaignMemberLst.add(new CampaignMember(AccountId=accId, CampaignId=campaignId));
            }
        }

        return accountCampaignMemberLst;
    }

    private static Map<Id, Id> saveNewAccountCampaignMembers(List<CampaignMember> accountCampaignMemberLst, Map<Id, Id> campaignIdByAccountId) {
        Set<Id> campaignMemberSuccessIds = new Set<Id>();
        if (!accountCampaignMemberLst.isEmpty()) {
            Database.SaveResult[] resultLst = Database.insert(accountCampaignMemberLst, false);
            for (Database.SaveResult sr : resultLst) {
                campaignMemberSuccessIds.add(sr.getId());
            }

            for (CampaignMember cm : [SELECT Id, AccountId, CampaignId 
                                        FROM CampaignMember
                                        WHERE Id IN : campaignMemberSuccessIds]) {
                campaignIdByAccountId.put(cm.AccountId, cm.CampaignId);
            }
        }

        return campaignIdByAccountId;
    }

    private static Map<Id, Set<Id>> getCampaignIdsByContactId(Map<Id, Id> campaignIdByAccountId) {
        //get contacts associated with the accounts and then the corresponding campaignId
        //note:  one contact can be associated with multiple accounts via AccountContactRelation
        Map<Id, Set<Id>> campaignIdsByContactId = new Map<Id, Set<Id>>();

        System.debug('~~~~ MapCampaignMemberService::getCampaignIdsByContactId:campaignIdByAccountId ' + campaignIdByAccountId);
        //get parents
        Map<Id, Set<Id>> accIdsByParentId = new Map<Id, Set<Id>>();

        //assume we don't need to check parent account in excluded names list
        //multiple accounts can be associated to the same parent
        //there is NO campaign member created for the parent account
        for (Account acc : [SELECT Id, Name, ParentId, Parent.Name FROM Account WHERE Id IN : campaignIdByAccountId.keySet()]) {
            //don't include excluded account names
            if (!accountNamesToExclude.contains(acc.Name) && !accountNamesToExclude.contains(acc.Parent.Name)) {
                if (!accIdsByParentId.containsKey(acc.ParentId)) {
                    Set<Id> accIds = new Set<Id>{acc.Id};
                    accIdsByParentId.put(acc.ParentId, accIds);
                } else {
                    accIdsByParentId.get(acc.ParentId).add(acc.Id);
                }
            }
            //System.debug('~~~~ MapCampaignMemberService::getCampaignIdsByContactId:accIdsByParentId.get(ParentId).size() ' + accIdsByParentId.get(acc.ParentId).size());
        }

        for (AccountContactRelation accConRel : [SELECT Id, AccountId, ContactId 
                                        FROM AccountContactRelation 
                                        WHERE 
                                            (AccountID IN: campaignIdByAccountId.keySet() OR AccountID IN : accIdsByParentId.keySet()) 
                                            AND Contact_Emailable__c = true 
                                            AND IsActive = true]) {
            //System.debug('~~~~ MapCampaignMemberService::getCampaignIdsByContactId:c ' + accConRel);

            //check accounts
            if (campaignIdByAccountId.containsKey(accConRel.AccountId)) {
                campaignIdsByContactId = addToCampaginIdsByContactId(accConRel.AccountId, accConRel.ContactId, campaignIdByAccountId, campaignIdsByContactId);
            } 
            //check parents, and go through each child account; there may be a rare chance where the child account has a different campaign than the other child related to the same parent account
            if (accIdsByParentId.containsKey(accConRel.AccountId)) {
                for (Id accId : accIdsByParentId.get(accConRel.AccountId)) {
                    campaignIdsByContactId = addToCampaginIdsByContactId(accId, accConRel.ContactId, campaignIdByAccountId, campaignIdsByContactId);
                }
            }
        }

        return campaignIdsByContactId;
    }

    private static Map<Id, Set<Id>> addToCampaginIdsByContactId(Id accountId, Id contactId, Map<Id, Id> campaignIdByAccountId, Map<Id, Set<Id>> campaignIdsByContactId) {
        Id campaignId = campaignIdByAccountId.get(accountId);
        if (campaignId != null) {
            if (campaignIdsByContactId.containsKey(contactId)) {
                if (!campaignIdsByContactId.get(contactId).contains(campaignId)) {
                    campaignIdsByContactId.get(contactId).add(campaignId);
                }
            } else {
                campaignIdsByContactId.put(contactId, new Set<Id>{campaignId});
                campaignIdsByContactId.get(contactId).add(campaignId);
            }
        }

        return campaignIdsByContactId;
    }

    private static Map<Id, Set<Id>> removeExistingCampaignMemberContacts(Map<Id, Id> campaignIdByAccountId, Map<Id, Set<Id>> campaignIdsByContactId) {
        //get contacts associated with the campaigns
        for (CampaignMember cm : [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE CampaignId IN: campaignIdByAccountId.values()]) {
            // if there is a contact associated with the campaign, don't add to list of contact campaign members to create
            if (campaignIdsByContactId.containsKey(cm.ContactId) && campaignIdsByContactId.get(cm.ContactId).contains(cm.CampaignId)) {
                campaignIdsByContactId.get(cm.ContactId).remove(cm.CampaignId);
            } 
        }

        return campaignIdsByContactId;
    }

    private static void createAndSaveContactCampaignMembers(Map<Id, Set<Id>>  campaignIdsByContactId) {   
        List<CampaignMember>  contactCampaignMemberLst = new List<CampaignMember>();
        Set<Id> campaignMemberSuccessIds = new Set<Id>();
        
        //create contact campaign members
        for (Id conId : campaignIdsByContactId.keySet()) {
            for (Id campId : campaignIdsByContactId.get(conId)) {
                contactCampaignMemberLst.add(new CampaignMember(ContactId=conId, CampaignId=campId));
            }
        }

        if (!contactCampaignMemberLst.isEmpty()) {
            Database.SaveResult[] resultLst = Database.insert(contactCampaignMemberLst, false);
            for (Database.SaveResult sr : resultLst) {
                campaignMemberSuccessIds.add(sr.getId());
            }
        }
    }
}