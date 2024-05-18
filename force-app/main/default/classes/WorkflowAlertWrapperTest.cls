/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Test class for WorkflowAlertWrapper

History:
When        	Who         		What
24-June-2022	Arpit				Added code to cover code of WorkflowAlertWrapper.cls

*************************************************************************************/
@isTest
private class WorkflowAlertWrapperTest {
    
	static testMethod void testParse() {
		String json = '{\"size\":95,\"totalSize\":95,\"done\":true,\"queryLocator\":null,\"entityTypeName\":\"WorkflowAlert\",\"records\":[{\"attributes\":{\"type\":\"WorkflowAlert\",\"url\":\"/services/data/v33.0/tooling/sobjects/WorkflowAlert/01W1U000000GxVGUA0\"},\"Id\":\"01W1U000000GxVGUA0\",\"CcEmails\":\"arpit.vashishtha@firstonsite.com\"},{\"attributes\":{\"type\":\"WorkflowAlert\",\"url\":\"/services/data/v33.0/tooling/sobjects/WorkflowAlert/01W1U000000GxVGUA0\"},\"Id\":\"01W1U000000GxVGUA0\",\"CcEmails\":\"arpit.vashishtha@firstonsite.com\"}]}';
		WorkflowAlertWrapper obj = WorkflowAlertWrapper.parse(json);
		System.assert(obj != null);
	}
}