/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-29-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest(seeAllData=false)
public without sharing class BranchTestDataQueueableTest {
    @TestSetup
    static void makeData(){
        SandboxTestData.upsertSandboxData();
        delete [SELECT Id FROM Contract];
        delete [SELECT Id FROM Contact];
        delete [SELECT Id FROM Opportunity];
        delete [SELECT Id FROM WorkOrder];
        delete [SELECT Id FROM Account];
    }

    @isTest 
    private static void testBranchTestDataQueable() {
        BranchTestDataQueueable btdq = new BranchTestDataQueueable();
        test.startTest();
        System.enqueueJob(btdq);
        test.stopTest();

        System.assert([SELECT Id FROM Account WHERE RecordType.DeveloperName='Parent'].size() > 0);
        System.assert([SELECT Id FROM Account WHERE RecordType.DeveloperName='Account'].size() > 0);
        System.assert([SELECT Id FROM Account WHERE RecordType.DeveloperName='Property'].size() > 0);
        //System.assert([SELECT Id FROM Contract].size()>1);
        System.assert([SELECT Id FROM WorkOrder].size()>30);
    }

}