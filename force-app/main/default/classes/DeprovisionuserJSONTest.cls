/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Test class for DeprovisionuserJSON
Class:     		DeprovisionuserJSONTest.cls

History:
When        	Who         		What
24-June-2022	Arpit				Test class for DeprovisionuserJSON

*************************************************************************************/
@IsTest
public class DeprovisionuserJSONTest {
	
	static testMethod void testParse() {
		String json = '{ '+
		'  \"EventType\": \"UserInformation\", '+
		'  \"EntityId\": null, '+
		'  \"InstanceId\": null, '+
		'  \"FromState\": null, '+
		'  \"ToState\": null, '+
		'  \"Action\": null, '+
		'  \"User\": null, '+
		'  \"TimeStamp\": \"2021-03-09T12:05:01\", '+
		'  \"Data\": { '+
		'    \"EmailID\": \"test1@test.com\", '+
		'    \"Action\": \"Reprovision\" '+
		'  } '+
		'}';
		DeprovisionuserJSON obj = DeprovisionuserJSON.parse(json);
		System.assert(obj != null);
	}
}