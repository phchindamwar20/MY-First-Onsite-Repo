/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Test class for UpdateEmailAlert.cls
Class:     		UpdateEmailAlertTest.cls

History:
When        	Who         		What
20-July-2022	Arpit				Test class for UpdateEmailAlert.cls

*************************************************************************************/
@isTest 
public class UpdateEmailAlertTest {
    @isTest
    static void UpdateEmailAlertTest() {
        Test.startTest();
        //Setting Mock class to return the response as per the API response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(WebServiceMock.class, new CallOutMock());
        UpdateEmailAlert.getEmailAlert();
        String hostName = System.Url.getSalesforceBaseUrl().getHost();
        EnvironmentHelper.isSandbox(hostName);
        Test.stopTest();
    }
}