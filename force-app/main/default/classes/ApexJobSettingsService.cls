/**
 * @description       : This class is used by apex classes implementing schedule interface or the batch interface.  It is to help aid admin to configure, setup and cancel jobs easiler
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-02-2024
 * @last modified by  : Terri Jiles
**/
public virtual without sharing class ApexJobSettingsService {
    private String jobName = '';
    private final String SCHEDULED = 'Scheduled';
    private final String BATCH = 'Batch';
    private final String append = Test.isRunningTest() ? 'Test' : '';
    private String actualJobName = '';

    public ApexJobSettingsService() {}

    public virtual void setJobName(String thisJobName) {
        jobName=thisJobName;
        actualJobName=jobName+append;
    }

    public virtual String scheduleJob() {
        try {
            Apex_Job_Configuration__mdt config = Apex_Job_Configuration__mdt.getInstance(jobName);
            if (config.Type_of_Job__c==SCHEDULED) {
                Type scheduleClass = Type.forName(jobName);
                Schedulable schObj = (Schedulable)scheduleClass.newInstance();
                return System.schedule(actualJobName, config.Chron_Expression__c, schObj);
            } else {
                throw new ApexJobSettingServiceException('Job type must be a ' + SCHEDULED + ' job type in order to call this method');
            }
        } catch (Exception e){
            throw new ApexJobSettingServiceException('There was an issue scheduling the job ' + e.getMessage(), e);
        }
    }

    public virtual void cancelScheduledJob() {
        try {
            Apex_Job_Configuration__mdt config = Apex_Job_Configuration__mdt.getInstance(jobName);
            if (config.Type_of_Job__c==SCHEDULED) {
                for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: actualJobName]) {
                    System.abortJob(ct.Id);
                }
            } else {
                throw new ApexJobSettingServiceException('Job type must be a ' + SCHEDULED + ' job type in order to call this method');
            }
        } catch (Exception e){
            throw new ApexJobSettingServiceException('There was an issue scheduling the job ' + e.getMessage(), e);
        }
    }

    public virtual void executeBatchJob() {
        try {
            Apex_Job_Configuration__mdt config = Apex_Job_Configuration__mdt.getInstance(jobName);
            if (config.Type_of_Job__c==BATCH) {
                Type batchClass = Type.forName(jobName);
                Database.Batchable<SObject> batchObj = (Database.Batchable<SObject>)batchClass.newInstance();
                Database.executeBatch(batchObj, Integer.valueOf(config.Batch_Size__c));
            } else {
                throw new ApexJobSettingServiceException('Job type must be a ' + BATCH + ' job type in order to call this method');
            }
        } catch (Exception e) {
            throw new ApexJobSettingServiceException('There was an issue executing batch job ' + e.getMessage(), e);
        }
    }

    public virtual void cancelBatchJob() {
        try {
            Apex_Job_Configuration__mdt config = Apex_Job_Configuration__mdt.getInstance(jobName);
            if (config.Type_of_Job__c==BATCH) {
                for ( AsyncApexJob apexJob : [SELECT Id ,Status, ApexClass.Name FROM AsyncApexJob WHERE Status!='Aborted' and Status!='Completed' AND ApexClass.Name=:jobName] ){
                    System.abortJob(apexJob.Id);
                }
            } else {
                throw new ApexJobSettingServiceException('Job type must be a ' + BATCH + ' job type in order to call this method');
            }
        } catch (Exception e) {
            throw new ApexJobSettingServiceException('There was an issue canceling batch job ' + e.getMessage(), e);
        }

    }

    public virtual String getActualJobName() {
        return actualJobName;
    }

    public virtual String getJobName() {
        return jobName;
    }

    class ApexJobSettingServiceException extends Exception {}
}