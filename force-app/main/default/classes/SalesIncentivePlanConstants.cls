/**
 * @description       : This is the constants  for functionality related to the sales incentive plan:
 *                          Commissions:  Job Commisions, Employee Commissions
 *                          Goal Accelerator:  Goal Accelerators, Goal Acclerator Items
 *                          Base Bonus Accelerator:  Base Bonus Accelerator, Base Bonus Accelerator Items
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-30-2024
 * @last modified by  : Terri Jiles
**/
public class SalesIncentivePlanConstants {

    //Job Commission Job Margin Tier api values
	public final static String TIER_1 = 'Tier_1';
    public final static String TIER_2 = 'Tier_2';
    public final static String TIER_3 = 'Tier_3';
    public final static String TIER_4 = 'Tier_4';

    //Yes/No Picklist
    public final static String YES = 'Yes';
    public final static String NO = 'No';

    //Total Collection Type Picklist Values
    public final static String QUICK_COLLECTION = 'Quick Collection';
    public final static String SLOW_COLLECTION = 'Slow Collection';
    public final static String NONE = 'None';

    //Job Commission Statuses
    public final static String JC_STATUS_OPEN = 'Open';
    public final static String JC_STATUS_FINALIZED = 'Finalized';
    public final static String JC_STATUS_PAID = 'Paid';
    
    //Employee Commission Statuses
    public final static String EC_STATUS_PAID = 'Paid';

    //Bolt Log Error Record Type
    public final static String BOLT_LOG_RT_Name = 'Sales_Incentive_Plan_Error';
}