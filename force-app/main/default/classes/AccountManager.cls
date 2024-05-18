/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-01-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/Accounts/*')
global with sharing class AccountManager extends RecordManagerTemplate {
    @HttpPost
    global static void createAccount() {
        createRecord(BoltConstants.WS_BOLT_ACCOUNT_CREATE, 'AccountManager');
    }
    
    @HttpPut
    global static void updateAccount(){
        updateRecord(BoltConstants.WS_BOLT_ACCOUNT_UPDATE, 'AccountManager');        
    }
    
    @HttpGet
    global static Account getAccount(){
        RestRequest request = RestContext.request;
        String accountName = request.requestURI.substring(
          request.requestURI.lastIndexOf('/')+1);
        String decodedAccountName = EncodingUtil.urlDecode(accountName, 'UTF-8');
        
        List<Account> existingAccount = [SELECT ID FROM Account WHERE Name = :decodedAccountName];
        if(existingAccount.isEmpty())
            return null;
        return existingAccount[0];
    }
}