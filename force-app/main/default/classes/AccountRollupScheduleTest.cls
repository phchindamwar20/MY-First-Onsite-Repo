/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-06-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   02-01-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
public with sharing class AccountRollupScheduleTest {
    @isTest
    static void testThis() {
              // Schedule the test job
 
      String jobId = System.schedule('testAccountRollupApex',
        '0 0 0 3 9 ? *', 
         new AccountRollupSchedule());

      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
         NextFireTime
         FROM CronTrigger WHERE id = :jobId];
 
      // Verify the expressions are the same
      System.assertEquals('0 0 0 3 9 ? *', 
         ct.CronExpression);         
    }
}