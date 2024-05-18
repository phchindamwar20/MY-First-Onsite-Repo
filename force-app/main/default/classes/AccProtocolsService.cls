public with sharing class AccProtocolsService {
    
    private static List<Account_Protocol_Info__mdt> accountProtocolList;

    
    private static Set<String> getAccountProtocolFieldSet(){
        set<String> accountProtocolFieldSet= new set<String>();
        for(Account_Protocol_Info__mdt accProtocolrec :getAccountProtocolInfoLst()){
            accountProtocolFieldSet.add(accProtocolrec.Protocol_API_Field_Name__c);
        }
        return accountProtocolFieldSet;

    }
    
    public static string convertSetToCSV(Set<String> convertset, String prefixValue){
        if(String.isNotBlank(prefixValue)){
            List<String> convertedList = new List<String>();
            for (String item : convertSet) {
                convertedList.add(prefixValue + item);
            }
            return String.join(convertedList,', ');
        }
        return String.join(convertset,', ');
    }
    
    public static List<Account_Protocol_Info__mdt> getAccountProtocolInfoLst(){
        accountProtocolList = [select Id, DeveloperName, Protocol_API_Field_Name__c, Push_Protocols_Down_Value__c, Push_Protocol_Down_Field__c from Account_Protocol_Info__mdt];
        return accountProtocolList;
    }
    
    public static Map<Id, Set<String>> determineParentProtocolChange(Account newAccount, Account oldAccount, Map<Id, Set<String>> fieldsByAccId){
        
        if(oldAccount == null){
            return fieldsByAccId;
        }
        if(fieldsByAccId == null){
            fieldsByAccId = new Map<Id, Set<String>>();
        }
        for(Account_Protocol_Info__mdt accProtocolrec :getAccountProtocolInfoLst()){
            boolean isFieldChanged = oldAccount.get(accProtocolRec.Protocol_API_Field_Name__c) != newAccount.get(accProtocolRec.Protocol_API_Field_Name__c) ; system.debug('isFieldChanged'+isFieldChanged);
            boolean isPushProtocolDownField = newAccount.get(accProtocolrec.Push_Protocol_Down_Field__c) == accProtocolrec.Push_Protocols_Down_Value__c;system.debug('isPushProtocolDownField'+isPushProtocolDownField);
            if( isFieldChanged && isPushProtocolDownField){
                if(!fieldsByAccId.containsKey(newAccount.id)){
                    fieldsByAccId.put(newAccount.Id, new Set<String>{accProtocolrec.Protocol_API_Field_Name__c});
                }else{
                    fieldsByAccId.get(newAccount.Id).add(accProtocolrec.Protocol_API_Field_Name__c);
                }
            }            
        }
        system.debug('fieldsByAccId:'+JSON.serializePretty(fieldsByAccId));
        return fieldsByAccId;
    }
    
    public static List<Account> setChildrenProtocolsFromParents(Map<Id, Set<String>> fieldsByAccId){
        Map<Id, List<Database.Error>> errorLstById = new Map<Id, List<Database.Error>>();
        Set<String> fieldsToQuery = getAccountProtocolFieldSet();
        List<Account> childAccLst = new List<Account>();
        Set<Id> parentAccountIds = fieldsByAccId.keyset();
        String dynamicAccountQuery = 'Select Id, ParentId, '+convertSetToCSV(fieldsToQuery, 'Parent.') +', '+ convertSetToCSV(fieldsToQuery,'')+' from Account where ParentId IN :parentAccountIds'; system.debug(dynamicAccountQuery);
        List<Account> accountList = Database.query(String.escapeSingleQuotes(dynamicAccountQuery));
        System.debug('accountList to update'+ JSON.serializePretty(accountList));

        for(Account acc: accountList){
            Account childAccount = new Account(Id=acc.Id);
            for(String fieldApiName: fieldsByAccId.get(acc.ParentId)){
                system.debug('ParentField: '+acc.getSobject('parent').getSobject('Account').get(fieldApiName));

                childAccount.put(fieldApiName, acc.getSobject('parent').getSobject('Account').get(fieldApiName)); 
                childAccLst.add(childAccount);
            }
        }
        System.debug('childAccLst to update'+ JSON.serializePretty(childAccLst));

        Database.SaveResult[] results = Database.update(childAccLst, false);
        System.debug(results);
        errorLstById = DynamicApexService.getErrorsFromResult(results,childAccLst,'Account',errorLstById);
        return childAccLst;
    }
    
    // @TestVisible
    // public static void setChildProtocolFromParent(){
    //     //TODO - 
    // }

    public class AccProtocolsServiceException extends Exception {}
}