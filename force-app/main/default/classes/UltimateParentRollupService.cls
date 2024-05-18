/**
 * @description       : This rollup service calculates the Ultimate Parent for the account records that have the parent and account record types
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-29-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class UltimateParentRollupService {
    private Set<Id> allAccountIds = new Set<Id>();
    private List<String> errorMsgLst = new List<String>();

    public Set<Id> setUltimateParent(Set<Id> accIds) {

        Map<Id,Account> accUpdById = new Map<Id, Account>();    
        List<String> recordTypeLst = new List<String>();
        recordTypeLst.add(GeneralConstants.RT_ACC_ACCOUNT);
        recordTypeLst.add(GeneralConstants.RT_ACC_PARENT);
        
        AccountTriggerHandler.isSuppressTrigger=true;
        //System.debug('~~~~~ UltimateParentRollupService::setUltimateParent: accIds- ' + accIds.toString());
        Integer numOfAccs = accIds.size();
        Boolean isSetDataAdminReason = setDataAdminReason();

        //Query doesn't contain order by because 'Explicit ORDER BY not allowed when locking rows (Id order is implied)''
        for (Account acc : [SELECT Id, Name, The_Ultimate_Parent_Account__c, ParentId, Parent.The_Ultimate_Parent_Account__c, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.ParentId, RecordType.DeveloperName FROM Account 
                            WHERE Id IN: accIds AND RecordType.DeveloperName IN:recordTypeLst 
                            FOR UPDATE]) {
            //System.debug('~~~~ UltimateParentRollupService::setUltimateParent: acc - ' + acc);

            Account accUpd = new Account();
            if (acc.ParentId == null) {
                accUpd.Id = acc.Id;
                accUpd.The_Ultimate_Parent_Account__c=null;
                //System.debug('~~~~ UltimateParentRollupService::setUltimateParent: acc - top level 0');
            } 
            else if (acc.ParentId != null) {
                if (numOfAccs == 1) {//STAR-4130 not processing bulk 
                    accUpd.Id = acc.Id;
                    accUpd.The_Ultimate_Parent_Account__c=getUltimateParentId(acc.Id);   //this recursive method has the potential to case a TOO MANY SQOL LIMIT ERROR or CPU TIMEOUT LIMIT ERROR
                    //System.debug('~~~~ UltimateParentRollupService::setUltimateParent: acc - recursive num 1');
                } else if (acc.Parent.ParentId == null) {
                    accUpd.Id = acc.Id;
                    accUpd.The_Ultimate_Parent_Account__c=acc.ParentId;
                    //System.debug('~~~~ UltimateParentRollupService::setUltimateParent: acc - top level 1');
                } else if (acc.Parent.Parent.ParentId == null) {
                    accUpd.Id = acc.Id;
                    accUpd.The_Ultimate_Parent_Account__c=acc.Parent.ParentId;
                    //System.debug('~~~~ UltimateParentRollupService::setUltimateParent: acc - top level 2');
                } else if (acc.Parent.Parent.Parent.ParentId == null) {
                    accUpd.Id = acc.Id;
                    accUpd.The_Ultimate_Parent_Account__c=acc.Parent.Parent.ParentId;
                    //System.debug('~~~~ UltimateParentRollupService::setUltimateParent: acc - top level 3');
                } else if (acc.Parent.Parent.Parent.Parent.ParentId == null) {
                    accUpd.Id = acc.Id;
                    accUpd.The_Ultimate_Parent_Account__c=acc.Parent.Parent.Parent.ParentId;
                    //System.debug('~~~~ UltimateParentRollupService::setUltimateParent: acc - top level 4');
                } else {
                    accUpd.Id = acc.Id;
                    accUpd.The_Ultimate_Parent_Account__c=getUltimateParentId(acc.Parent.Parent.Parent.ParentId);      //this recursive method has the potential to case a TOO MANY SQOL LIMIT ERROR or CPU TIMEOUT LIMIT ERROR  
                    //System.debug('~~~~ UltimateParentRollupService::setUltimateParent: acc - recursive beyond level 4');            
                }
            }
            
            //Account accUpd = new Account(Id=acc.Id, The_Ultimate_Parent_Account__c=ultimateParentId);
            accUpd.Data_Admin_Reason__c = isSetDataAdminReason ? 'Mass Update' : null;
            accUpdById.put(accUpd.Id, accUpd);
            if (acc.RecordType.DeveloperName == recordTypeLst[0]) {
                //only send accounts with the Account record type to Bolt
                allAccountIds.add(acc.Id);
            }
        
        }
        if (!accUpdById.isEmpty()) {
            Set<Id> ids = updateRecs(accUpdById.values());
            Map<Id, Account> accChildById = new Map<Id, Account>([SELECT Id FROM Account 
                                    WHERE ParentId IN: ids
                                    AND RecordType.DeveloperName IN:recordTypeLst 
                                    FOR UPDATE]);

            if (!accChildById.isEmpty()) {
                setUltimateParent(accChildById.keySet());
            }
        } 
        return allAccountIds;
        
    }

    public String getErrors() {
        String errorMsgs = '';

        for (String errorMsg : errorMsgLst) {
            errorMsgs += errorMsg + '\n';
        }

        return errorMsgs;
    }

    //STAR-4130
    //this recursive method has the potential to case a TOO MANY SQOL LIMIT ERROR or CPU TIMEOUT LIMIT ERROR
    //This only becomes an issue on records processed in mass where the ultimate parents haven't been set in order
    private static Id getUltimateParentId(Id accountId) {
        Boolean isUltimateParent = false;
        Id parentId = null;
        for (Account acc : [SELECT ParentId FROM Account WHERE Id=:accountId]) {
            parentId = acc.ParentId;
        }

        if (parentId != null) {
            return getUltimateParentId(parentId);
        } else {
            return accountId;
        }
    }

    private static Boolean setDataAdminReason() {
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());

        Boolean isDataAdminTurnedOff = dataAdmin.TurnOffTrigger__c || dataAdmin.TurnOffWorkflow__c || dataAdmin.TurnOffProcessBuilder__c || dataAdmin.TurnOffValidationRules__c || dataAdmin.TurnOffFlow__c;
        //System.debug('~~~~ UltimateParentRollupService::setDataAdminReason: isDataAdminTurnedOff - ' + isDataAdminTurnedOff);

        return isDataAdminTurnedOff;
    }

    private Set<Id> updateRecs(List<Account> recLst) {
        Set<Id> ids = new Set<Id>();
        String errorMsg = '';
        Database.SaveResult[] resultLst = Database.update(recLst, false);
        for (Database.SaveResult sr : resultLst) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    errorMsgLst.add(' Error: Id - ' + sr.getId() + ', status code: ' + err.getStatusCode() + ',  messsage: ' + err.getMessage());
                }
            } else {
                ids.add(sr.getId());
            }
        } 
        
        return ids;
    }
}