/**
 * @description       : This is the test class for SandboxUserSetupService
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-19-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public with sharing class SandboxUserSetupServiceTest {
    
    @isTest
    private static void testSandboxUserSetupService() {
        Test.startTest();
        SandboxUserSetupService sbus = new SandboxUserSetupService(25);
        sbus.setupSandboxUsers();
        Test.stopTest();

        System.assert(Database.countQuery('SELECT count() FROM Sandbox_User__mdt WHERE Skip_User__c=false') <= Database.countQuery('SELECT count() FROM User WHERE Is_Sandbox_User__c=true'));
    }

    @isTest
    private static void testSandboxUserSetupServiceDefault() {
        Test.startTest();
        SandboxUserSetupService sbus = new SandboxUserSetupService();
        sbus.setupSandboxUsers();
        Test.stopTest();

        System.assert(Database.countQuery('SELECT count() FROM Sandbox_User__mdt WHERE Skip_User__c=false') <= Database.countQuery('SELECT count() FROM User WHERE Is_Sandbox_User__c=true'));
    }

    @isTest
    private static void testSandboxUserSetupServiceNull() {
        Test.startTest();
        SandboxUserSetupService sbus = new SandboxUserSetupService(null);
        sbus.setupSandboxUsers();
        Test.stopTest();

        System.assert(Database.countQuery('SELECT count() FROM Sandbox_User__mdt WHERE Skip_User__c=false') <= Database.countQuery('SELECT count() FROM User WHERE Is_Sandbox_User__c=true'));
    }

    @isTest
    private static void testSandboxUserSetupServiceZero() {
        Test.startTest();
        SandboxUserSetupService sbus = new SandboxUserSetupService(0);
        sbus.setupSandboxUsers();
        Test.stopTest();

        System.assert(Database.countQuery('SELECT count() FROM Sandbox_User__mdt WHERE Skip_User__c=false') <= Database.countQuery('SELECT count() FROM User WHERE Is_Sandbox_User__c=true'));
    }
}