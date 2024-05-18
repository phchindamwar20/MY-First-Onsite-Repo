/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-25-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/Transaction/*')
global without sharing class TransactionManager extends RecordManagerTemplate{
    @HttpPatch
    global static void upsertTransaction() {
        upsertRecord('upsertTransaction', 'TransactionManager');
    }
}