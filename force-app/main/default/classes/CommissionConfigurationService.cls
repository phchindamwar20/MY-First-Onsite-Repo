/**
 * @description       : This configures the tier and associated parameters for a job commission record
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-20-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class CommissionConfigurationService {
    public static List<Job_Commission__c> setTiers(List<Job_Commission__c> jobCommissionLst) {
        List<Job_Commission_Configuration__mdt> jobCommConfigLst = Job_Commission_Configuration__mdt.getAll().values();

        for (Job_Commission__c jobCom : jobCommissionLst) {
            for (Job_Commission_Configuration__mdt config : jobCommConfigLst) {
                if (jobCom.Job_Margin__c != null) {
                    //Tier 1
                    if (config.Maximum_Margin_for_Tier__c == null && config.Minimum_Margin_for_Tier__c != null &&
                            jobCom.Job_Margin__c >= config.Minimum_Margin_for_Tier__c) {
                        jobCom = setConfig(jobCom, config);
                        break;
                    } 
                    //Tier 2 or 3
                    else if (config.Maximum_Margin_for_Tier__c != null && config.Minimum_Margin_for_Tier__c != null &&
                            config.Maximum_Margin_for_Tier__c > jobCom.Job_Margin__c && jobCom.Job_Margin__c >= config.Minimum_Margin_for_Tier__c) {
                        jobCom = setConfig(jobCom, config);
                        break;
                    } else if ( config.Maximum_Margin_for_Tier__c != null && config.Minimum_Margin_for_Tier__c == null  &&
                            config.Maximum_Margin_for_Tier__c > jobCom.Job_Margin__c ) {
                        jobCom = setConfig(jobCom, config);
                        break;
                    }
                //Tier 4 
                } else if (jobCom.Job_Margin__c == null && config.DeveloperName == SalesIncentivePlanConstants.TIER_4) {
                    jobCom = setConfig(jobCom, config);
                    break;
                }
            }
        }
        return jobCommissionLst;
    }

    private static Job_Commission__c setConfig(Job_Commission__c jobCom, Job_Commission_Configuration__mdt config) {
        jobCom.Collection_Incentive_Threshold__c=config.Collection_Incentive_Threshold__c;
        jobCom.Deposit1st_Payment_Incentive_Threshold__c=config.Deposit1st_Payment_Incentive_Threshold__c;
        jobCom.Deposit_First_Payment_Incentive__c=config.DepositFirst_Payment_Incentive__c;
        jobCom.Margin_Tier__c=config.DeveloperName;
        jobCom.Maximum_Margin_for_Tier__c=config.Maximum_Margin_for_Tier__c;
        jobCom.Minimum_Margin_for_Tier__c=config.Minimum_Margin_for_Tier__c;
        jobCom.Quick_Collection_Incentive__c=config.Quick_Collection_Incentive__c;
        jobCom.Slow_Collection_Incentive__c=config.Slow_Collection_Incentive__c;

        return jobCom;
    }
}