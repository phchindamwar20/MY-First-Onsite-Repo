/**
 * @description       : This is the test class for CommissionConfigurationInvoker.  
 *                      Please note, the more robust test cases for this are in CommissionConfigurationInvokerTest, which 
 *                      test the CommissionConfigurationService
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 02-26-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class CommissionConfigurationInvokerTest {
    @isTest
    private static void testInvoker() {
        List<Job_Commission__c> jobCommissionLst = new List<Job_Commission__c>();
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=50)); //tier 1
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=45)); //tier 1 
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=43)); //tier 2
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=38)); //tier 2
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=29)); //tier 3
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=25)); //tier 3
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=24.9999));  //tier 4
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=0));  //tier 4

        Test.startTest();
        jobCommissionLst = CommissionConfigurationInvoker.configureJobCommissions(jobCommissionLst);
        Test.stopTest();

        for (Job_Commission__c jobCom : jobCommissionLst) {
            Assert.isNotNull(jobCom.Margin_Tier__c, 'Fail:  No margin tier set');
        }
        
    }
}