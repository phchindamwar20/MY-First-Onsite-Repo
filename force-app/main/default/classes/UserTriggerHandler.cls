/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    User trigger Hanlder, which is called on any DML gets performed on User Object.
Class:     		UserTriggerHandler.cls
Test Class:     UserTriggerHandlerTest.cls

History:
When        	Who         		What
21-June-2022	Arpit				Added the code to send the API callout to ICI for provisioning the user.

*************************************************************************************/
public without sharing class UserTriggerHandler extends TriggerHandlerBase {
    public UserTriggerHandler() {}
}//End of UserTriggerHandler class