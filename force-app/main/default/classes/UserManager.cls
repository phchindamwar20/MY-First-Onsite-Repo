/**
 * @description       : This is the web service called by bolt in the Employee Master Sync utlized to create or update users
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 02-03-2024
 * @last modified by  : Terri Jiles
**/
@RestResource(urlMapping='/User/*')
global without sharing class UserManager extends RecordManagerTemplate {
    @HttpPost
    global static void createUser() {
        createRecord(BoltConstants.WS_BOLT_USER_CREATE, 'UserManager');
    }

    @HttpPut
    global static void updateUser() {
        updateRecord(BoltConstants.WS_BOLT_USER_UPDATE, 'UserManager');
    }
}