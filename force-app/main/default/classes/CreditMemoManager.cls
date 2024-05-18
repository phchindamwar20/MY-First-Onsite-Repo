/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-04-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/CreditMemo/*')
global without sharing class CreditMemoManager extends RecordManagerTemplate {
    @HttpPatch
    global static void upsertCreditMemo() {
        upsertRecord('upsertCreditMemo', 'CreditMemoManager');
    }
}