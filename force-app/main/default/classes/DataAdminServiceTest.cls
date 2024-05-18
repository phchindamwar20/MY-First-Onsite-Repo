/**
 * @description       : The purpose of this test class is to test DataAdminService class
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-02-2024
 * @last modified by  : Terri Jiles
**/
@isTest
private without sharing class DataAdminServiceTest {
    @TestSetup
    private static void makeData(){
        TestFactory.createUsers();
    }

    @isTest 
    private static void testUserNoDataAdmin() {
        User admin = [SELECT Id fROM User WHERE ADP_Associate_OID__c ='ABCD22222222' LIMIT 1];

        System.runAs(admin) {
            //prevalidation verify no data admin
            Assert.areEqual(0, [SELECT Id FROM DataAdmin__c WHERE SetupOwnerId=:admin.Id].size(), 'Failed:  expected the data admin record for user not to exists since this is a new user');

            DataAdminService das = new DataAdminService();
            
            //assert revert flag is false because no dataadmin exists for user
            Assert.areEqual(false, das.isRevertDataAdmin, 'Failed:  ReverDataAdmin is suppose to be false because the user did not have a data admin user');

            //create data admin record
            das.modifyDataAdmin(true, true, true, true, true);

            //verify record created with all set to true
            DataAdmin__c daAdmin = DataAdmin__c.getInstance(admin.Id);

            //verify data admin updated as expected
            Assert.areEqual(admin.Id, daAdmin.SetupOwnerId, 'Failed:  setup owner id not admin');
            Assert.areEqual(true, daAdmin.TurnOffFlow__c, 'Failed:  turn off flow suppose to be true');
            Assert.areEqual(true, daAdmin.TurnOffProcessBuilder__c, 'Failed:  turn off process builder suppose to be true');
            Assert.areEqual(true, daAdmin.TurnOffTrigger__c, 'Failed: turn off trigger suppose to be true');
            Assert.areEqual(true, daAdmin.TurnOffValidationRules__c, 'Failed: turn off validation rules suppose to be true');
            Assert.areEqual(true, daAdmin.TurnOffWorkflow__c, 'Failed: turn off workflow rules suppose to be true');

            //revert data admin
            das.reverDataAdmin();

            //verify data admin deleted
            Assert.areEqual(0, [SELECT Id FROM DataAdmin__c WHERE SetupOwnerId=:admin.Id].size(), 'Failed:  expected the data admin record for user to be deleted since we are reverting back to an intial state');
        }
    }

    @isTest 
    private static void testUserExistingDataAdmin() {
        User admin = [SELECT Id fROM User WHERE ADP_Associate_OID__c ='ABCD22222222' LIMIT 1];

        System.runAs(admin) {
            //create initial data admin
            DataAdmin__c newDataAdmin = new DataAdmin__c(SetupOwnerId=admin.Id, TurnOffFlow__c=true, TurnOffProcessBuilder__c=true, TurnOffTrigger__c=true, TurnOffValidationRules__c=true, TurnOffWorkflow__c=true);
            insert newDataAdmin;

            //prevalidation verify existing data admin
            Assert.areEqual(1, [SELECT Id FROM DataAdmin__c WHERE SetupOwnerId=:admin.Id].size(), 'Failed:  expected the data admin record for user  to exists');

            DataAdminService das = new DataAdminService();
            
            //assert revert flag is true because dataadmin exists for user
            Assert.areEqual(true, das.isRevertDataAdmin, 'Failed:  ReverDataAdmin is suppose to be true because the user does have a data admin user');

            //create data admin record
            das.modifyDataAdmin(false, false, false, false, false);

            //verify record created with all set to true
            DataAdmin__c daAdmin = DataAdmin__c.getInstance(admin.Id);

            //verify data admin updated as expected
            Assert.areEqual(admin.Id, daAdmin.SetupOwnerId, 'Failed:  setup owner id not admin');
            Assert.areEqual(false, daAdmin.TurnOffFlow__c, 'Failed:  turn off flow suppose to be false');
            Assert.areEqual(false, daAdmin.TurnOffProcessBuilder__c, 'Failed:  turn off process builder suppose to be false');
            Assert.areEqual(false, daAdmin.TurnOffTrigger__c, 'Failed: turn off trigger suppose to be false');
            Assert.areEqual(false, daAdmin.TurnOffValidationRules__c, 'Failed: turn off validation rules suppose to be false');
            Assert.areEqual(false, daAdmin.TurnOffWorkflow__c, 'Failed: turn off workflow rules suppose to be false');

            //revert data admin
            das.reverDataAdmin();

            //verify data admin reverted as expected
            DataAdmin__c daAdminRevert = DataAdmin__c.getInstance(admin.Id);
            Assert.areEqual(admin.Id, daAdminRevert.SetupOwnerId, 'Failed:  setup owner id not admin');
            Assert.areEqual(true, daAdminRevert.TurnOffFlow__c, 'Failed:  turn off flow suppose to be true');
            Assert.areEqual(true, daAdminRevert.TurnOffProcessBuilder__c, 'Failed:  turn off process builder suppose to be true');
            Assert.areEqual(true, daAdminRevert.TurnOffTrigger__c, 'Failed: turn off trigger suppose to be true');
            Assert.areEqual(true, daAdminRevert.TurnOffValidationRules__c, 'Failed: turn off validation rules suppose to be true');
            Assert.areEqual(true, daAdminRevert.TurnOffWorkflow__c, 'Failed: turn off workflow rules suppose to be true');

        }
    }
}