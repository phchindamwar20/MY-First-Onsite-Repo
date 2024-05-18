/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-29-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public without sharing class BranchManagerTest {
    private static String REQUEST_URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexRest/Branches';

    @TestSetup
    static void makeData(){
        Bolt__c integrationBolt = new Bolt__c(SetupOwnerId = UserInfo.getUserId(), Is_Bolt_Integration_User__c=true);
        insert integrationBolt; //prevents trigger from firing integration back to Bolt, since the integration bolt user created the record
        Map<String, ServiceTerritory> serviceTerritoryByNameMap = TestFactory.createServiceTerritories();
    }

    @isTest
    private static void testGetBranch() {        
        RestRequest request = new RestRequest();
        request.requestUri = REQUEST_URI;
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        // Update status of existing record to Working
        Test.startTest();
        List<ServiceTerritory> branchLst = BranchManager.getBranches();
        //PropertyManager.POST;
        Test.stopTest();
        // Verify records obtained
        System.assert(branchLst.size() > 0);
    }   
}