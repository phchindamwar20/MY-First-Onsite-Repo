/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-09-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-09-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
public with sharing class ProtocolMigrationTest {
    @TestSetup
    static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=true;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
            dataAdmin.SetupOwnerId = UserInfo.getUserId();
            insert dataAdmin;  
        }
        else {
            update dataAdmin;
        } 
                
        TestFactory.createJobTestData(100);  
         
    }

    @isTest
    static void testBatch() {

        test.startTest();
        Id result = Database.executeBatch(new ProtocolMigration(), 100);
        test.stopTest();

        Integer count = 0;
        for (WorkOrder job : [SELECT ID FROM WorkOrder WHERE Protocols_ACM_Testing__c != null AND Protocols_Adjusters__c != null AND  Protocols_Billing__c != null AND Protocols_Broker__c != NULL AND Protocols_DFRs__c != NULL AND Protocols_Portal__c != null AND Protocols_Pricing__c != null AND Protocols_Special_Concerns__c != null AND Protocols_Work_Auth_PO__c != NULL]) {
            System.debug('~~~~ ProtocolMigrationTest::testBatch: job - ' + job);
            count++;
        }

        System.assert(count > 0);
    }
}