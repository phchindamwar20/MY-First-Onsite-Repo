/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-01-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

@RestResource(urlMapping='/Property/*')
global without sharing class PropertyManager extends RecordManagerTemplate {

    @HttpPost
    global static void createProperty() {
        createRecord('createProperty', 'PropertyManager');
    }

    @HttpPut
    global static void updateProperty() {
        updateRecord('updateProperty', 'PropertyManager');
    }

    /* Not used at this time
    @HttpDelete
    global static void deleteProperty() {
        deleteRecord('PropertyManager', 'deleteProperty');
    }
    */
}