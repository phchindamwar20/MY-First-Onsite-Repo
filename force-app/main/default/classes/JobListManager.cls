/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-09-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/JobList/*')
global without sharing class JobListManager extends RecordManagerTemplate {
    @HttpPut
    global static void updateJobList() {
        updateRecordList('updateJobList', 'JobListManager');
    }
}