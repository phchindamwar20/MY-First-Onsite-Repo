/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-03-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/Invoice/*')
global without sharing class InvoiceManager extends RecordManagerTemplate {
    @HttpPatch
    global static void upsertInvoice() {
        upsertRecord('upsertInvoice', 'InvoiceManager');
    }
}