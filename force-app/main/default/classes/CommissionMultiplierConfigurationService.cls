/**
 * @description       : This configures the mulitiplier based on the number of commissionable employees on a job commission
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 02-27-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class CommissionMultiplierConfigurationService {
    public static List<Job_Commission__c> setMultiplierInfo(List<Job_Commission__c> jobCommissionLst) {        
        Set<String> tiers = new Set<String>();
        for (Job_Commission__c jobCom : jobCommissionLst) {
            tiers.add(jobCom.Margin_Tier__c);
        }

        List<Job_Commission_Multiplier__mdt> jobCommissionMultiplierLst = [SELECT DeveloperName, Split_Multiplier__c, Max_Total_Sharable_Percent__c, Max_Number_of_Employee_Commissions__c, Min_Number_of_Employee_Commissions__c, Max_Split_Percent_for_One_EC__c, Job_Commission_Configuration__r.DeveloperName 
                                                                            FROM Job_Commission_Multiplier__mdt 
                                                                            WHERE Job_Commission_Configuration__r.DeveloperName=:tiers];

        for (Job_Commission__c jobCom : jobCommissionLst) {
            for (Job_Commission_Multiplier__mdt jobComMultiplier : jobCommissionMultiplierLst) {
                if (jobComMultiplier.Job_Commission_Configuration__r.DeveloperName == jobCom.Margin_Tier__c ) {
                    if(jobComMultiplier.Max_Number_of_Employee_Commissions__c == null && jobComMultiplier.Min_Number_of_Employee_Commissions__c != null && 
                            jobCom?.Number_of_Commissionable_Employees__c >= jobComMultiplier.Min_Number_of_Employee_Commissions__c) {
                        jobCom = setMultiplierInfo(jobCom, jobComMultiplier);
                        break;
                    } else if (jobComMultiplier.Max_Number_of_Employee_Commissions__c != null && jobComMultiplier.Min_Number_of_Employee_Commissions__c != null) {
                        if (jobComMultiplier.Max_Number_of_Employee_Commissions__c > jobCom?.Number_of_Commissionable_Employees__c &&  jobCom?.Number_of_Commissionable_Employees__c >= jobComMultiplier.Min_Number_of_Employee_Commissions__c) {
                            jobCom = setMultiplierInfo(jobCom, jobComMultiplier);
                            break;
                        } else if (jobComMultiplier.Min_Number_of_Employee_Commissions__c == 0 && jobCom?.Number_of_Commissionable_Employees__c == null) {
                            jobCom = setMultiplierInfo(jobCom, jobComMultiplier);
                            break;
                        }
                    } 
                }
            }
        }

        return jobCommissionLst;
    }

    private static Job_Commission__c setMultiplierInfo(Job_Commission__c jobCom, Job_Commission_Multiplier__mdt jobComMultiplier) {
        jobCom.Max_Split_Percentage__c=jobComMultiplier.Max_Split_Percent_for_One_EC__c;
        jobCom.Split_Multiplier__c = jobComMultiplier.Split_Multiplier__c;
        jobCom.Max_Number_of_Employee_Commissions__c = jobComMultiplier.Max_Number_of_Employee_Commissions__c;
        jobCom.Min_Number_of_Employee_Commissions__c = jobComMultiplier.Min_Number_of_Employee_Commissions__c;
        jobCom.Max_Total_Sharable_Percentage__c = jobComMultiplier.Max_Total_Sharable_Percent__c;

        return jobCom;
    }
}