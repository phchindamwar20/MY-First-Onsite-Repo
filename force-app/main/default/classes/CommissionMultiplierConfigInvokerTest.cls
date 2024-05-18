/**
 * @description       : This is the test class for CommissionMultiplierConfigurationInvoker
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 02-23-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public with sharing class CommissionMultiplierConfigInvokerTest {
    
    @isTest
    private static void testInvoker() {
        List<Job_Commission__c> jobComLst = new List<Job_Commission__c>();
        jobComLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_1, Number_of_Commissionable_Employees__c=1));

        Test.startTest();
        jobComLst = CommissionMultiplierConfigurationInvoker.setMultipliers(jobComLst);
        Test.stopTest();

        Job_Commission_Multiplier__mdt jcm = Job_Commission_Multiplier__mdt.getInstance('Tier_1_1');
        System.assertEquals(jcm.Split_Multiplier__c, jobComLst[0].Split_Multiplier__c);
        System.assertEquals(jcm.Max_Split_Percent_for_One_EC__c, jobComLst[0].Max_Split_Percentage__c);
        System.assertEquals(jcm.Max_Number_of_Employee_Commissions__c, jobComLst[0].Max_Number_of_Employee_Commissions__c);
        System.assertEquals(jcm.Min_Number_of_Employee_Commissions__c, jobComLst[0].Min_Number_of_Employee_Commissions__c);
        System.assertEquals(jcm.Max_Total_Sharable_Percent__c, jobComLst[0].Max_Total_Sharable_Percentage__c);
    }
}