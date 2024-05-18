/**
 * @description       :  This is an invoker action that sets the job commission multiplier parameter configuration
 *                      for it's tier and number of employee commissions.  This invoker is called in flow
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 12-14-2023
 * @last modified by  : Terri Jiles
**/
global without sharing class CommissionMultiplierConfigurationInvoker {
    @InvocableMethod(label='Get Commission Multiplier Parameter Information' 
    description='Get the Commission Multiplier parameter information based on Job Commission\'s number of commissionable employees and the job commission margin tier. ' 
    category='Sales Incentive Plan' 
    iconName='slds:utility:moneybag')
    public static List<Job_Commission__c> setMultipliers(List<Job_Commission__c> jobCommissionLst) {
        return CommissionMultiplierConfigurationService.setMultiplierInfo(jobCommissionLst);
    }
}