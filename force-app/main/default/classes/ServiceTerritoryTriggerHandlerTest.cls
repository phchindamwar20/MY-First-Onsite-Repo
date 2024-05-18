/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-28-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class ServiceTerritoryTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getOrgDefaults();
        dataAdmin.TurnOffFlow__c=true;
        dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.SetupOwnerId=UserInfo.getUserId();
        insert dataAdmin;
        
        TestFactory.createJobTestData(200);  
    }

    @isTest
    static void testUpdateSimple() {
        List<ServiceTerritory> servTerrLst = new List<ServiceTerritory>();
        Id myId = UserInfo.getUserId();

        for (ServiceTerritory st : [SELECT Id, General_Manager__c FROM ServiceTerritory]) {
            servTerrLst.add(new ServiceTerritory(Id=st.Id, General_Manager__c=myId));
        }

        Test.startTest();
        update servTerrLst;
        Test.stopTest();

        System.assertEquals(200, [SELECT Id FROM WorkOrderShare WHERE UserOrGroupId=:myId AND
                                                                        AccessLevel='Edit' AND
                                                                        RowCause='Manual'].size());
    }
    static void testNoUpdate() {
        List<ServiceTerritory> servTerrLst = new List<ServiceTerritory>();
        Id myId = UserInfo.getUserId();

        List<Job_Sharing__c> jobSharingLst = new List<Job_Sharing__c>();
        for (WorkOrder job : [SELECT Id FROM WorkOrder]) {
            jobSharingLst.add(new Job_Sharing__c(Job__c=job.Id, User__c=myId));
        }
        insert jobSharingLst;
        System.assertEquals(200, [SELECT Id FROM WorkOrderShare WHERE UserOrGroupId=:myId AND
                                                                        AccessLevel='Edit' AND
                                                                        RowCause='Manual'].size());


        for (ServiceTerritory st : [SELECT Id, General_Manager__c FROM ServiceTerritory]) {
            servTerrLst.add(new ServiceTerritory(Id=st.Id, General_Manager__c=myId));
        }

        Test.startTest();
        update servTerrLst;
        Test.stopTest();

        //no double shares should be created
        System.assertEquals(200, [SELECT Id FROM WorkOrderShare WHERE UserOrGroupId=:myId AND
                                                                        AccessLevel='Edit' AND
                                                                        RowCause='Manual'].size());
    }    
}