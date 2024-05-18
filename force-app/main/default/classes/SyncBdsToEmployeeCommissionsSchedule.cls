/**
 * @description       : This class schedules SyncBdsToEmployeeCommissionsBatch
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-02-2024
 * @last modified by  : Terri Jiles
**/
global without sharing class SyncBdsToEmployeeCommissionsSchedule extends ApexJobSettingsService implements Schedulable {
    public SyncBdsToEmployeeCommissionsSchedule() {
        setJobName('SyncBdsToEmployeeCommissionsSchedule'); 
    }
    
    global void execute(SchedulableContext ctx) {
        SyncBdsToEmployeeCommissionsBatch b = new SyncBdsToEmployeeCommissionsBatch();
        b.executeBatchJob();
    }
}