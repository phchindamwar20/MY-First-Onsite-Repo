/**
 * @description       : This is an invoker action that sets the job commission parameter configuration
 *                      for it's tier based on the Job Margin.  This invoker is called in flow
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 02-27-2024
 * @last modified by  : Terri Jiles
**/
global without sharing class CommissionConfigurationInvoker {
    @InvocableMethod(label='Get Commission Parameter Information' 
                        description='Get the Commission Tier parameter information based on job\'s Margin from the Commission Configuration custom metadata type and set the tier calculation configuration information for each job commission record in the list' 
                        category='Sales Incentive Plan' 
                        iconName='slds:utility:moneybag')
    public static List<Job_Commission__c> configureJobCommissions(List<Job_Commission__c> jobCommissionLst) {
        return CommissionConfigurationService.setTiers(jobCommissionLst);
    }
}