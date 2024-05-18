/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    User trigger, which is called on any DML gets performed on User Object.
Class:          UserTrigger.trigger
Test Class:     UserTriggerHandlerTest.cls

History:
When            Who                 What
21-June-2022    Arpit               Added the code to send the API callout to ICI for provisioning the user.

*************************************************************************************/
trigger UserTrigger on User (after insert, after update) {
    TriggerDispatcher.Run('User', Trigger.operationType);
}