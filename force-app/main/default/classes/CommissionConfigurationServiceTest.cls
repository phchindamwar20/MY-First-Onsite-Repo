/**
 * @description       : This is the test class for CommissionConfigurationService
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-20-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class CommissionConfigurationServiceTest {
    @isTest
    private static void testTiers() {
        Integer tier1=0, tier2=0, tier3=0, tier4=0;
        List<Job_Commission__c> jobCommissionLst = new List<Job_Commission__c>();
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=24.9999));  //tier 4
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=null)); //tier 4
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=50)); //tier 1
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=45)); //tier 1 
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=43)); //tier 2
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=38)); //tier 2
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=29)); //tier 3
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=25)); //tier 3
        //jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=24.9999));  //tier 4
        jobCommissionLst.add(new Job_Commission__c(Job_Margin__c=0));  //tier 4

        Test.startTest();
        jobCommissionLst = CommissionConfigurationService.setTiers(jobCommissionLst);
        Test.stopTest();


        for (Job_Commission__c jobCom : jobCommissionLst) {
            CommissionCalTestUtility.assertCommissionParameters(jobCom);
            for (Job_Commission_Configuration__mdt config : Job_Commission_Configuration__mdt.getAll().values()) {
                if(jobCom.Margin_Tier__c == SalesIncentivePlanConstants.TIER_1) {
                    tier1++;
                    break;
                } else if (jobCom.Margin_Tier__c == SalesIncentivePlanConstants.TIER_2) {
                    tier2++;
                    break;
                } else if (jobCom.Margin_Tier__c == SalesIncentivePlanConstants.TIER_3) {
                    tier3++;
                    break;
                } else if (jobCom.Margin_Tier__c == SalesIncentivePlanConstants.TIER_4) {
                    tier4++;
                    break;
                }
            }
        }  
        
        Assert.areEqual(2, tier1, 'failed:  Expected 2 tier 1 matches, received ' + tier1);
        Assert.areEqual(2, tier2, 'failed:  Expected 2 tier 2 matches, received ' + tier2);
        Assert.areEqual(2, tier3, 'failed:  Expected 2 tier 3 matches, received ' + tier3);
        Assert.areEqual(3, tier4, 'failed:  Expected 2 tier 4 matches, received ' + tier4);
    }
}