/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-01-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/Jobs/*')
global without sharing class JobManager extends RecordManagerTemplate{
    
    @HttpPost
    global static void createJob(){
        createRecord(BoltConstants.WS_BOLT_JOB_CREATE, 'JobManager');
    }
    
    @HttpPatch
    global static void updateJob(){
        updateRecord(BoltConstants.WS_BOLT_JOB_UPDATE, 'JobManager');
    }
}