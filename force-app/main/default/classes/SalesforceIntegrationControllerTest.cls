@IsTest(SeeAllData = true)
public with sharing class SalesforceIntegrationControllerTest {

 @IsTest
 static void testLoginWithInvalidCredentials() {
  Map<String,List<SObject>> objects = SalesforceIntegrationController.getUserInformation();
  System.assertNotEquals(true, objects.isEmpty());
 }
}