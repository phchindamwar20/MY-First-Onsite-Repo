/**
 * @description       : This is the test class for CommissionMultiplierConfigurationService
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-09-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public class CommissionMultiplierConfigServiceTest {
    @isTest
    private static void testTier1() {
        List<Job_Commission__c> jobCommLst = new List<Job_Commission__c>();
        List<Job_Commission__c> jobCommResultLst = new List<Job_Commission__c>();
        counter thisCounter = new counter();

        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_1, Number_of_Commissionable_Employees__c=null));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_1, Number_of_Commissionable_Employees__c=0));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_1, Number_of_Commissionable_Employees__c=1));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_1, Number_of_Commissionable_Employees__c=2));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_1, Number_of_Commissionable_Employees__c=3));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_1, Number_of_Commissionable_Employees__c=4));
        
        Test.startTest();
        jobCommResultLst = CommissionMultiplierConfigurationService.setMultiplierInfo(jobCommLst);
        Test.stopTest();
        
        for (Job_Commission__c jobCom : jobCommResultLst) {
            CommissionCalTestUtility.assertCommissionMultiplierParameters(jobCom);
            thisCounter.incCommissionMultiplierCounts(jobCom);
        }

        thisCounter.assertCommissionMultiplierCounts(SalesIncentivePlanConstants.TIER_1);
    }

    @isTest
    private static void testTier2() {
        List<Job_Commission__c> jobCommLst = new List<Job_Commission__c>();
        List<Job_Commission__c> jobCommResultLst = new List<Job_Commission__c>();
        counter thisCounter = new counter();

        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_2, Number_of_Commissionable_Employees__c=null));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_2, Number_of_Commissionable_Employees__c=0));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_2, Number_of_Commissionable_Employees__c=1));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_2, Number_of_Commissionable_Employees__c=2));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_2, Number_of_Commissionable_Employees__c=3));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_2, Number_of_Commissionable_Employees__c=4));
        
        Test.startTest();
        jobCommResultLst = CommissionMultiplierConfigurationService.setMultiplierInfo(jobCommLst);
        Test.stopTest();
        
        for (Job_Commission__c jobCom : jobCommResultLst) {
            CommissionCalTestUtility.assertCommissionMultiplierParameters(jobCom);
            thisCounter.incCommissionMultiplierCounts(jobCom);
        }

        thisCounter.assertCommissionMultiplierCounts(SalesIncentivePlanConstants.TIER_2);
     }    
    
    @isTest
    private static void testTier3() {
        List<Job_Commission__c> jobCommLst = new List<Job_Commission__c>();
        List<Job_Commission__c> jobCommResultLst = new List<Job_Commission__c>();
        counter thisCounter = new counter();
        
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_3, Number_of_Commissionable_Employees__c=null));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_3, Number_of_Commissionable_Employees__c=0));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_3, Number_of_Commissionable_Employees__c=1));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_3, Number_of_Commissionable_Employees__c=2));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_3, Number_of_Commissionable_Employees__c=3));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_3, Number_of_Commissionable_Employees__c=4));
        
        Test.startTest();
        jobCommResultLst = CommissionMultiplierConfigurationService.setMultiplierInfo(jobCommLst);
        Test.stopTest();
        
        for (Job_Commission__c jobCom : jobCommResultLst) {
            CommissionCalTestUtility.assertCommissionMultiplierParameters(jobCom);
            thisCounter.incCommissionMultiplierCounts(jobCom);
        }

        thisCounter.assertCommissionMultiplierCounts(SalesIncentivePlanConstants.TIER_3);
    }    
    
    @isTest
    private static void testTier4() {
        List<Job_Commission__c> jobCommLst = new List<Job_Commission__c>();
        List<Job_Commission__c> jobCommResultLst = new List<Job_Commission__c>();
        counter thisCounter = new counter();
        
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_4, Number_of_Commissionable_Employees__c=null));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_4, Number_of_Commissionable_Employees__c=0));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_4, Number_of_Commissionable_Employees__c=1));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_4, Number_of_Commissionable_Employees__c=2));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_4, Number_of_Commissionable_Employees__c=3));
        jobCommLst.add(new Job_Commission__c(Margin_Tier__c=SalesIncentivePlanConstants.TIER_4, Number_of_Commissionable_Employees__c=4));
        
        Test.startTest();
        jobCommResultLst = CommissionMultiplierConfigurationService.setMultiplierInfo(jobCommLst);
        Test.stopTest();
        
        for (Job_Commission__c jobCom : jobCommResultLst) {
            CommissionCalTestUtility.assertCommissionMultiplierParameters(jobCom);
            thisCounter.incCommissionMultiplierCounts(jobCom);
        }

        thisCounter.assertCommissionMultiplierCounts(SalesIncentivePlanConstants.TIER_4);
     }    

    private class counter {
        public Integer ecCount1=0;
        public Integer ecCount2=0;
        public Integer ecCount3=0;

        public void  assertCommissionMultiplierCounts(String tier) {
            Assert.areEqual(3, ecCount1, 'Failed:  expected 3 for multiplier of ' + Job_Commission_Multiplier__mdt.getInstance(tier+'_1').Split_Multiplier__c +', only received ' + ecCount1);
            Assert.areEqual(1, ecCount2, 'Failed:  expected 1 for multiplier of ' + Job_Commission_Multiplier__mdt.getInstance(tier+'_2').Split_Multiplier__c +', only received ' + ecCount2);
            Assert.areEqual(2, ecCount3, 'Failed:  expected 2 for multiplier of ' + Job_Commission_Multiplier__mdt.getInstance(tier+'_3').Split_Multiplier__c +', only received ' + ecCount3);            
        }

        public void incCommissionMultiplierCounts(Job_Commission__c jobCom) {
            String tier = jobCom.Margin_Tier__c;
    
            if (jobCom?.Number_of_Commissionable_Employees__c == null || 
                    (
                        Job_Commission_Multiplier__mdt.getInstance(tier+'_1').Min_Number_of_Employee_Commissions__c <= jobCom?.Number_of_Commissionable_Employees__c && 
                        jobCom?.Number_of_Commissionable_Employees__c < Job_Commission_Multiplier__mdt.getInstance(tier+'_1').Max_Number_of_Employee_Commissions__c
                    )
                ) {
                ecCount1++;
            } else if (
                Job_Commission_Multiplier__mdt.getInstance(tier+'_2').Min_Number_of_Employee_Commissions__c <= jobCom?.Number_of_Commissionable_Employees__c && 
                jobCom?.Number_of_Commissionable_Employees__c < Job_Commission_Multiplier__mdt.getInstance(tier+'_2').Max_Number_of_Employee_Commissions__c
            ) {
                ecCount2++;
            } else if (
                Job_Commission_Multiplier__mdt.getInstance(tier+'_3').Min_Number_of_Employee_Commissions__c <= jobCom?.Number_of_Commissionable_Employees__c 
            ) {
                ecCount3++;
            } else {
                Assert.fail('No match on commission multiplier');
            }
        }
        
    }
}