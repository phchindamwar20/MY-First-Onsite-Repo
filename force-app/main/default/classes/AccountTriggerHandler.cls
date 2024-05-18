/**
 * @File Name          : AccountTriggerHandler.cls
 * @Description        : 1. This associates an account with a 'parent portal account', so accounts can be shared with community users
 *                       2. Prevents the change of record type on account if the account is associated with a job as an account or a property
 *                       3. Prevents the deletion of an account if it is associated with a job as an account or property
 *                       4. Queueable chain of responsibility jobs associated with the account trigger is built directly into the trigger framework.  If you
 *                          want to see the potential jobs chained together, look at the Execution Item Configuration custom metadata for account and the corresponding trigger event
 * @Author             : Terri Jiles
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 08-18-2023
 * @Modification Log   : 
 * Ver       Date            Author              Modification
 * 2.0    05/09/2024          Kiran K             preventDeletes - logic moved to flow-delete-trigger
**/
public without sharing class AccountTriggerHandler extends TriggerHandlerBase {
    public AccountTriggerHandler() {}
    
    public static Boolean isSuppressTrigger=false;

    public override Boolean IsDisabled() {
        if (!isSuppressTrigger) {
            try {
                DataAdmin__c bypass = DataAdmin__c.getInstance();
                return bypass.TurnOffTrigger__c;
            }
            // if custom setting doesn't exists, don't disable 
            catch (Exception e) {
                return false;
            } 
        } else {
            return isSuppressTrigger;
        }
    }
   
    public override void beforeInsert(SObject[] newItems) {
        setDefault((List<Account>)newItems, null);
    }

    public override void afterInsert(Map<Id, SObject> newItems) {}

    public override void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) { 
        integrateWithBoltValidations(newItems, oldItems);
    }   

    public override void beforeDelete(Map<Id, SObject> oldItems) {
        //preventDeletes(oldItems);
    }

    public void setDefault(List<Account> newAccounts, Map<Id, Account> mapOldAccountById) {
        Map<String, String> mapNameByKey = new Map<String, String>();
        Map<String, Id> mapIdByName = new Map<String, Id>();

        for (Default_Portal_Account__mdt dpa : [SELECT DeveloperName, CountryCode__c, StateProvinceCode__c, Default_Account_Name__c FROM Default_Portal_Account__mdt ORDER BY CountryCode__c DESC, StateProvinceCode__c DESC]) {
            if (!String.isBlank(dpa.DeveloperName)) { 
                mapNameByKey.put(dpa.DeveloperName, dpa.Default_Account_Name__c); 
                //System.debug('~~~~ AccountTriggerHandler::setDefault: ' + dpa.DeveloperName + ' Partner Account Name ' + dpa.Default_Account_Name__c);
            }           
        }
        for (Account pa : [SELECT Id, Name FROM Account WHERE Name IN: mapNameByKey.values()]) {
            mapIdByName.put(pa.Name, pa.Id);    
            //System.debug('~~~~ AccountTriggerHandler::setDefault: pa ' + pa);      
        }

        for (Account acc : newAccounts) {
            Boolean defaultAcc = false;
            if ( !mapIdByName.containsKey(acc.Name) && mapOldAccountById == null ) { defaultAcc=true; } 
            else if (!mapIdByName.containsKey(acc.Name) && mapOldAccountById.containsKey(acc.Id) && (acc.BillingCountryCode != mapOldAccountById.get(acc.Id).BillingCountryCode || acc.BillingStateCode != mapOldAccountById.get(acc.Id).BillingCountryCode)) { defaultAcc=true; }

            String countryCode = !String.isBlank(acc.BillingCountryCode) ? acc.BillingCountryCode : '';
            String stateCode = !String.isBlank(acc.BillingStateCode) ?  acc.BillingStateCode : '';
            String key = '';
            //System.debug('~~~~ AccountTriggerHandler::setDefault: countryCode ' + countryCode + ', stateCode ' + stateCode  + ' defaultAcc ' + defaultAcc);

            if (defaultAcc) {
                String key1 = countryCode + '_' + stateCode, key2=countryCode, key3='Default';
                //System.debug('~~~~ AccountTriggerHandler::setDefault: key1 ' + key1 + ' key2 ' + key2 + ' key3 ' + key3);

                if (mapNameByKey.containsKey(key1)) {
                    key=mapNameByKey.get(key1);
                    //System.debug('~~~~ AccountTriggerHandler::key ' + key);
                } else if (mapNameByKey.containsKey(key2)) {
                    key=mapNameByKey.get(key2);
                    //System.debug('~~~~ AccountTriggerHandler::key ' + key);
                } else if (mapNameByKey.containsKey(key3)) { 
                    key=mapNameByKey.get(key3);
                    //System.debug('~~~~ AccountTriggerHandler::key ' + key);                   
                } else {
                    key='';
                }
                if (mapIdByName.containsKey(key)) { 
                    //System.debug('~~~~ AccountTriggerHandler::mapIdByName.get(key) ' + mapIdByName.get(key));
                    acc.Parent_Portal_Account__c=mapIdByName.get(key); 
                }                
            }
        }

    }

    //private void integrateWithBoltAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    private void integrateWithBoltValidations(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {    
        Map<Id, Account> newAccountById = (Map<Id, Account>)newItems;
        Map<Id, Account> oldAccountById = (Map<Id, Account>)oldItems;
        Map<Id, AggregateResult> numJobsByAccId = new Map<Id, AggregateResult>();
        Map<Id, AggregateResult> numJobsByPropId = new Map<Id, AggregateResult>();

        //STAR-4018, STAR-4657  Get Jobs associated with Account
        for (AggregateResult job : [SELECT Count(Id), AccountId FROM WorkOrder WHERE AccountId IN: newAccountById.keySet() GROUP BY AccountId]) {
            Id accId = (Id)job.get('AccountId');
            if (newAccountById.get(accId).RecordTypeId != oldAccountById.get(accId).RecordTypeId) {
                Account acc = new Account(Id=accId);
                numJobsByAccId.put(accId, job);
            }
        }

        //STAR-4018, STAR-4657  Get Jobs associated with Properties
        for (AggregateResult job : [SELECT Count(Id), Property__c FROM WorkOrder WHERE Property__c IN: newAccountById.keySet() GROUP BY Property__c]) {
            Id accId = (Id)job.get('Property__c');
            if (newAccountById.get(accId).RecordTypeId != oldAccountById.get(accId).RecordTypeId) {
                Account acc = new Account(Id=accId);
                numJobsByPropId.put(accId, job);
            }
        }

        //STAR-4018, STAR-4657 Don't allow record type change if account or property associated with jobs
        for (Account acc : newAccountById.values()) {
            if (newAccountById.get(acc.Id).RecordTypeId != oldAccountById.get(acc.Id).RecordTypeId &&
                (numJobsByAccId.containsKey(acc.Id) || numJobsByPropId.containsKey(acc.Id))) {
                    acc.addError(Label.ERROR_NO_RT_CHNG_WITH_JOBS);
            }
        }

    }    
    
}