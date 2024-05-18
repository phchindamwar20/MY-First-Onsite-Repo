/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-25-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   01-25-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
global without sharing class AccountRollupSchedule  implements Schedulable{
    global void execute(SchedulableContext sc) {
        AccountRollupBatch b = new AccountRollupBatch();
        database.executeBatch(b);
    }
}