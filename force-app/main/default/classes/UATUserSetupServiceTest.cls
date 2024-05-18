/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-03-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-03-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest(SeeAllData=false)
public with sharing class UATUserSetupServiceTest {
    @TestSetup
    static void makeData(){
        TestFactory.createUsers();
    }

    @isTest
    static void testSetupUAT() {
        Test.startTest();

        try {
            UATUserSetupService.updateUatUsers();
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Unable to setup UAT Users');
        }
    }

}