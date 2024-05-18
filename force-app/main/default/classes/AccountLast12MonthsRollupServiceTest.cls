/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-01-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class AccountLast12MonthsRollupServiceTest {
    @TestSetup
    private static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=true;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.TurnOffFlow__c=true;
        if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
            dataAdmin.SetupOwnerId = UserInfo.getUserId();
            insert dataAdmin;  
        }
        else {
            update dataAdmin;
        } 
    }

    @isTest
    static private void testStar3294Example() {
        /*Parent Record Type accounts should sum the Number of Jobs and Contracted Sales / Revised Contract Amount fields on all children in their hierarchy where Record Type = Parent or Account to calculate the Tier criteria.
        Example: Account 1 (Parent Record Type) is parent to Child 1 (Account RT), Child 2 (Account RT) and Child 3 (Parent RT). Child 3 is a parent to Child 4. In the last 12 months:
            Child 1 (Account) has 10 jobs with Contracted Sales of $500,000 and is Tier 2.
            Child 2 (Account) has 25 jobs with Contracted Sales of $400,000 and is Tier 2.  
            Child 3 (Parent) has 1 job with Contracted Sales of $50,000 which would normally put this account at Tier 4, but with Child 4, has 24 jobs and $500,000 of contracted sales, thus is Tier 2. 
            Child 4 (Account) has 23 jobs with Contracted Sales of $450,000 and thus is Tier 3.
            Account 1 would show 0 jobs and 59 child jobs with Contracted sales of $0 and $1,400,000 child Contracted Sales and be Tier 1.*/

            Account parentAcc = (Account)TestFactory.createSObject(new Account(RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId(), Name='Parent'), 'TestFactoryDefaults.AccountDefaults', true);
            Account child1 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId(), Name='Child1'), 'TestFactoryDefaults.AccountDefaults', true);
                List<WorkOrder> child1JobLst = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=child1.Id, ROM_Contracted_Sales__c=50000.00, Status='In Progress'), 10, 'TestFactoryDefaults.JobDefaults', true);
            Account child2 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId(), Name='Child2'), 'TestFactoryDefaults.AccountDefaults', true);
                List<WorkOrder> child2JobLst = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=child2.Id, ROM_Contracted_Sales__c=16000.00, Status='Work Complete'), 25, 'TestFactoryDefaults.JobDefaults', true);
            Account child3 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId(), Name='Child3'), 'TestFactoryDefaults.AccountDefaults', true);
                List<WorkOrder> child3JobLst = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=child3.Id, ROM_Contracted_Sales__c=50000.00, Status='Pre-production'), 1, 'TestFactoryDefaults.JobDefaults', true);
            Account child4 = (Account)TestFactory.createSObject(new Account(ParentId=child3.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId(), Name='Child4'), 'TestFactoryDefaults.AccountDefaults', true);
                List<WorkOrder> child4JobLst = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=child4.Id, ROM_Contracted_Sales__c=19565.22, Status='AR Pending'), 23, 'TestFactoryDefaults.JobDefaults', true);

            for (WorkOrder job : [SELECT AccountId, Account.Name, Account.ParentId, Id, ROM_Contracted_Sales__c FROM WorkOrder ORDER BY AccountId]) {
                System.debug('~~~~ AccountLast12MonthsRollupServiceTest::testStar3294Example: job ' + job);
            }

            Test.startTest();
            AccountLast12MonthsRollupService.rollUpJobsOnAccounts([SELECT Id, Name, ParentId, Tier__c, Tier_Override__c, Last_Modified_Tier_By__c, Last_Date_Tier_Set__c FROM Account WHERE RecordType.DeveloperName In ('Parent', 'Account')]);
            Test.stopTest();
            
            for (Account acc : [SELECT Id, Name, Tier__c, Last_12_Months_Contracted_Sales__c, Last_12_Months_Number_of_Jobs__c, Last_12_Months_Contracted_Sales_Children__c, Last_12_Months_Number_of_Jobs_Children__c, Last_12_Months_Contracted_Sales_All__c, Last_12_Months_Number_of_Jobs_All__c FROM Account]) {
                System.debug('~~~~ AccountLast12MonthsRollupServiceTest::testStar3294Example: acc '+ acc);
            }

            System.assertEquals(1, [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId()
                                                            AND Name='Parent' 
                                                            AND Tier__c=:AccountLast12MonthsRollupService.TIER1
                                                            AND Last_12_Months_Contracted_Sales__c=0.00
                                                            AND Last_12_Months_Number_of_Jobs__c=0
                                                            AND Last_12_Months_Contracted_Sales_Children__c>=1400000.00
                                                            AND Last_12_Months_Number_of_Jobs_Children__c=59
                                                            AND Last_12_Months_Contracted_Sales_All__c>=1400000.00
                                                            AND Last_12_Months_Number_of_Jobs_All__c=59].size(),
                                    'Failed:  Expected Parent to be Tier 1');
            System.assertEquals(1, [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId()
                                                            AND Name='Child1' 
                                                            AND Tier__c=:AccountLast12MonthsRollupService.TIER2
                                                            AND Last_12_Months_Contracted_Sales__c=500000.00
                                                            AND Last_12_Months_Number_of_Jobs__c=10
                                                            AND Last_12_Months_Contracted_Sales_Children__c=0.00
                                                            AND Last_12_Months_Number_of_Jobs_Children__c=0
                                                            AND Last_12_Months_Contracted_Sales_All__c=500000.00
                                                            AND Last_12_Months_Number_of_Jobs_All__c=10].size(),
                                    'Failed:  Expected Child1 to be Tier 2');
            System.assertEquals(1, [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId()
                                                            AND Name='Child2' 
                                                            AND Tier__c=:AccountLast12MonthsRollupService.TIER2
                                                            AND Last_12_Months_Contracted_Sales__c=400000.00
                                                            AND Last_12_Months_Number_of_Jobs__c=25
                                                            AND Last_12_Months_Contracted_Sales_Children__c=0.00
                                                            AND Last_12_Months_Number_of_Jobs_Children__c=0
                                                            AND Last_12_Months_Contracted_Sales_All__c=400000.00
                                                            AND Last_12_Months_Number_of_Jobs_All__c=25].size(),
                                    'Failed:  Expected Child2 to be Tier 2');
            System.assertEquals(1, [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId()
                                                            AND Name='Child3' 
                                                            AND Tier__c=:AccountLast12MonthsRollupService.TIER2
                                                            AND Last_12_Months_Contracted_Sales__c>=50000.00
                                                            AND Last_12_Months_Number_of_Jobs__c=1
                                                            AND Last_12_Months_Contracted_Sales_Children__c>=450000.00
                                                            AND Last_12_Months_Number_of_Jobs_Children__c=23
                                                            AND Last_12_Months_Contracted_Sales_All__c>=500000.00
                                                            AND Last_12_Months_Number_of_Jobs_All__c=24].size(),
                                    'Failed:  Expected Child3 to be Tier 2');
            System.assertEquals(1, [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId()
                                                            AND Name='Child4' 
                                                            AND Tier__c=:AccountLast12MonthsRollupService.TIER3
                                                            AND Last_12_Months_Contracted_Sales__c>=450000.00
                                                            AND Last_12_Months_Number_of_Jobs__c=23
                                                            AND Last_12_Months_Contracted_Sales_Children__c=0.00
                                                            AND Last_12_Months_Number_of_Jobs_Children__c=0
                                                            AND Last_12_Months_Contracted_Sales_All__c>=450000.00
                                                            AND Last_12_Months_Number_of_Jobs_All__c=23].size(),
                                    'Failed:  Expected Child4 to be Tier 2');                                    
    }

    @isTest
    static void testOverrideTier(){
        Account parentAcc = (Account)TestFactory.createSObject(new Account(RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId(), Name='Parent'), 'TestFactoryDefaults.AccountDefaults', true);
        Account child1 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId(), Name='Child1'), 'TestFactoryDefaults.AccountDefaults', true);
            List<WorkOrder> child1JobLst = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=child1.Id, ROM_Contracted_Sales__c=50000,Status='AP Pending'), 10, 'TestFactoryDefaults.JobDefaults', true);
        Account child2 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId(), Name='Child2'), 'TestFactoryDefaults.AccountDefaults', true);
            List<WorkOrder> child2JobLst = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=child2.Id, ROM_Contracted_Sales__c=16000,Status='Closed'), 25, 'TestFactoryDefaults.JobDefaults', true);
        Account child3 = (Account)TestFactory.createSObject(new Account(ParentId=parentAcc.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId(), Name='Child3', Tier_Override__c=true, Tier__c=AccountLast12MonthsRollupService.TIER3), 'TestFactoryDefaults.AccountDefaults', true);
            List<WorkOrder> child3JobLst = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=child3.Id, ROM_Contracted_Sales__c=50000,Status='Work Complete'), 1, 'TestFactoryDefaults.JobDefaults', true);
        Account child4 = (Account)TestFactory.createSObject(new Account(ParentId=child3.Id, RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId(), Name='Child4'), 'TestFactoryDefaults.AccountDefaults', true);
            List<WorkOrder> child4JobLst = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=child4.Id, ROM_Contracted_Sales__c=19565.22,Status='Pre-production'), 23, 'TestFactoryDefaults.JobDefaults', true);
        
        for (WorkOrder job : [SELECT AccountId, Account.Name, Account.ParentId, Id, ROM_Contracted_Sales__c FROM WorkOrder ORDER BY AccountId]) {
            System.debug('~~~~ AccountLast12MonthsRollupServiceTest::testOverrideTier: job ' + job);
        }

        Test.startTest();
        AccountLast12MonthsRollupService.rollUpJobsOnAccounts([SELECT Id, Name, ParentId, Tier__c, Tier_Override__c, Last_Modified_Tier_By__c, Last_Date_Tier_Set__c FROM Account WHERE RecordType.DeveloperName In ('Parent', 'Account')]);
        Test.stopTest();

        for (Account acc : [SELECT Id, Name, Tier__c, Last_12_Months_Contracted_Sales__c, Last_12_Months_Number_of_Jobs__c, Last_12_Months_Contracted_Sales_Children__c, Last_12_Months_Number_of_Jobs_Children__c, Last_12_Months_Contracted_Sales_All__c, Last_12_Months_Number_of_Jobs_All__c FROM Account]) {
            System.debug('~~~~ AccountLast12MonthsRollupServiceTest::testOverrideTier: acc '+ acc);
        }     
        
        System.assertEquals(1, [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId()
                                                        AND Name='Parent' 
                                                        AND Tier__c=:AccountLast12MonthsRollupService.TIER1
                                                        AND Last_12_Months_Contracted_Sales__c=0.00
                                                        AND Last_12_Months_Number_of_Jobs__c=0
                                                        AND Last_12_Months_Contracted_Sales_Children__c>=1400000.00
                                                        AND Last_12_Months_Number_of_Jobs_Children__c=59
                                                        AND Last_12_Months_Contracted_Sales_All__c>=1400000.00
                                                        AND Last_12_Months_Number_of_Jobs_All__c=59].size(),
                                'Failed:  Expected Parent to be Tier 1');
        System.assertEquals(1, [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId()
                                                        AND Name='Child1' 
                                                        AND Tier__c=:AccountLast12MonthsRollupService.TIER2
                                                        AND Last_12_Months_Contracted_Sales__c=500000
                                                        AND Last_12_Months_Number_of_Jobs__c=10
                                                        AND Last_12_Months_Contracted_Sales_Children__c=0
                                                        AND Last_12_Months_Number_of_Jobs_Children__c=0
                                                        AND Last_12_Months_Contracted_Sales_All__c=500000
                                                        AND Last_12_Months_Number_of_Jobs_All__c=10].size(),
                                'Failed:  Expected Child1 to be Tier 2');
        System.assertEquals(1, [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId()
                                                        AND Name='Child2' 
                                                        AND Tier__c=:AccountLast12MonthsRollupService.TIER2
                                                        AND Last_12_Months_Contracted_Sales__c=400000
                                                        AND Last_12_Months_Number_of_Jobs__c=25
                                                        AND Last_12_Months_Contracted_Sales_Children__c=0
                                                        AND Last_12_Months_Number_of_Jobs_Children__c=0
                                                        AND Last_12_Months_Contracted_Sales_All__c=400000
                                                        AND Last_12_Months_Number_of_Jobs_All__c=25].size(),
                                'Failed:  Expected Child2 to be Tier 2');
        System.assertEquals(1, [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId()
                                                        AND Name='Child3' 
                                                        AND Tier__c=:AccountLast12MonthsRollupService.TIER3
                                                        AND Calculated_Tier__c=:AccountLast12MonthsRollupService.TIER2
                                                        AND Last_12_Months_Contracted_Sales__c=50000
                                                        AND Last_12_Months_Number_of_Jobs__c=1
                                                        AND Last_12_Months_Contracted_Sales_Children__c>=450000
                                                        AND Last_12_Months_Number_of_Jobs_Children__c=23
                                                        AND Last_12_Months_Contracted_Sales_All__c>=500000
                                                        AND Last_12_Months_Number_of_Jobs_All__c=24].size(),
                                'Failed:  Expected Child3 to be Tier 2');
        System.assertEquals(1, [SELECT Id FROM Account WHERE RecordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId()
                                                        AND Name='Child4' 
                                                        AND Tier__c=:AccountLast12MonthsRollupService.TIER3
                                                        AND Last_12_Months_Contracted_Sales__c>=450000
                                                        AND Last_12_Months_Number_of_Jobs__c=23
                                                        AND Last_12_Months_Contracted_Sales_Children__c=0
                                                        AND Last_12_Months_Number_of_Jobs_Children__c=0
                                                        AND Last_12_Months_Contracted_Sales_All__c>=450000
                                                        AND Last_12_Months_Number_of_Jobs_All__c=23].size(),
                                'Failed:  Expected Child4 to be Tier 2');          
    }

    @isTest
    static void testTierCalculation() {
        //Tier1
        System.assertEquals(AccountLast12MonthsRollupService.TIER1, AccountLast12MonthsRollupService.calculateTier(1, AccountLast12MonthsRollupService.TIER_1_CONTRACT_AMOUNT_MIN), 'Expected Tier 1 based on contract amount');
        System.assertEquals(AccountLast12MonthsRollupService.TIER1, AccountLast12MonthsRollupService.calculateTier(AccountLast12MonthsRollupService.TIER_1_JOB_COUNT_MIN, 0), 'Expected Tier 1 based on number of jobs');
        System.assertEquals(AccountLast12MonthsRollupService.TIER1, AccountLast12MonthsRollupService.calculateTier(AccountLast12MonthsRollupService.TIER_1_JOB_COUNT_MIN, AccountLast12MonthsRollupService.TIER_1_CONTRACT_AMOUNT_MIN), 'Expected Tier 1 based on contract amount AND number of jobs');
        
        //Tier2   
        System.assertEquals(AccountLast12MonthsRollupService.TIER2, AccountLast12MonthsRollupService.calculateTier(1, AccountLast12MonthsRollupService.TIER_2_CONTRACT_AMOUNT_MIN), 'Expected Tier 2 based on contract amount');
        System.assertEquals(AccountLast12MonthsRollupService.TIER2, AccountLast12MonthsRollupService.calculateTier(AccountLast12MonthsRollupService.TIER_2_JOB_COUNT_MIN, 0), 'Expected Tier 2 based on number of jobs');
        System.assertEquals(AccountLast12MonthsRollupService.TIER2, AccountLast12MonthsRollupService.calculateTier(AccountLast12MonthsRollupService.TIER_2_JOB_COUNT_MIN, AccountLast12MonthsRollupService.TIER_2_CONTRACT_AMOUNT_MIN), 'Expected Tier 2 based on contract amount AND number of jobs');

        //Tier3   
        System.assertEquals(AccountLast12MonthsRollupService.TIER3, AccountLast12MonthsRollupService.calculateTier(1, AccountLast12MonthsRollupService.TIER_3_CONTRACT_AMOUNT_MIN), 'Expected Tier 3 based on contract amount');
        System.assertEquals(AccountLast12MonthsRollupService.TIER3, AccountLast12MonthsRollupService.calculateTier(AccountLast12MonthsRollupService.TIER_3_JOB_COUNT_MIN, 0), 'Expected Tier 3 based on number of jobs');
        System.assertEquals(AccountLast12MonthsRollupService.TIER3, AccountLast12MonthsRollupService.calculateTier(AccountLast12MonthsRollupService.TIER_3_JOB_COUNT_MIN, AccountLast12MonthsRollupService.TIER_3_CONTRACT_AMOUNT_MIN), 'Expected Tier 3 based on contract amount AND number of jobs');

        //Tier4   
        System.assertEquals(AccountLast12MonthsRollupService.TIER4, AccountLast12MonthsRollupService.calculateTier(1, (AccountLast12MonthsRollupService.TIER_3_CONTRACT_AMOUNT_MIN - 0.01)), 'Expected Tier 4 based on contract amount');
        System.assertEquals(AccountLast12MonthsRollupService.TIER4, AccountLast12MonthsRollupService.calculateTier(AccountLast12MonthsRollupService.TIER_3_JOB_COUNT_MIN-1, 0), 'Expected Tier 4 based on number of jobs');
        System.assertEquals(AccountLast12MonthsRollupService.TIER4, AccountLast12MonthsRollupService.calculateTier((AccountLast12MonthsRollupService.TIER_3_JOB_COUNT_MIN-1), AccountLast12MonthsRollupService.TIER_3_CONTRACT_AMOUNT_MIN-.01), 'Expected Tier 2 based on contract amount AND number of jobs');
    }
}