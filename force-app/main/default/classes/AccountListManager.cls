/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-07-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/AccountList/*')
global without sharing class AccountListManager extends RecordManagerTemplate {
    @HttpPut
    global static void updateAccountList() {
        updateRecordList('updateAccountList', 'AccountListManager');
    }
}