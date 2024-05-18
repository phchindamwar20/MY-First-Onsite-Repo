/**
 * @File Name          : SandboxTestData_Test.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 12-12-2022
 * @Modification Log   : 
 * Ver       Date            Author              Modification
 * 1.0    1/27/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 * 2.0    05/07/2024  Kiran K (CFS)               STAR-6221 remove opportunity references
**/ 

@isTest (SeeAllData=false)
public class SandboxTestData_Test {
    @isTest
    static void  testSandboxTestData() {  
        /*
        DataAdmin__c dataAdmin = new DataAdmin__c();
        dataAdmin.TurnOffTrigger__c=true;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        insert dataAdmin;
        */

        Test.startTest();

        Test.testSandboxPostCopyScript(
            new SandboxTestData(), UserINfo.getOrganizationId(), 
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName());

        Test.stopTest();

        System.assert([Select Id From WorkType WHERE ShouldAutoCreateSvcAppt=false].size() > 0);
        System.assert([Select Id From Pricebook2].size() > 0);
        System.assert([Select Id From OperatingHours].size() > 0);
        System.assert([Select id From ServiceTerritory].size() > 0);
        System.assert([Select Id From TimeSlot].size() > 0);
        System.assert([Select Id From Account].size() > 0);
        System.assert([Select Id From Contact].size() > 0);
        System.assert([Select Id From Contract].size() > 0);
        System.assert([Select Id From WorkOrder].size() > 0);
        System.assert([SELECT ID FROM Contact WHERE Name = 'Joe Schomoe' Limit 1].size() > 0);
        System.assert([SELECT ID FROM Account WHERE Parent_Portal_Account__c != NULL].size() > 0);
        //System.assert([SELECT ID FROM Invoice_Request_Form__c].size() > 0);
        System.assert([SELECT ID FROM Area_Wide_Event__c].size() > 0);

    }
}