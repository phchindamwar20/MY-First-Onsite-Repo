/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-24-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global without sharing class JobSharingSchedule  implements Schedulable{
    global void execute(SchedulableContext sc) {
        JobSharingBatch b = new JobSharingBatch();
        database.executeBatch(b);
    }
}