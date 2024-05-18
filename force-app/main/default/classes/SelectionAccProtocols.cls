public without sharing class SelectionAccProtocols extends SelectionBase{
    private static Map<Id, Set<String>> fieldsByAccId;
    private static set<String> accountProtocolFieldsSet ;

    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for (Account newAcc : (List<Account>)newById.values()) {    
            Account oldAcc = oldById != null && oldById.containsKey(newAcc.Id) ? (Account)oldById.get(newAcc.Id) : null;
            if (isProtocolChange(newAcc,oldAcc)) {
                recIds.add(oldAcc.Id);    
            } 
        }
    }

    public Map<Id, Set<String>> getFieldsByAccId(){
        return fieldsByAccId; 
    }
    
    @TestVisible
    private static Boolean isProtocolChange(Account newAccount,  Account oldAccount){
        Boolean result = false;
        fieldsByAccId = AccProtocolsService.determineParentProtocolChange(newAccount, oldAccount, fieldsByAccId);
        if(fieldsByAccId.containskey(newAccount.Id)){
            result = true;
        }
        return result;
    }
}