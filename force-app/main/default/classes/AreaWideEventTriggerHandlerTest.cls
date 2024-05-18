/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-01-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class AreaWideEventTriggerHandlerTest {
    @TestSetup
    private static void makeData(){
        List<Area_Wide_Event__c> aweLst = new List<Area_Wide_Event__c>(); 
        
        for (Integer i=0 ; i<200 ; i++) {
            aweLst.add(new Area_Wide_Event__c(Name='Test ' + String.valueOf(i), Active__c=true, Event_Type__c='Area Wide Event'));
        }

        insert aweLst;
    }

    @isTest
    private static void testInsertAwe() {
        //since we are just calling web service in the trigger and can't call the web service during test execution
        //we'll just verify that the awes were inserted
        System.assert([SELECT Id FROM Area_Wide_Event__c].size()==200, 'AWEs not inserted');
    }

    @isTest
    private static void testUpdateAwe() {
        //since we are just calling web service in the trigger and can't call the web service during test execution
        //we'll just verify that the awes were updated
        List<Area_Wide_Event__c> aweLst = new List<Area_Wide_Event__c>();
        for (Area_Wide_Event__c awe : [SELECT Id FROM Area_Wide_Event__c]) {
            aweLst.add(new Area_Wide_Event__c(Id=awe.Id, Active__c=false));
        }

        Test.startTest();
        update aweLst;
        Test.stopTest();

        System.assert([SELECT Id FROM Area_Wide_Event__c WHERE Active__c=false].size()==200, 'AWE not updated to false');
    }
}