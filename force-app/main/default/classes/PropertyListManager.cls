/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-08-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/PropertyList/*')
global without sharing class PropertyListManager extends RecordManagerTemplate {
    @HttpPut
    global static void updatePropertyList() {
        updateRecordList('updatePropertyList', 'PropertyListManager');
    }
}