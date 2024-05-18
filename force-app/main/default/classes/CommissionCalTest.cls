/**
 * @description       : This test class test all the record triggered flows associated with automatically creating,
 *                      updated and calculating job commissions and employee commissions
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-09-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public with sharing class CommissionCalTest {
    @TestSetup
    private static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=false;
        dataAdmin.TurnOffProcessBuilder__c=false;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.TurnOffFlow__c=false;
        if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
            dataAdmin.SetupOwnerId = UserInfo.getUserId();
            insert dataAdmin;
        }
        else {
            update dataAdmin;
        }

        Map<String, ServiceTerritory> serviceTerritoryByNameMap = TestFactory.createServiceTerritories();
        Test.startTest();
        List<User> commissionableSalesUserLst = CommissionCalTestUtility.getSalesCommissionableUsers();
        Test.stopTest();
        
        User boltUser = [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];
        
        if (BOLT__c.getInstance(boltUser.Id) == null) {
            BOLT__c bolt = new BOLT__c(SetupOwnerId=boltUser.Id, Is_Bolt_Integration_User__c=true);
            insert bolt;
        } 

        if (DataAdmin__c.getInstance(boltUser.Id) == null ) {
            DataAdmin__c dataAdmin2 = new DataAdmin__c();
            dataAdmin2.TurnOffTrigger__c=false;
            dataAdmin2.TurnOffWorkflow__c=false;
            dataAdmin2.TurnOffProcessBuilder__c=false;
            dataAdmin2.TurnOffValidationRules__c=true;
            dataAdmin2.TurnOffFlow__c=false;
            insert dataAdmin2;
        }
    }

    /*** Multiplier and tier test, these groups of test verify the multiplier on the job commission is correct when the job commission is created
     *   based on the number of BD KTMs on the job where Sales_Commissionable_User__c=true, selected tier is correct and all calculations are correct
     *   all of these scenarios are happy path scenarios - qualifies for Deposit/First Payment, Quick Collection and is commissionable
     */
    //test tier 1 with 3 BD/ECs
    @isTest
    private static void test3EcMultiplierTier1() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job = CommissionCalTestUtility.createCommissionableJobByNumberOfBDsAndJobMargin(3, Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_1).Minimum_Margin_for_Tier__c + 1);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(3, jobCom.Employee_Commissions__r.size(), 'Failed:  expected 3 employee commission records');
        Assert.areEqual(SalesIncentivePlanConstants.TIER_1, jobCom.Margin_Tier__c, 'Failed:  expected tier 1 margin');
        Assert.areEqual(1662.50, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(554.17, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    //test tier 2 with 2 BD/ECs
    @isTest
    private static void test2EcMultiplierTier2(){
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job = CommissionCalTestUtility.createCommissionableJobByNumberOfBDsAndJobMargin(2, Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_2).Minimum_Margin_for_Tier__c + 1);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(2, jobCom.Employee_Commissions__r.size(), 'Failed:  expected 2 employee commission records');
        Assert.areEqual(SalesIncentivePlanConstants.TIER_2, jobCom.Margin_Tier__c, 'Failed:  expected tier 2 margin');
        Assert.areEqual(1200, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(600, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    //test tier 3 with 1 BD/EC
    @isTest
    private static void test1EcMultiplierTier3(){
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job = CommissionCalTestUtility.createCommissionableJobByNumberOfBDsAndJobMargin(1, Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_3).Minimum_Margin_for_Tier__c + 1);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(1, jobCom.Employee_Commissions__r.size(), 'Failed:  expected 1 employee commission records');
        Assert.areEqual(SalesIncentivePlanConstants.TIER_3, jobCom.Margin_Tier__c, 'Failed:  expected tier 3 margin');
        Assert.areEqual(750, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(750, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    //test tier 4 with 1 BD/EC
    @isTest
    private static void test1EcMultiplierTier4(){
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job = CommissionCalTestUtility.createCommissionableJobByNumberOfBDsAndJobMargin(1, Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_4).Maximum_Margin_for_Tier__c - 1);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(1, jobCom.Employee_Commissions__r.size(), 'Failed:  expected 1 employee commission records');
        Assert.areEqual(SalesIncentivePlanConstants.TIER_4, jobCom.Margin_Tier__c, 'Failed:  expected tier 4 margin');
        Assert.areEqual(0, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(0, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    /**** Deposit/First Payment non-qualification */
    //doesn't qualify because there is no  date of first payment nor is there a first payment amount
    @isTest 
    private static void testMissingDepositFirstPaymentDateAndAmount() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job = CommissionCalTestUtility.createDepositFirstPaymentVariantJob(Date.today(), null, null);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_DepositFirst_Payment_Met__c, 'Failed:  expected default deposit first payment met = no');
        Assert.areEqual(1330, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(443.33, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');      
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    //Doesn't qualify because date of first payment received more than 65 days after start date
    @isTest 
    private static void testNotQualifiedgDepositFirstPaymentDateAndAmount() {
        Integer daysToAdd = (Integer)(Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_1).Deposit1st_Payment_Incentive_Threshold__c+1);
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job = CommissionCalTestUtility.createDepositFirstPaymentVariantJob(Date.today(), Date.today().addDays(daysToAdd), 1000);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(1330, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(443.33, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_DepositFirst_Payment_Met__c, 'Failed:  expected default deposit first payment met = no');
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    /**** Total collection - verify slow collection criteria, and verify a sub set of scenarios where none of the total collection criteria was met by default***/
    //Verify Slow Collection works as expected when date fully collected > 120 days
    @isTest 
    private static void testSlowCollection() {
        Integer daysToAdd = (Integer)(Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_1).Collection_Incentive_Threshold__c + 1);
        
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job = CommissionCalTestUtility.createTotalCollectionVariantJob(Date.today(), Date.today().addDays(daysToAdd));
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_Quick_Collection_Met__c, 'Failed:  expected quick collection met to be no');
        Assert.areEqual(SalesIncentivePlanConstants.YES, jobCom.Default_Slow_Collection_Met__c, 'Failed: expected default collection met to be no');
        Assert.areEqual(997.50, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(332.50, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }
    
    //Verify Doesn't qualify for Quick or Slow Collection due to missing date fully collected
    @isTest 
    private static void testNotQualifiedForTotalCollectionMissingDateFullyCollected() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job = CommissionCalTestUtility.createTotalCollectionVariantJob(Date.today(), null);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_Quick_Collection_Met__c, 'Failed:  expected default quick collection met to be no');
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_Slow_Collection_Met__c, 'Failed: expected default slow collection met to be no');
        Assert.areEqual(332.50, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(110.83, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    //Verify Doesn't qualify for Quick or Slow Collection due to missing work complete date and date fully collected
    @isTest 
    private static void testNotQualifiedForTotalCollectionMissingAllDates() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job = CommissionCalTestUtility.createTotalCollectionVariantJob(null, null);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_Quick_Collection_Met__c, 'Failed:  expected default quick collection met to be no');
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_Slow_Collection_Met__c, 'Failed: expected default slow collection met to be no');
        Assert.areEqual(332.50, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(110.83, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');        
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    /**** Non-Commissionable Scenarios - this verify the job isn't commissionable by default if 
     *    Job In Legal = YES OR
     *    Job IN Collections = YES OR
     *    Bad Debt > 0 OR
     *    House Account = true
     */
    //Verify the job isn't commissionable because the job is in legal
    @isTest 
    private static void testNotCommissionableInLegal() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job =  CommissionCalTestUtility.createNonCommissionableVariantJob(true, false, false, null);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_Commissionable__c, 'Failed:  should not be commissionable by default');
        Assert.areEqual(0, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(0, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    //Verify the job isn't commissionable because the job is in collections
    @isTest 
    private static void testNotCommissionableInCollections() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job =  CommissionCalTestUtility.createNonCommissionableVariantJob(false, true, false, null);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_Commissionable__c, 'Failed:  should not be commissionable by default');
        Assert.areEqual(0, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(0, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');        
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    //Verify the job isn't commissionable because the job is a House Account job
    @isTest 
    private static void testNotCommissionableHouseAccount() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job =  CommissionCalTestUtility.createNonCommissionableVariantJob(false, false, true, null);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_Commissionable__c, 'Failed:  should not be commissionable by default');
        Assert.areEqual(0, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(0, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');       
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    //Verify the job isn't commissionable because the job has bad debt
    @isTest 
    private static void testNotCommissionableHasBadDebt() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            Test.startTest();
            WorkOrder job =  CommissionCalTestUtility.createNonCommissionableVariantJob(false, false, false, 1000);
            Test.stopTest();
        }

        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_Commissionable__c, 'Failed:  should not be commissionable by default');
        Assert.areEqual(0, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(0, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');       
        CommissionCalTestUtility.assertCommissionAllAutoMatches();
    }

    /****  Verify Finanical Field Updates */
    @isTest
    private static void  testFinanicalFieldUpdates() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            WorkOrder job = CommissionCalTestUtility.createCommissionableJobByNumberOfBDsAndJobMargin(1, Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_3).Minimum_Margin_for_Tier__c + 1);
            job.Start_Date__c = Date.today().addDays(1);
            job.Date_of_First_Payment__c=null;
            job.Work_Complete_Date__c = null;
            job.Date_Fully_Collected__c = null;
            job.ROM_Contracted_Sales__c = 50000;
            job.First_Payment_Amount__c = 0;
            job.Expected_Margin__c = Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_2).Minimum_Margin_for_Tier__c + 1;

            Test.startTest();
            update job;
            Test.stopTest();

            Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
            Assert.areEqual(job.Start_Date__c, jobCom.Job_Start_Date__c, 'Failed:  no match on start date');
            Assert.areEqual(job.Date_of_First_Payment__c, jobCom.Job_Date_of_DepositFirst_Payment__c, 'Failed: no match on deposit first payment date');
            Assert.areEqual(job.Work_Complete_Date__c, jobCom.Job_Work_Complete_Date__c, 'Failed: no match on work complete date');
            Assert.areEqual(job.Date_Fully_Collected__c, jobCom.Job_Date_Fully_Collected__c, 'Failed: no match on date fully collected');
            Assert.areEqual(job.ROM_Contracted_Sales__c, jobCom.Job_Amount__c, 'Failed: no match on Job Amount');
            Assert.areEqual(job.First_Payment_Amount__c, jobCom.Job_DepositFirst_Payment_Amount__c, 'Failed: no match on Job Deposit First Payment Amount');
            Assert.areEqual(job.Expected_Margin__c, jobCom.Job_Margin__c, 'Failed:  no match on job margin');
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
        }
    }

    //verify test updating job finanicals to not be commissionable
    @isTest 
    private static void testNonCommissionableFieldUpdates() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            WorkOrder job = CommissionCalTestUtility.createCommissionableJobByNumberOfBDsAndJobMargin(1, Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_2).Minimum_Margin_for_Tier__c + 1);
            job.Legal__c = true;
            job.In_Collections__c = true;
            job.Bad_Debt__c = 10000;
            job.House_Account__c = true;

            Test.startTest();
            update job;
            Test.stopTest();

            Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
            ASsert.areEqual(CommissionCalTestUtility.convertCheckboxToYesNo(job.Legal__c), jobCom.Job_In_Legal__c, 'Failed:  job in legal not matched');
            Assert.areEqual(CommissionCalTestUtility.convertCheckboxToYesNo(job.In_Collections__c), jobCom.Job_In_Collections__c, 'Failed: job in collections not matched');
            Assert.areEqual(job.Bad_Debt__c, jobCom.Job_Bad_Debt__c, 'Failed:  job bad debt not matched');
            Assert.areEqual(CommissionCalTestUtility.convertCheckboxToYesNo(job.House_Account__c), jobCom.House_Account__c, 'Failed:  House account not matched');
            Assert.areEqual(SalesIncentivePlanConstants.NO, jobCom.Default_Commissionable__c, 'Failed:  should not be commissionable by default');
            Assert.areEqual(jobCom.Default_Commissionable__c, jobCom.Actual_Commissionable__c, 'Failed:  actual and default commissionable should be the same');
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
        }            
    }
    
    //verify the job margin on a commission reflects the final job margin if the job status is closed
    @isTest 
    private static void testCommissionableJobClosedUseFinalMargin() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            WorkOrder job = CommissionCalTestUtility.createCommissionableJobByNumberOfBDsAndJobMargin(2, Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_2).Minimum_Margin_for_Tier__c + 1);
            job.Status='Closed';
            job.Final_Margin__c = Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_1).Minimum_Margin_for_Tier__c + 1;

            Test.startTest();
            update job;
            Test.stopTest();

            Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
            Assert.areEqual(job.Final_Margin__c, jobCom.Job_Margin__c, 'Failed:  Job margin not matched');
            Assert.areEqual(SalesIncentivePlanConstants.TIER_1, jobCom.Margin_Tier__c, 'Failed: no match on job tier');
            Assert.areEqual(job.Status, jobCom.Job_Status__c, 'Failed: job status not matched');
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
        }
    }

    //verify Paid EC's aren't updated STAR-6372
    @isTest
    private static void testPaidEc() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            
            WorkOrder job = CommissionCalTestUtility.createCommissionableJobByNumberOfBDsAndJobMargin(2, Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_2).Minimum_Margin_for_Tier__c + 1);
            
        }

        Job_Commission__c jobComBefore = CommissionCalTestUtility.getJobComAndRelatedRecs();
        
        //update recs for test
        Test.startTest();
        Employee_Commission__c finalizedEC = new Employee_Commission__c(Id=jobComBefore.Employee_Commissions__r[1].Id, Status__c=SalesIncentivePlanConstants.EC_STATUS_PAID);
        update finalizedEC;
        Test.stopTest();

        WorkOrder jobUpdate = new WorkOrder(Id=jobComBefore.Job__c, ROM_Contracted_Sales__c=120000);
        update jobUpdate;


        Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
        Assert.areEqual(2, jobCom.Employee_Commissions__r.size(), 'Failed:  expected 2 employee commission records');
        Assert.areEqual(SalesIncentivePlanConstants.TIER_2, jobCom.Margin_Tier__c, 'Failed:  expected tier 2 margin');
        Assert.areEqual(1440, jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
        Assert.areEqual(720, jobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Open EC Actual Total Payment on EC not matched');
        Assert.areEqual(600, jobCom.Employee_Commissions__r[1].Actual_Commission_Amount__c, 'Failed: Paid EC Actual Total Payment on EC not matched');
    }

    /**** simulate exceptions to verify calculation differences between default and actual commission values 
     * this only test a subset of scenarios
    */
    //verify  deposit first payment  exception calculated correctly
    @isTest
    private static void testExceptionDepositFirstPayment() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            WorkOrder job = CommissionCalTestUtility.createDepositFirstPaymentVariantJob(Date.today(), null, 1000);
            
            Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
            
            //simulate making actual deposit/first payment met = true as an exception
            //call sub flow JobCommissionCal_Subflow_SetActualDepositFirstPaymentParameters to do this
            Map<String, Object> inputValueByVarName = new Map<String, Object>();
            inputValueByVarName.put('varN_Deposit1stPayIncentivePercent', jobCom.Deposit_First_Payment_Incentive__c);
            inputValueByVarName.put('varP_ActualDeposit1stPaymentMet', SalesIncentivePlanConstants.YES);

            Flow.Interview.JobCommissionCal_Subflow_SetActualDepositFirstPaymentParameters actualDepositFirstPaymentMetFlow = new Flow.Interview.JobCommissionCal_Subflow_SetActualDepositFirstPaymentParameters(inputValueByVarName);
            actualDepositFirstPaymentMetFlow.start();
            
            Job_Commission__c copyJobCom = jobCom.clone(true);
            copyJobCom.Actual_DepositFirst_Payment_Met__c = SalesIncentivePlanConstants.YES;
            copyJobCom.Actual_Deposit_1st_Payment_Incentive__c = actualDepositFirstPaymentMetFlow.varN_ActualDeposit1stPayIncentivePer;
            copyJobCom.Exception_DepositFirst_Payment__c = actualDepositFirstPaymentMetFlow.varP_ExceptionDepositFirstPayment;
            
            //call flow to update job commission calculations
            inputValueByVarName.clear();
            inputValueByVarName.put('varR_JobCommission', copyJobCom);
            Flow.Interview.JobCommissionCal_Subflow_CalculateJobCommission calJobCom = new Flow.Interview.JobCommissionCal_Subflow_CalculateJobCommission(inputValueByVarName);
            calJobCom.start();
            copyJobCom=calJobCom.varR_JobCommission;
            
            //run test
            Test.startTest();
            update copyJobCom;
            Test.stopTest();

            Job_Commission__c exceptionJobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();

            Assert.areEqual(SalesIncentivePlanConstants.YES, exceptionJobCom.Actual_DepositFirst_Payment_Met__c, 'Failed: expected actual deposit first payment met to be YES');
            Assert.areEqual(exceptionJobCom.Deposit_First_Payment_Incentive__c, exceptionJobCom.Actual_Deposit_1st_Payment_Incentive__c, 'Failed: actual deposit first payment incentive not matched');
            Assert.areEqual(SalesIncentivePlanConstants.YES, exceptionJobCom.Exception_DepositFirst_Payment__c, 'Failed:  exception for deposit first payment incentive should be yes');
            Assert.areNotEqual(exceptionJobCom.Default_DepositFirst_Payment_Met__c, exceptionJobCom.Actual_DepositFirst_Payment_Met__c, 'Failed: expected the deposit first payment met for default and actuals to be different');
            Assert.areNotEqual(exceptionJobCom.Default_DepositFirst_Payment_Amount__c , exceptionJobCom.Actual_DepositFirst_Payment_Amount__c, 'Failed:  expected actual and default deposit amounts to be different');
            Assert.areNotEqual(exceptionJobCom.Default_Total_Payment_Amount__c, exceptionJobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed: expected the default and actual commission amounts to be different');
            Assert.areEqual(1662.50, exceptionJobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
            Assert.areEqual(554.17, exceptionJobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
            Assert.areEqual(1330.00, exceptionJobCom.Default_Total_Payment_Amount__c, 'Failed:  Default Total Payment on Job Commission not matched');
            Assert.areEqual(443.33, exceptionJobCom.Employee_Commissions__r[0].Default_Commission_Amount__c, 'Failed: Default Total Payment on EC not matched');
    
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
        }
    }

    //Verify  slow collection exception calculated correctly
    @isTest
    private static void testExceptionSlowCollection() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            WorkOrder job = CommissionCalTestUtility.createTotalCollectionVariantJob(null, null);
            
            Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
            
            //simulate making actual slow collection met = true as an exception
            Map<String, Object> inputValueByVarName = new Map<String, Object>();
            inputValueByVarName.put('varP_ThisActualMet', SalesIncentivePlanConstants.YES);
            inputValueByVarName.put('varP_ThatActualMet', jobCom.Actual_Quick_Collection_Met__c);
            inputValueByVarName.put('varN_ThisIncentivePercentage', jobCom.Slow_Collection_Incentive__c);
            inputValueByVarName.put('varP_ThisDefaultMet', jobCom.Default_Slow_Collection_Met__c);
            inputValueByVarName.put('varP_ThatDefaultMet', jobCom.Default_Quick_Collection_Met__c);

            Flow.Interview.JobCommissionCal_Subflow_SetActualTotalCollectionParameters actualactualTotalCollectionFlow = new Flow.Interview.JobCommissionCal_Subflow_SetActualTotalCollectionParameters(inputValueByVarName);
            actualactualTotalCollectionFlow.start();
            
            Job_Commission__c updateJobCom = jobCom.clone(true);
            updateJobCom.Actual_Slow_Collection_Met__c = SalesIncentivePlanConstants.YES;
            updateJobCom.Actual_Quick_Collection_Met__c = actualactualTotalCollectionFlow.varP_ThatActualMet;
            updateJobCom.Actual_Slow_Collection_Incentive__c = actualactualTotalCollectionFlow.varN_ThisActualIncentivePercentage;
            updateJobCom.Actual_Quick_Collection_Incentive__c = actualactualTotalCollectionFlow.varN_ThatActualIncentivePercentage;
            updateJobCom.Exception_Slow_Collection__c = actualactualTotalCollectionFlow.varP_ThisException;
            updateJobCom.Exception_Quick_Collection__c = actualactualTotalCollectionFlow.varP_ThatException;
            

            //call flow to update job commission calculations
            inputValueByVarName.clear();
            inputValueByVarName.put('varR_JobCommission', updateJobCom);
            Flow.Interview.JobCommissionCal_Subflow_CalculateJobCommission calJobCom = new Flow.Interview.JobCommissionCal_Subflow_CalculateJobCommission(inputValueByVarName);
            calJobCom.start();
            updateJobCom=calJobCom.varR_JobCommission;
                        
            Test.startTest();
            update updateJobCom;
            Test.stopTest();
            
            Job_Commission__c exceptionJobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();


            Assert.areEqual(SalesIncentivePlanConstants.NO, exceptionJobCom.Default_Quick_Collection_Met__c, 'Failed: Default quick collection met is expected to be NO');
            Assert.areEqual(SalesIncentivePlanConstants.NO, exceptionJobCom.Default_Slow_Collection_Met__c, 'Failed: Default slow collection met is expected to be NO');
            Assert.areEqual(SalesIncentivePlanConstants.YES, exceptionJobCom.Actual_Slow_Collection_Met__c, 'Failed: expected actual slow collection met to be YES');
            Assert.areEqual(SalesIncentivePlanConstants.NO, exceptionJobCom.Actual_Quick_Collection_Met__c, 'Failed: actual quick collection met is expected to be NO');
            Assert.areEqual(SalesIncentivePlanConstants.YES, exceptionJobCom.Exception_Slow_Collection__c, 'Failed:  exception for slow collection should be yes');
            Assert.areEqual(SalesIncentivePlanConstants.NO, exceptionJobCom.Exception_Quick_Collection__c, 'Failed:  exception for quick collection should be yes');
            Assert.areNotEqual(exceptionJobCom.Actual_Total_Commission_Payment_Amount__c, exceptionJobCom.Default_Total_Collection_Payment_Amount__c, 'Failed: expected the total commission payment default and actuals to be different');
            Assert.areNotEqual(exceptionJobCom.Default_Slow_Collection_Payment_Amount__c , exceptionJobCom.Actual_Slow_Collection_Payment_Amount__c, 'Failed:  expected actual and default slow collection amounts to be different');
            Assert.areEqual(exceptionJobCom.Default_Quick_Collection_Payment_Amount__c, exceptionJobCom.Actual_Quick_Collection_Payment_Amount__c, 'Failed: expected the default and actual quick collection commission amounts to be the same');
            Assert.areEqual(997.50, exceptionJobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
            Assert.areEqual(332.50, exceptionJobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
            Assert.areEqual(332.5, exceptionJobCom.Default_Total_Payment_Amount__c, 'Failed:  Default Total Payment on Job Commission not matched');
            Assert.areEqual(110.83, exceptionJobCom.Employee_Commissions__r[0].Default_Commission_Amount__c, 'Failed: Default Total Payment on EC not matched');
    
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
        }
    }

    //Verify  quick collection exception calculated correctly
    @isTest
    private static void testExceptionQuickCollection() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            //create slow collection job by default
            WorkOrder job = CommissionCalTestUtility.createTotalCollectionVariantJob(
                Date.today(), 
                Date.today().addDays(
                    Integer.valueOf(
                        Job_Commission_Configuration__mdt.getInstance(SalesIncentivePlanConstants.TIER_1).Collection_Incentive_Threshold__c + 1
                    )
                )
            );
            
            Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
            
            //simulate making actual slow collection met = true as an exception
            Map<String, Object> inputValueByVarName = new Map<String, Object>();
            inputValueByVarName.put('varP_ThisActualMet', SalesIncentivePlanConstants.YES);
            inputValueByVarName.put('varP_ThatActualMet', jobCom.Actual_Slow_Collection_Met__c);
            inputValueByVarName.put('varN_ThisIncentivePercentage', jobCom.Quick_Collection_Incentive__c);
            inputValueByVarName.put('varP_ThisDefaultMet', jobCom.Default_Quick_Collection_Met__c);
            inputValueByVarName.put('varP_ThatDefaultMet', jobCom.Default_Slow_Collection_Met__c);

            Flow.Interview.JobCommissionCal_Subflow_SetActualTotalCollectionParameters actualTotalCollectionFlow = new Flow.Interview.JobCommissionCal_Subflow_SetActualTotalCollectionParameters(inputValueByVarName);
            actualTotalCollectionFlow.start();
            
            Job_Commission__c updateJobCom = jobCom.clone(true);
            updateJobCom.Actual_Quick_Collection_Met__c = SalesIncentivePlanConstants.YES;
            updateJobCom.Actual_Slow_Collection_Met__c = actualTotalCollectionFlow.varP_ThatActualMet;
            updateJobCom.Actual_Quick_Collection_Incentive__c = actualTotalCollectionFlow.varN_ThisActualIncentivePercentage;
            updateJobCom.Actual_Slow_Collection_Incentive__c = actualTotalCollectionFlow.varN_ThatActualIncentivePercentage;
            updateJobCom.Exception_Quick_Collection__c = actualTotalCollectionFlow.varP_ThisException;
            updateJobCom.Exception_Slow_Collection__c = actualTotalCollectionFlow.varP_ThatException;
            

            //call flow to update job commission calculations
            inputValueByVarName.clear();
            inputValueByVarName.put('varR_JobCommission', updateJobCom);
            Flow.Interview.JobCommissionCal_Subflow_CalculateJobCommission calJobCom = new Flow.Interview.JobCommissionCal_Subflow_CalculateJobCommission(inputValueByVarName);
            calJobCom.start();
            updateJobCom=calJobCom.varR_JobCommission;
                        
            Test.startTest();
            update updateJobCom;
            Test.stopTest();
            
            Job_Commission__c exceptionJobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();


            Assert.areEqual(SalesIncentivePlanConstants.YES, exceptionJobCom.Default_Slow_Collection_Met__c, 'Failed: Default slow collection met is expected to be YES');
            Assert.areEqual(SalesIncentivePlanConstants.NO, exceptionJobCom.Default_Quick_Collection_Met__c, 'Failed: Default quick collection met is expected to be NO');
            Assert.areEqual(SalesIncentivePlanConstants.YES, exceptionJobCom.Actual_Quick_Collection_Met__c, 'Failed: expected actual quick collection met to be YES');
            Assert.areEqual(SalesIncentivePlanConstants.NO, exceptionJobCom.Actual_Slow_Collection_Met__c, 'Failed: actual slow collection met is expected to be NO');
            Assert.areEqual(SalesIncentivePlanConstants.YES, exceptionJobCom.Exception_Quick_Collection__c, 'Failed:  exception for quick collection should be yes');
            Assert.areEqual(SalesIncentivePlanConstants.YES, exceptionJobCom.Exception_Slow_Collection__c, 'Failed:  exception for slow collection should be yes');
            Assert.areNotEqual(exceptionJobCom.Actual_Total_Commission_Payment_Amount__c, exceptionJobCom.Default_Total_Collection_Payment_Amount__c, 'Failed: expected the total commission payment default and actuals to be different');
            Assert.areNotEqual(exceptionJobCom.Default_Quick_Collection_Payment_Amount__c , exceptionJobCom.Actual_Quick_Collection_Payment_Amount__c, 'Failed:  expected actual and default quick collection amounts to be different');
            Assert.areNotEqual(exceptionJobCom.Default_Slow_Collection_Payment_Amount__c, exceptionJobCom.Actual_Slow_Collection_Payment_Amount__c, 'Failed: expected the default and actual slow collection commission amounts to be the same');
            Assert.areEqual(1662.50, exceptionJobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
            Assert.areEqual(554.17, exceptionJobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
            Assert.areEqual(997.50, exceptionJobCom.Default_Total_Payment_Amount__c, 'Failed:  Default Total Payment on Job Commission not matched');
            Assert.areEqual(332.50, exceptionJobCom.Employee_Commissions__r[0].Default_Commission_Amount__c, 'Failed: Default Total Payment on EC not matched');
    
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
        }
    }


    //Verify commissionable exception calculated correctly
    @isTest
    private static void testExceptionCommissionable() {
        User boltSync =  [SELECT Id FROM User WHERE Alias='Boltx' LIMIT 1];

        System.runAs(boltSync) {
            WorkOrder job =  CommissionCalTestUtility.createNonCommissionableVariantJob(true, false, false, null);
            
            Job_Commission__c jobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();
            
            //simulate making actual commissionable met = true as an exception
            Job_Commission__c updateJobCom = jobCom.clone(true);
            updateJobCom.Actual_Commissionable__c = SalesIncentivePlanConstants.YES;
            updateJobCom.Exception_Commissionable__c=SalesIncentivePlanConstants.YES;
            Map<String, Object> inputValueByVarName = new Map<String, Object>();
            //Can't use sublfow... get a Salesforce Internal Error probably because the input variables are picklist and apex passes picklist as text
            /*inputValueByVarName.put('varP_isActualMet', updateJobCom.Actual_Commissionable__c);
            inputValueByVarName.put('varP_isDefaultlMet', updateJobCom.Default_Commissionable__c);
            for (String key : inputValueByVarName.keySet()) {
                System.debug('~~~~ CommissionCalTest::testExceptionCommissionable - inputValueByVarName - ' + key + ', ' + (String)inputValueByVarName.get(key));
            }

            Flow.Interview.JobCommissionCal_SubFlow_DetermineException commissionableException = new Flow.Interview.JobCommissionCal_SubFlow_DetermineException(inputValueByVarName);
            commissionableException.start();

            updateJobCom.Exception_Commissionable__c = commissionableException.varP_isException;
            */

            //call flow to update job commission calculations
            inputValueByVarName.clear();
            inputValueByVarName.put('varR_JobCommission', updateJobCom);
            Flow.Interview.JobCommissionCal_Subflow_CalculateJobCommission calJobCom = new Flow.Interview.JobCommissionCal_Subflow_CalculateJobCommission(inputValueByVarName);
            calJobCom.start();
            updateJobCom=calJobCom.varR_JobCommission;
                        
            Test.startTest();
            update updateJobCom;
            Test.stopTest();
            
            Job_Commission__c exceptionJobCom = CommissionCalTestUtility.getJobComAndRelatedRecs();

            Assert.areEqual(SalesIncentivePlanConstants.YES, exceptionJobCom.Actual_Commissionable__c, 'Failed: expected actual commissionable met to be YES');
            Assert.areEqual(SalesIncentivePlanConstants.NO, exceptionJobCom.Default_Commissionable__c, 'Failed: expected default commissionable met to be NO');
            Assert.areEqual(SalesIncentivePlanConstants.YES, exceptionJobCom.Exception_Commissionable__c, 'Failed:  exception for commissionable should be yes');
            Assert.areNotEqual(exceptionJobCom.Actual_Total_Commission_Payment_Amount__c, exceptionJobCom.Default_Total_Collection_Payment_Amount__c, 'Failed: expected the total commission payment default and actuals to be different');
            Assert.areEqual(1662.50, exceptionJobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed:  Actual Total Payment on Job Commission not matched');
            Assert.areEqual(554.17, exceptionJobCom.Employee_Commissions__r[0].Actual_Commission_Amount__c, 'Failed: Actual Total Payment on EC not matched');
            Assert.areEqual(0, exceptionJobCom.Default_Total_Payment_Amount__c, 'Failed:  Default Total Payment on Job Commission not matched');
            Assert.areEqual(0, exceptionJobCom.Employee_Commissions__r[0].Default_Commission_Amount__c, 'Failed: Default Total Payment on EC not matched');
    
            CommissionCalTestUtility.assertCommissionAllAutoMatches();
        }
    }
}