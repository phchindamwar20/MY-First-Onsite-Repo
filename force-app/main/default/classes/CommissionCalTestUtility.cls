/**
 * @description       : This is a test utlity for validating job commission and employee commission 
 *                      automations and calculations in flow and apex
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-17-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class CommissionCalTestUtility {

    public static List<User> getSalesCommissionableUsers() {
        String queryString = 
            'SELECT  '+
            '    Id, '+  
            '    ADP_Associate_OID__c, '+ 
            '    LastName, '+
            '    FirstName, '+ 
            '    Name, '+
            '    Sales_Commissionable_User__c '+ 
            'FROM ' +
            '    User ' + 
            'WHERE '+
            '    LastName LIKE \'BDAccountManager%\' AND ' +
            '    Sales_Commissionable_User__c=true';
        List<User> salesCommissionableUserLst = (List<User>)Database.query(queryString);

        if (salesCommissionableUserLst == null || salesCommissionableUserLst.isEmpty()) {
            TestFactory.createUsers();
            salesCommissionableUserLst = (List<User>)Database.query(queryString);
        }

        return salesCommissionableUserLst;
    }

    //can only do 0-3 Bds here
    public static WorkOrder createCommissionableJobsList(Integer numberOfCommissionableBDs, List<User> commissionableSalesLst, Id accId, Id propId, Id branchId, Boolean isInsert) {
        WorkOrder job = (WorkOrder)TestFactory.createSObject(
            new WorkOrder(
                AccountId=accId, 
                Property__c=propId, 
                Start_Date__c=Date.today(), 
                Date_of_First_Payment__c=Date.today().addDays(30), 
                Work_Complete_Date__c=Date.today().addDays(60), 
                Date_Fully_Collected__c=Date.today().addDays(90),
                ROM_Contracted_Sales__c=100000.00,
                First_Payment_Amount__c=1000,
                Expected_Margin__c=50.0000,
                ServiceTerritoryId=branchId), 
            'TestFactoryDefaults.JobDefaults', 
            false);

        if (numberOfCommissionableBDs >= 1) {
            job.BD_Account_Manager__c=commissionableSalesLst[0].Id;
        }
        if (numberOfCommissionableBDs >=2) {
            job.BD_Account_Manager_2__c=commissionableSalesLst[1].Id;
        }
        if (numberOfCommissionableBDs >=3) {
            job.BD_Account_Manager_3__c=commissionableSalesLst[2].Id;
        }
        if (isInsert) {
            insert job;
        }

        return job;
    }

    //can only do 0-3 Bds here
    public static WorkOrder createCommissionableJobByNumberOfBDsAndJobMargin(Integer numberOfCommissionableBDs, Decimal expectedMargin ) {
        Bolt__c integrationBolt = new Bolt__c(SetupOwnerId = UserInfo.getUserId(), Is_Bolt_Integration_User__c=true);
        insert integrationBolt; //prevents trigger from firing integration back to Bolt, since the integration bolt user created the record
        Account acc = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.AccountDefaults', true);
        Account propertyNew = (Account)TestFactory.createSObject(new Account(ParentId=acc.Id), 'TestFactoryDefaults.PropertyDefaults', true);
        ServiceTerritory branch = [SELECT Id FROM ServiceTerritory WHERE General_Manager__r.IsActive=true LIMIT 1];

        WorkOrder job = (WorkOrder)TestFactory.createSObject(
            new WorkOrder(
                AccountId=acc.Id, 
                Property__c=propertyNew.Id, 
                Start_Date__c=Date.today(), 
                Date_of_First_Payment__c=Date.today().addDays(30), 
                Work_Complete_Date__c=Date.today().addDays(60), 
                Date_Fully_Collected__c=Date.today().addDays(90),
                ROM_Contracted_Sales__c=100000.00,
                First_Payment_Amount__c=1000,
                Expected_Margin__c=expectedMargin,
                ServiceTerritoryId=branch.Id), 
            'TestFactoryDefaults.JobDefaults', 
            false);

        List<User> commissionableSalesLst = getSalesCommissionableUsers();
        if (numberOfCommissionableBDs >= 1) {
            job.BD_Account_Manager__c=commissionableSalesLst[0].Id;
        }
        if (numberOfCommissionableBDs >=2) {
            job.BD_Account_Manager_2__c=commissionableSalesLst[1].Id;
        }
        if (numberOfCommissionableBDs >=3) {
            job.BD_Account_Manager_3__c=commissionableSalesLst[2].Id;
        }
        
        insert job;

        return job;
    }

    public static WorkOrder createNonCommissionableVariantJob(Boolean isLegal, Boolean isInCollections, Boolean isHouseAccount, Decimal badDebt) {
        Bolt__c integrationBolt = new Bolt__c(SetupOwnerId = UserInfo.getUserId(), Is_Bolt_Integration_User__c=true);
        insert integrationBolt; //prevents trigger from firing integration back to Bolt, since the integration bolt user created the record
        Account acc = (Account)TestFactory.createSObject(new Account(House_Account__c=isHouseAccount), 'TestFactoryDefaults.AccountDefaults', true);
        Account propertyNew = (Account)TestFactory.createSObject(new Account(ParentId=acc.Id), 'TestFactoryDefaults.PropertyDefaults', true);
        List<User> commissionableSalesLst = getSalesCommissionableUsers();
        ServiceTerritory branch = [SELECT Id FROM ServiceTerritory WHERE General_Manager__r.IsActive=true LIMIT 1];

        WorkOrder job = (WorkOrder)TestFactory.createSObject(
            new WorkOrder(
                AccountId=acc.Id, 
                Property__c=propertyNew.Id, 
                Start_Date__c=Date.today(), 
                Date_of_First_Payment__c=Date.today().addDays(30), 
                Work_Complete_Date__c=Date.today().addDays(60), 
                Date_Fully_Collected__c=Date.today().addDays(90),
                ROM_Contracted_Sales__c=100000.00,
                First_Payment_Amount__c=1000,
                Expected_Margin__c=1+Job_Commission_Configuration__mdt.getInstance('Tier_1').Minimum_Margin_for_Tier__c,
                BD_Account_Manager__c=commissionableSalesLst[0].Id,
                BD_Account_Manager_2__c=commissionableSalesLst[1].Id,
                BD_Account_Manager_3__c=commissionableSalesLst[2].Id,
                ServiceTerritoryId=branch.Id), 
            'TestFactoryDefaults.JobDefaults', 
            false);

        if (isLegal) {
            job.Legal__c = isLegal;
        }
        if (isInCollections) {
            job.In_Collections__c=isInCollections;
        }
        if (badDebt != null && badDebt > 0  ) {
            job.Bad_Debt__c = badDebt;
        }
        insert job;

        return job;
    }
    
    public static WorkOrder createDepositFirstPaymentVariantJob(Date startDate, Date dateOfFirstPayment, Decimal firstPaymentAmount) {
        Bolt__c integrationBolt = new Bolt__c(SetupOwnerId = UserInfo.getUserId(), Is_Bolt_Integration_User__c=true);
        insert integrationBolt; //prevents trigger from firing integration back to Bolt, since the integration bolt user created the record
        Account acc = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.AccountDefaults', true);
        Account propertyNew = (Account)TestFactory.createSObject(new Account(ParentId=acc.Id), 'TestFactoryDefaults.PropertyDefaults', true);
        List<User> commissionableSalesLst = getSalesCommissionableUsers();
        ServiceTerritory branch = [SELECT Id FROM ServiceTerritory WHERE General_Manager__r.IsActive=true LIMIT 1];

        WorkOrder job = (WorkOrder)TestFactory.createSObject(
            new WorkOrder(
                AccountId=acc.Id, 
                Property__c=propertyNew.Id, 
                Start_Date__c=startDate, 
                Date_of_First_Payment__c=dateOfFirstPayment, 
                Work_Complete_Date__c=Date.today().addDays(60), 
                Date_Fully_Collected__c=Date.today().addDays(90),
                ROM_Contracted_Sales__c=100000.00,
                Expected_Margin__c=1+Job_Commission_Configuration__mdt.getInstance('Tier_1').Minimum_Margin_for_Tier__c,
                First_Payment_Amount__c=firstPaymentAmount,
                BD_Account_Manager__c=commissionableSalesLst[0].Id,
                BD_Account_Manager_2__c=commissionableSalesLst[1].Id,
                BD_Account_Manager_3__c=commissionableSalesLst[2].Id,
                ServiceTerritoryId=branch.Id), 
            'TestFactoryDefaults.JobDefaults', 
            false);

        insert job;
        return job; 
    }

    public static WorkOrder createTotalCollectionVariantJob(Date workCompleteDate, Date dateFullyCollected) {
        Bolt__c integrationBolt = new Bolt__c(SetupOwnerId = UserInfo.getUserId(), Is_Bolt_Integration_User__c=true);
        insert integrationBolt; //prevents trigger from firing integration back to Bolt, since the integration bolt user created the record
        Account acc = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.AccountDefaults', true);
        Account propertyNew = (Account)TestFactory.createSObject(new Account(ParentId=acc.Id), 'TestFactoryDefaults.PropertyDefaults', true);
        List<User> commissionableSalesLst = getSalesCommissionableUsers();
        ServiceTerritory branch = [SELECT Id FROM ServiceTerritory WHERE General_Manager__r.IsActive=true LIMIT 1];

        WorkOrder job = (WorkOrder)TestFactory.createSObject(
            new WorkOrder(
                AccountId=acc.Id, 
                Property__c=propertyNew.Id, 
                Start_Date__c=Date.today(), 
                Date_of_First_Payment__c=Date.today().addDays(30), 
                Expected_Margin__c = 1+Job_Commission_Configuration__mdt.getInstance('Tier_1').Minimum_Margin_for_Tier__c,
                Work_Complete_Date__c=workCompleteDate, 
                Date_Fully_Collected__c=dateFullyCollected,
                ROM_Contracted_Sales__c=100000.00,
                First_Payment_Amount__c=1000,
                BD_Account_Manager__c=commissionableSalesLst[0].Id,
                BD_Account_Manager_2__c=commissionableSalesLst[1].Id,
                BD_Account_Manager_3__c=commissionableSalesLst[2].Id,
                ServiceTerritoryId=branch.Id),
            'TestFactoryDefaults.JobDefaults', 
            false);

       
        insert job;
        return job;
    }


    public static Job_Commission__c getJobComAndRelatedRecs() {
        return [SELECT 
            Id,
            Job__r.AccountId,
            Job__r.Account.House_Account__c,
            Job__r.Bad_Debt__c,
            Job__r.BD_Account_Manager__c,
            Job__r.BD_Account_Manager__r.Sales_Commissionable_User__c,
            Job__r.BD_Account_Manager_2__c,
            Job__r.BD_Account_Manager_2__r.Sales_Commissionable_User__c,
            Job__r.BD_Account_Manager_3__c,
            Job__r.BD_Account_Manager_3__r.Sales_Commissionable_User__c,
            Job__r.Date_Fully_Collected__c,
            Job__r.Date_of_First_Payment__c,
            Job__r.Expected_Margin__c,
            Job__r.Final_Margin__c,
            Job__r.First_Payment_Amount__c,
            Job__r.House_Account__c,
            Job__r.In_Collections__c,
            Job__r.Legal__c,
            Job__r.ROM_Contracted_Sales__c,
            Job__r.Start_Date__c,
            Job__r.Status,
            Job__r.Work_Complete_Date__c,
            Actual_Commissionable__c,
            Actual_Deposit_1st_Payment_Incentive__c,
            Actual_DepositFirst_Payment_Amount__c,
            Actual_DepositFirst_Payment_Met__c,
    //        Actual_Pay_w_o_Commissionable_Switch__c,
            Actual_Quick_Collection_Incentive__c,
            Actual_Quick_Collection_Met__c,
            Actual_Quick_Collection_Payment_Amount__c,
            Actual_Slow_Collection_Incentive__c,
            Actual_Slow_Collection_Met__c,
            Actual_Slow_Collection_Payment_Amount__c,
            Actual_Total_Collection_Payment_Amount__c,
            Actual_Total_Collection_Type__c,
            Actual_Total_Commission__c,
            Actual_Total_Commission_Payment_Amount__c,
            Added_Employee_Commissions__c,
            Collection_Incentive_Threshold__c,
            Commission_Close_Date__c,
            Commission_Payment_Date__c,
            Commission_Status__c,
            Commissionable_Employee_Removed__c,
            CreatedById,
            CurrencyIsoCode,
            Custom_Splits__c,
            Default_Commissionable__c,
            Default_Deposit_1st_Payment_Incentive__c,
            Default_DepositFirst_Payment_Amount__c,
            Default_DepositFirst_Payment_Met__c,
    //        Default_Pay_w_o_Commissionable_Switch__c,
            Default_Quick_Collection_Incentive__c,
            Default_Quick_Collection_Met__c,
            Default_Quick_Collection_Payment_Amount__c,
            Default_Slow_Collection_Incentive__c,
            Default_Slow_Collection_Met__c,
            Default_Slow_Collection_Payment_Amount__c,
            Default_Total_Collection_Payment_Amount__c,
            Default_Total_Collection_Type__c,
            Default_Total_Commission__c,
            Default_Total_Payment_Amount__c,
            Deposit1st_Payment_Incentive_Threshold__c,
            Deposit_First_Payment_Incentive__c,
            Exception_Commissionable__c,
            Exception_DepositFirst_Payment__c,
            Exception_Quick_Collection__c,
            Exception_Slow_Collection__c,
            Exception_Reason__c,
            Has_Bad_Debt__c,
            House_Account__c,
            Job__c,
            Job_Amount__c,
            Job_Bad_Debt__c,
            Name,
            Job_Commission_Number__c,
            Job_Date_Fully_Collected__c,
            Job_Date_of_DepositFirst_Payment__c,
            Job_DepositFirst_Payment_Amount__c,
            Job_In_Collections__c,
            Job_In_Legal__c,
            Job_Margin__c,
            Job_Start_Date__c,
            Job_Status__c,
            Job_Work_Complete_Date__c,
            Margin_Tier__c,
            Max_Number_of_Employee_Commissions__c,
            Max_Split_Percentage__c,
            Max_Total_Sharable_Percentage__c,
            Maximum_Margin_for_Tier__c,
            Min_Number_of_Employee_Commissions__c,
            Minimum_Margin_for_Tier__c,
            Number_of_Commissionable_Employees__c,
            OwnerId,
            Quick_Collection_Incentive__c,
            Removed_Employee_Commissions__c,
            Slow_Collection_Incentive__c,
            Split_Multiplier__c,
            (
                SELECT 
                    Id,
                    Actual_Commission_Amount__c,
                    Actual_DepositFirst_Payment_Amount__c,
                    Actual_Quick_Collection_Amount__c,
                    Actual_Slow_Collection_Amount__c,
                    Commission_Payment_Date__c,
                    CurrencyIsoCode,
                    Default_Commission_Amount__c,
                    Default_DepositFirst_Payment_Amount__c,
                    Default_Quick_Collection_Amount__c,
                    Default_Slow_Collection_Amount__c,
                    Employee__c,
                    Employee__r.ADP_Associate_OID__c,
                    Employee__r.FirstName,
                    Employee__r.LastName,
                    Employee__r.Sales_Commissionable_User__c,
                    Employee_Commission_ID__c,
                    Name,
                    Employee_Name__c,
                    Individual_Split_Percentage__c, 
                    IsCurrentUser__c,
                    Job__c,
                    Job_Commission__c,
                    Last_Auto_Update_From_BD_EC_Sync__c,
                    Last_Auto_Update_From_Job_Commission__c,
                    OwnerId,
                    Split_Percentage_Override__c,
                    Status__c,
                    Update_Employee_Commission__c
                FROM 
                    Employee_Commissions__r
            )
        FROM Job_Commission__c LIMIT 1 ];
    }

    public static void assertCommissionAllAutoMatches() {
        Job_Commission__c jobCom = getJobComAndRelatedRecs();
        
        //assert financial fields
        assertFinanicalFields(jobCom);

        //tier parameter settings
        assertCommissionParameters(jobCom);
        assertCommissionMultiplierParameters(jobCom);

        //validate job commission fields
        assertJobCommissionFields(jobCom);

        //validate EC/BD count and EC finanicals
        assertEcBdSync(jobCom);
    }

    public static void assertFinanicalFields(Job_Commission__c jobCom) {
        //assert financial fields
        Assert.areEqual(jobCom.Job__r.Bad_Debt__c, jobCom.Job_Bad_Debt__c, 'Failed:  Bad Debt doesn\'t match');
        Assert.areEqual(jobCom.Job__r.Date_Fully_Collected__c,jobCom.Job_Date_Fully_Collected__c, 'Failed:  Date Fully Collected doesn\'t match');
        Assert.areEqual(jobCom.Job__r.Date_of_First_Payment__c, jobCom.Job_Date_of_DepositFirst_Payment__c, 'Failed:  Date of Deposit/First Payment doesn\'t match ');
        Assert.areEqual(jobCom.Job__r.First_Payment_Amount__c, jobCom.Job_DepositFirst_Payment_Amount__c, 'Failed:  Deposit/First Payment Amount doesn\'t match');
        Assert.areEqual(convertCheckboxToYesNo(jobCom.Job__r.House_Account__c), jobCom.House_Account__c, 'Failed: House Account doesn\'t match');
        Assert.areEqual(convertCheckboxToYesNo(jobCom.Job__r.Bad_Debt__c > 0), jobCom.Has_Bad_Debt__c, 'Failed:  Has Bad Debt did\'t calculate properly');
        Assert.areEqual(convertCheckboxToYesNo(jobCom.Job__r.In_Collections__c), jobCom.Job_In_Collections__c, 'Failed: IN Collections doesn\'t match');
        Assert.areEqual(convertCheckboxToYesNo(jobCom.Job__r.Legal__c), jobCom.Job_In_Legal__c, 'Failed: In Legal doesn\'t match');

        //Job Margin
        if (GeneralConstants.OPEN_JOB_STATUSES.contains(jobCom.Job__r.Status)) {
            //Job Open, assert against expected margin
            Assert.areEqual(jobCom.Job__r.Expected_Margin__c, jobCom.Job_Margin__c, 'Failed:  Job Margin doesn\'t match Expected Margin for open job');
        } else {
            //Job Closed or cancelled, assert against final margin
            Assert.areEqual(jobCom.Job__r.Final_Margin__c, jobCom.Job_Margin__c, 'Failed:  Job Margin doesn\'t match Final Margin for closed or cancelled job');
        }
    }
    

    public static void assertJobCommissionCloseDate(Job_Commission__c jobCom) {
        Assert.areEqual(jobCom.Job__r.Close_Date__c, jobCom.Commission_Close_Date__c, 'Failed:  job close date doesn\'t match job commission close date');
    }

    public static void assertCommissionParameters(Job_Commission__c jobCom) {
        Boolean isFound=false;
        for (Job_Commission_Configuration__mdt config : Job_Commission_Configuration__mdt.getAll().values()) {
            if (jobCom.Job_Margin__c != null) {
                if (config == Job_Commission_Configuration__mdt.getInstance('Tier_1') &&
                    jobCom?.Job_Margin__c >= config.Minimum_Margin_for_Tier__c) {
                    System.debug('~~~~ CommissionCalTestUtility::testTiers - Tier 1');
                    Assert.areEqual(SalesIncentivePlanConstants.TIER_1, jobCom.Margin_Tier__c, 'Failed:  Margin Tier not matched');
                    assertSetOfConfigParameters(config, jobCom);
                    isFound=true;
                    break;
                } else if (config== Job_Commission_Configuration__mdt.getInstance('Tier_2')
                    && config.Maximum_Margin_for_Tier__c > jobCom.Job_Margin__c && jobCom.Job_Margin__c >= config.Minimum_Margin_for_Tier__c) {
                    System.debug('~~~~ CommissionCalTestUtility::testTiers - Tier 2');
                    Assert.areEqual(SalesIncentivePlanConstants.TIER_2, jobCom.Margin_Tier__c, 'Failed:  Margin Tier not matched');
                    assertSetOfConfigParameters(config, jobCom);
                    isFound=true;
                    break;
                } else if (config == Job_Commission_Configuration__mdt.getInstance('Tier_3')
                    && config.Maximum_Margin_for_Tier__c > jobCom.Job_Margin__c && jobCom.Job_Margin__c >= config.Minimum_Margin_for_Tier__c) {
                    System.debug('~~~~ CommissionCalTestUtility::testTiers - Tier 3');
                    Assert.areEqual(SalesIncentivePlanConstants.TIER_3, jobCom.Margin_Tier__c, 'Failed:  Margin Tier not matched ');
                    assertSetOfConfigParameters(config, jobCom);
                    isFound=true;
                    break;
                } else if (
                    config == Job_Commission_Configuration__mdt.getInstance('Tier_4') 
                    && config.Maximum_Margin_for_Tier__c > jobCom.Job_Margin__c) {
                    System.debug('~~~~ CommissionCalTestUtility::testTiers - Tier 4');
                    Assert.areEqual(SalesIncentivePlanConstants.TIER_4, jobCom.Margin_Tier__c, 'Failed:  Margin Tier not matched');
                    assertSetOfConfigParameters(config, jobCom);
                    isFound=true;
                    break;
                } 
            } else if  (config == Job_Commission_Configuration__mdt.getInstance('Tier_4') && jobCom.Job_Margin__c == null ) {
                    System.debug('~~~~ CommissionCalTestUtility::testTiers - Tier 4');
                    Assert.areEqual(SalesIncentivePlanConstants.TIER_4, jobCom.Margin_Tier__c, 'Failed:  Margin Tier not matched');
                    assertSetOfConfigParameters(config, jobCom);
                    isFound=true;
                    break;

            }
           
        }
        if (isFound == false) {
            //Tier 4 if no margin
            Assert.fail('No match on commission tier');
        }
    }

    public static void assertCommissionMultiplierParameters(Job_Commission__c jobCom) {
        String tier = jobCom.Margin_Tier__c;
        Decimal numberOfCommissionableEmployees = jobCom.Number_of_Commissionable_Employees__c;

        if (jobCom?.Number_of_Commissionable_Employees__c == null || 
                (
                    Job_Commission_Multiplier__mdt.getInstance(tier+'_1').Min_Number_of_Employee_Commissions__c <= numberOfCommissionableEmployees&& 
                    numberOfCommissionableEmployees < Job_Commission_Multiplier__mdt.getInstance(tier+'_1').Max_Number_of_Employee_Commissions__c
                )
            ) {
            Job_Commission_Multiplier__mdt jcm = Job_Commission_Multiplier__mdt.getInstance(tier+'_1');
            assertSetOfMultiplierParameters(jcm, jobCom);
        } else if (
            Job_Commission_Multiplier__mdt.getInstance(tier+'_2').Min_Number_of_Employee_Commissions__c <= numberOfCommissionableEmployees && 
            numberOfCommissionableEmployees < Job_Commission_Multiplier__mdt.getInstance(tier+'_2').Max_Number_of_Employee_Commissions__c
        ) {
            Job_Commission_Multiplier__mdt jcm = Job_Commission_Multiplier__mdt.getInstance(tier+'_2');
            assertSetOfMultiplierParameters(jcm, jobCom);
        } else if (
            Job_Commission_Multiplier__mdt.getInstance(tier+'_3').Min_Number_of_Employee_Commissions__c <= numberOfCommissionableEmployees 
        ) {
            Job_Commission_Multiplier__mdt jcm = Job_Commission_Multiplier__mdt.getInstance(tier+'_3');
            assertSetOfMultiplierParameters(jcm, jobCom);
        } else {
            Assert.fail('No match on commission multiplier');
        }
    }

    public static void assertEcBdSync(Job_Commission__c jobCom) {
        Integer bdCount = 0;
        Set<Id> commissionableSalesBDIds = new Set<Id>();

        if (jobCom?.Job__r.BD_Account_Manager__c != null && jobCom.Job__r.BD_Account_Manager__r.Sales_Commissionable_User__c == true) {
            commissionableSalesBDIds.add(jobCom.Job__r.BD_Account_Manager__c);
            bdCount++;
        }
        if (jobCom?.Job__r.BD_Account_Manager_2__c != null && jobCom.Job__r.BD_Account_Manager_2__r.Sales_Commissionable_User__c == true) {
            commissionableSalesBDIds.add(jobCom.Job__r.BD_Account_Manager_2__c);
            bdCount++;
        }
        if (jobCom?.Job__r.BD_Account_Manager_3__c != null && jobCom.Job__r.BD_Account_Manager_3__r.Sales_Commissionable_User__c == true) {
            commissionableSalesBDIds.add(jobCom.Job__r.BD_Account_Manager_3__c);
            bdCount++;
        }
        //verify the commissionable sales users are unique
        if (bdCount != commissionableSalesBDIds.size()) {
            Assert.fail('number of commissionable sales bds aren\'t unique');
        }

        //verify ec and bds
        Decimal total = 0.0000;
        Decimal split =  bdCount > 0 ? 100.0000/bdCount: 0;
        split = split.setScale(4);
        Decimal oddSplit = 100.0000 - bdCount * split;
        oddSplit = oddSplit.setScale(4);
        oddSplit += split;

        Integer ecCount = jobCom.Employee_Commissions__r.size();
        Integer ecActualCount = 0;
        for (Employee_Commission__c ec : jobCom.Employee_Commissions__r) {
            System.debug('~~~~ CommissionCalTestUtility::assertEcBdSync: ec.Individual_Split_Percentage__c - ' + ec.Individual_Split_Percentage__c);
            System.debug('~~~~ CommissionCalTestUtility::assertEcBdSync: ec.Actual_DepositFirst_Payment_Amount__c - ' + ec.Actual_DepositFirst_Payment_Amount__c);
            String expectedEmployeeId = '';
            if (jobCom.Job__r.BD_Account_Manager__c == ec.Employee__c) {
                expectedEmployeeId = jobCom.Job__r.BD_Account_Manager__c;
            } else if (jobCom.Job__r.BD_Account_Manager_2__c == ec.Employee__c) {
                expectedEmployeeId=jobCom.Job__r.BD_Account_Manager_2__c;
            } else if (jobCom.Job__r.BD_Account_Manager_3__c == ec.Employee__c) {
                expectedEmployeeId=jobCom.Job__r.BD_Account_Manager_3__c;
            }

            if (commissionableSalesBDIds.contains(ec.Employee__c)) {
                ecActualCount++;
                Assert.areEqual(expectedEmployeeId, ec.Employee__c, 'Failed:  Employee doesn\'t match');
                Assert.isTrue(ec.Individual_Split_Percentage__c == split || ec.Individual_Split_Percentage__c == oddSplit, 'Failed: Auto calculated Individual Split Percentage not calculated properly');
                assertEmployeeCommissionFields(jobCom, ec);
                total += ec.Individual_Split_Percentage__c;
            } else {
                Assert.fail('No match on EC/BD Sync');
            }
        }

        Assert.areEqual(ecCount, ecActualCount, 'Failed:  The number of total ecs don\'t match the number of ECs that are commissionable Sales Users');
        Assert.areEqual(bdCount, ecActualCount, 'Failed:  number of commissionable sales bds on job doesn\'t match the employee commission count of commissionable sales bds');

        if (jobCom?.Employee_Commissions__r.size() > 0) {
            Assert.areEqual(100.0000, total, 'Failed:  expected sum of all employee commission splits to add to 100%');
        }
    }

    public static void assertJobCommissionFields(Job_Commission__c jobCom) {
        assertJobCommissionDefault(jobCom);
        assertJobCommissionExceptions(jobCom);
        assertJobCommissionActual(jobCom) ;
    }

    public static void assertJobCommissionDefault(Job_Commission__c jobCom) {
        //***** Default ****
        //Default Expected Commissionable 
        String exDefaultCommissionable = SalesIncentivePlanConstants.YES;
        if (
            (jobCom.Job_Bad_Debt__c != null && jobCom.Job_Bad_Debt__c > 0) ||
            jobCom.Job_In_Legal__c == SalesIncentivePlanConstants.YES  ||
            jobCom.Job_In_Collections__c == SalesIncentivePlanConstants.YES ||
            jobCom.House_Account__c == SalesIncentivePlanConstants.YES
        ) {
            exDefaultCommissionable = SalesIncentivePlanConstants.NO;
        }
        Decimal baseAmount = exDefaultCommissionable == SalesIncentivePlanConstants.YES ? jobCom.Job_Amount__c * jobCom.Split_Multiplier__c / 100 : 0;

        //Default Expected Deposit First Payment 
        String exDefaultDepositFirstPaymentMet = SalesIncentivePlanConstants.NO;
        Decimal exDefaultDepositFirstPaymentIncentive = 0.0000;
        Decimal exDefaultDepositFirstPaymentAmount = 0.00;
        if (jobCom.Job_Start_Date__c != null && jobCom.Job_Date_of_DepositFirst_Payment__c != null && 
            jobCom.Job_Start_Date__c.daysBetween(jobCom.Job_Date_of_DepositFirst_Payment__c) <= jobCom.Deposit1st_Payment_Incentive_Threshold__c) {
            exDefaultDepositFirstPaymentMet = SalesIncentivePlanConstants.YES;
            exDefaultDepositFirstPaymentIncentive = jobCom.Deposit_First_Payment_Incentive__c;
            exDefaultDepositFirstPaymentAmount = jobCom.Deposit_First_Payment_Incentive__c * baseAmount;
        }

        //Default Expected Total Collection 
        String exDefaultQuickCollectionMet = SalesIncentivePlanConstants.NO;
        String exDefaultSlowCollectionMet = SalesIncentivePlanConstants.NO;
        String exDefaultTotalCollectionType = SalesIncentivePlanConstants.NONE;
        Decimal exDefaultQuickCollectionIncentive = 0.0000;
        Decimal exDefaultSlowCollectionIncentive = 0.0000;
        Decimal exDefaultQuickCollectionAmount = 0.00;
        Decimal exDefaultSlowCollectionAmount = 0.00;
        Decimal exDefaultTotalCollectionAmount = 0.00;
        if (jobCom.Job_Work_Complete_Date__c != null && jobCom.Job_Date_Fully_Collected__c != null) {
            if (jobCom.Job_Work_Complete_Date__c.daysBetween(jobCom.Job_Date_Fully_Collected__c) <= jobCom.Collection_Incentive_Threshold__c) {
                exDefaultQuickCollectionMet = SalesIncentivePlanConstants.YES;
                exDefaultTotalCollectionType = SalesIncentivePlanConstants.QUICK_COLLECTION;
                exDefaultQuickCollectionIncentive = jobCom.Quick_Collection_Incentive__c;
                exDefaultQuickCollectionAmount = jobCom.Quick_Collection_Incentive__c * baseAmount;
                exDefaultTotalCollectionAmount = exDefaultQuickCollectionAmount;
            } else {
                exDefaultSlowCollectionMet = SalesIncentivePlanConstants.YES;
                exDefaultTotalCollectionType = SalesIncentivePlanConstants.SLOW_COLLECTION;
                exDefaultSlowCollectionIncentive = jobCom.Slow_Collection_Incentive__c;
                exDefaultSlowCollectionAmount = jobCom.Slow_Collection_Incentive__c * baseAmount;
                exDefaultTotalCollectionAmount = exDefaultSlowCollectionAmount;
            }
        }

        //Default Total Amount
        //expectedTotalPaymentAmount =  exDefaultDepositFirstPaymentAmount + exDefaultTotalCollectionAmount ;
        Decimal exTotalPaymentAmount = baseAmount * (exDefaultDepositFirstPaymentIncentive + exDefaultQuickCollectionIncentive + exDefaultSlowCollectionIncentive);
        Decimal exTotalCommissionPercent = 0;
        if (jobCom.Job_Amount__c > 0) {
            exTotalCommissionPercent = 100 * exTotalPaymentAmount / jobCom.Job_Amount__c;
        }

        //Assert Defaults
        Assert.areEqual(exDefaultCommissionable, jobCom.Default_Commissionable__c, 'Failed: Default Commissionable doesn\'t match');
        Assert.areEqual(exDefaultDepositFirstPaymentMet, jobCom.Default_DepositFirst_Payment_Met__c, 'Failed:  Default Deposit/First Payment inccorrect');
        Assert.areEqual(exDefaultDepositFirstPaymentIncentive, jobCom.Default_Deposit_1st_Payment_Incentive__c, 'Failed:  Default deposit first payment doesn\'t match');
        Assert.areEqual(exDefaultDepositFirstPaymentAmount.setScale(2, System.RoundingMode.HALF_UP), jobCom.Default_DepositFirst_Payment_Amount__c, 'Failed:  Default Deposit/First Payment Amount doesn\'t match');
        Assert.areEqual(exDefaultQuickCollectionMet, jobCom.Default_Quick_Collection_Met__c, 'Failed: Default Quick Collection Met doesn\'t match');
        Assert.areEqual(exDefaultSlowCollectionMet, jobCom.Default_Slow_Collection_Met__c, 'Failed: Default Slow Collection Met doesn\'t match');
        Assert.areEqual(exDefaultTotalCollectionType, jobCom.Default_Total_Collection_Type__c, 'Failed: Default Total Collection Type doesn\'t match');
        Assert.areEqual(exDefaultQuickCollectionIncentive, jobCom.Default_Quick_Collection_Incentive__c, 'Failed:  Default Quick Collection Incentive doesn\'t match');
        Assert.areEqual(exDefaultSlowCollectionIncentive, jobCom.Default_Slow_Collection_Incentive__c, 'Failed:  Default Slow Collection Incentive doesn\'t match');
        Assert.areEqual(exDefaultQuickCollectionAmount.setScale(2, System.RoundingMode.HALF_UP), jobCom.Default_Quick_Collection_Payment_Amount__c, 'Failed:  Default Quick Collection Payment Amount');
        Assert.areEqual(exDefaultSlowCollectionAmount.setScale(2, System.RoundingMode.HALF_UP), jobCom.Default_Slow_Collection_Payment_Amount__c, 'Failed: Default Slow Collection Payment Amount');
        Assert.areEqual(exDefaultTotalCollectionAmount.setScale(2, System.RoundingMode.HALF_UP), jobCom.Default_Total_Collection_Payment_Amount__c, 'Failed:  Default Total Collection Payment Amount failed');
        Assert.areEqual(exTotalPaymentAmount.setScale(2, System.RoundingMode.HALF_UP), jobCom.Default_Total_Payment_Amount__c, 'Failed:  Default Total Payment Amount failed');
        Assert.areEqual(exTotalCommissionPercent, jobCom.Default_Total_Commission__c, 'Failed:  Total Commission Percent failed');
    }

    public static void assertJobCommissionExceptions(Job_Commission__c jobCom) {
        String exExceptionCommissionable =  jobCom.Default_Commissionable__c != jobCom.Actual_Commissionable__c ? SalesIncentivePlanConstants.YES : SalesIncentivePlanConstants.NO;
        String exExceptionFirstDepositFirstPayment = jobCom.Default_DepositFirst_Payment_Met__c != jobCom.Actual_DepositFirst_Payment_Met__c ? SalesIncentivePlanConstants.YES : SalesIncentivePlanConstants.NO;
        String exActualDepositFirstPaymentMet = jobCom.Exception_DepositFirst_Payment__c == SalesIncentivePlanConstants.NO ?  jobCom.Default_DepositFirst_Payment_Met__c : oppositeYesNo(jobCom.Default_DepositFirst_Payment_Met__c);
        String exExceptionQuickCollection  = SalesIncentivePlanConstants.NO;
        String exExceptionSlowCollection = SalesIncentivePlanConstants.NO;
        String exActualQuickCollectionMet = SalesIncentivePlanConstants.NO;
        String exActualSlowCollectionMet = SalesIncentivePlanConstants.NO;

        if(jobCom.Default_Slow_Collection_Met__c == jobCom.Default_Quick_Collection_Met__c && jobCom.Default_Slow_Collection_Met__c==SalesIncentivePlanConstants.NO && jobCom.Actual_Slow_Collection_Met__c == SalesIncentivePlanConstants.YES) {
            exActualSlowCollectionMet = SalesIncentivePlanConstants.YES;
            exExceptionSlowCollection = SalesIncentivePlanConstants.YES;
        } else if (jobCom.Default_Slow_Collection_Met__c == jobCom.Default_Quick_Collection_Met__c && jobCom.Default_Slow_Collection_Met__c==SalesIncentivePlanConstants.NO && jobCom.Actual_Quick_Collection_Met__c == SalesIncentivePlanConstants.YES) {
            exActualQuickCollectionMet = SalesIncentivePlanConstants.YES;
            exExceptionQuickCollection = SalesIncentivePlanConstants.YES;
        } else if (jobCom.Default_Quick_Collection_Met__c == jobCom.Actual_Quick_Collection_Met__c && jobCom.Actual_Quick_Collection_Met__c==SalesIncentivePlanConstants.YES ) {
            exActualQuickCollectionMet = SalesIncentivePlanConstants.YES;
            exActualSlowCollectionMet = SalesIncentivePlanConstants.NO;
        } else if (jobCom.Actual_Slow_Collection_Met__c == jobCom.Default_Slow_Collection_Met__c && jobCom.Actual_Slow_Collection_Met__c==SalesIncentivePlanConstants.YES) {
            exActualQuickCollectionMet = SalesIncentivePlanConstants.NO;
            exActualSlowCollectionMet = SalesIncentivePlanConstants.YES;
        } else  {
            if (jobCom.Actual_Quick_Collection_Met__c != jobCom.Default_Quick_Collection_Met__c) {
                exExceptionQuickCollection = SalesIncentivePlanConstants.YES;
                exActualQuickCollectionMet = jobCom.Actual_Quick_Collection_Met__c;
                exActualSlowCollectionMet = oppositeYesNo(exActualQuickCollectionMet);
            }
            if (jobCom.Actual_Slow_Collection_Met__c != jobCom.Default_Slow_Collection_Met__c) {
                exExceptionSlowCollection = SalesIncentivePlanConstants.YES;
                exActualSlowCollectionMet = jobCom.Actual_Slow_Collection_Met__c;
                exActualQuickCollectionMet = oppositeYesNo(exActualSlowCollectionMet);
            }
        }

        Assert.areEqual(exExceptionCommissionable, jobCom.Exception_Commissionable__c, 'Failed: Exception Commissionable not expected');
        Assert.areEqual(exExceptionFirstDepositFirstPayment, jobCom.Exception_DepositFirst_Payment__c, 'Failed:  Exception Deposit First Payment Doesn\'t match');
        Assert.areEqual(exActualDepositFirstPaymentMet, jobCom.Actual_DepositFirst_Payment_Met__c, 'Failed:  Actual Deposit First Payment Met not matched');
        Assert.areEqual(exExceptionQuickCollection, jobCom.Exception_Quick_Collection__c, 'Failed: Exception Quick Collection not matched');
        Assert.areEqual(exExceptionSlowCollection, jobCom.Exception_Slow_Collection__c, 'Failed:  Exception Slow Collection not matched');
        Assert.areEqual(exActualQuickCollectionMet, jobCom.Actual_Quick_Collection_Met__c, 'Failed: Actual Quick Collection Met not matched');
        Assert.areEqual(exActualSlowCollectionMet, jobCom.Actual_Slow_Collection_Met__c, 'Failed:  Actual Slow Collection Met not matched');
    }

    public static void assertJobCommissionActual(Job_Commission__c jobCom) {
        Decimal baseAmount = JobCom.Actual_Commissionable__c == SalesIncentivePlanConstants.YES ? JobCom.Job_Amount__c * JobCom.Split_Multiplier__c / 100 : 0;
        Decimal exActualDepositFirstPaymentIncentive = jobCom.Actual_DepositFirst_Payment_Met__c == SalesIncentivePlanConstants.YES ? 
                                                        jobCom.Deposit_First_Payment_Incentive__c : 0;
        Decimal exActualDepositFirstPayentAmount = exActualDepositFirstPaymentIncentive * baseAmount;
        Decimal exActualQuickCollectionIncentive = jobCom.Actual_Quick_Collection_Met__c == SalesIncentivePlanConstants.YES && 
                                                    jobCom.Actual_Slow_Collection_Met__c == SalesIncentivePlanConstants.NO? 
                                                        jobCom.Quick_Collection_Incentive__c : 0;
        Decimal exActualQuickCollectionAmount = exActualQuickCollectionIncentive * baseAmount;
        Decimal exActualSlowCollectionIncentive = jobCom.Actual_Slow_Collection_Met__c == SalesIncentivePlanConstants.YES && 
                                                    jobCom.Actual_Quick_Collection_Met__c == SalesIncentivePlanConstants.NO? 
                                                        jobCom.Slow_Collection_Incentive__c : 0;
        Decimal exActualSlowCollectionAmount = exActualSlowCollectionIncentive * baseAmount;
        Decimal exActualTotalCollectionPaymentAmount = 0;
        String exActualTotalCollectionType = SalesIncentivePlanConstants.NONE;
        Decimal exActualTotalCommissionPaymentAmount =  (exActualDepositFirstPaymentIncentive + exActualQuickCollectionIncentive + exActualSlowCollectionIncentive)
                                                            * baseAmount;
        Decimal exActualTotalCommission = jobCom.Job_Amount__c > 0 ? 100 * exActualTotalCommissionPaymentAmount / jobCom.Job_Amount__c : 0;

        if (jobCom.Actual_Quick_Collection_Met__c == SalesIncentivePlanConstants.YES) {
            exActualTotalCollectionPaymentAmount = exActualQuickCollectionAmount;
            exActualTotalCollectionType = SalesIncentivePlanConstants.QUICK_COLLECTION;
        } else if (jobCom.Actual_Slow_Collection_Met__c == SalesIncentivePlanConstants.YES) {
            exActualTotalCollectionPaymentAmount = exActualSlowCollectionAmount;
            exActualTotalCollectionType = SalesIncentivePlanConstants.SLOW_COLLECTION;
        }

        Assert.areEqual(exActualDepositFirstPaymentIncentive, jobCom.Actual_Deposit_1st_Payment_Incentive__c, 'Failed: Actual deposit 1st payment incentive not matched');
        Assert.areEqual(exActualDepositFirstPayentAmount.setScale(2, System.RoundingMode.HALF_UP), jobCom.Actual_DepositFirst_Payment_Amount__c, 'Failed: Actual deposit first payment amount not matched');
        Assert.areEqual(exActualQuickCollectionIncentive, jobCom.Actual_Quick_Collection_Incentive__c, 'Failed: Actual quick collection incentive not matched');
        Assert.areEqual(exActualQuickCollectionAmount.setScale(2, System.RoundingMode.HALF_UP), jobCom.Actual_Quick_Collection_Payment_Amount__c, 'Failed: Actual quick collection amount not matched');
        Assert.areEqual(exActualSlowCollectionIncentive, jobCom.Actual_Slow_Collection_Incentive__c, 'Failed: Actual slow collection incentive not matched');
        Assert.areEqual(exActualSlowCollectionAmount.setScale(2, System.RoundingMode.HALF_UP), jobCom.Actual_Slow_Collection_Payment_Amount__c, 'Failed: Actual slow collection amount not matched');
        Assert.areEqual(exActualTotalCollectionPaymentAmount.setScale(2, System.RoundingMode.HALF_UP), jobCom.Actual_Total_Collection_Payment_Amount__c, 'Failed: Actual total collection payment amount not matched');
        Assert.areEqual(exActualTotalCollectionType, jobCom.Actual_Total_Collection_Type__c, 'Failed: Actual total collection type not matched');
        Assert.areEqual(exActualTotalCommissionPaymentAmount.setScale(2, System.RoundingMode.HALF_UP), jobCom.Actual_Total_Commission_Payment_Amount__c, 'Failed: Actual total commission payment amount not matched');
        Assert.areEqual(exActualTotalCommission.setScale(4, System.RoundingMode.HALF_UP), jobCom.Actual_Total_Commission__c, 'Failed: Actual total commission not matched');
    }

    public static void assertEmployeeCommissionFields(Job_Commission__c jobCom, Employee_Commission__c ec) {
        Decimal baseAmountActual = jobCom.Actual_Commissionable__c == SalesIncentivePlanConstants.YES ? ec.Individual_Split_Percentage__c / 100 * jobCom.Split_Multiplier__c * jobCom.Job_Amount__c / 100 : 0 ;
        //baseAmountActual = baseAmountActual.setScale(2, System.RoundingMode.HALF_UP);
        Decimal baseAmountDefault = jobCom.Default_Commissionable__c == SalesIncentivePlanConstants.YES ? ec.Individual_Split_Percentage__c / 100 * jobCom.Split_Multiplier__c * jobCom.Job_Amount__c / 100 : 0;
        //baseAmountDefault = baseAmountDefault.setScale(2, System.RoundingMode.HALF_UP);
        Decimal exActualCommissionAmount = baseAmountActual * (jobCom.Actual_Deposit_1st_Payment_Incentive__c + jobCom.Actual_Quick_Collection_Incentive__c + jobCom.Actual_Slow_Collection_Incentive__c);
        exActualCommissionAmount = exActualCommissionAmount.setScale(2, System.RoundingMode.HALF_UP);
        Decimal exActualDepositFirstPaymentAmount = baseAmountActual * jobCom.Actual_Deposit_1st_Payment_Incentive__c;
        exActualDepositFirstPaymentAmount = exActualDepositFirstPaymentAmount.setScale(2, System.RoundingMode.HALF_UP);
        Decimal exActualQuickCollectionAmount = baseAmountActual * jobCom.Actual_Quick_Collection_Incentive__c;
        exActualQuickCollectionAmount = exActualQuickCollectionAmount.setScale(2, System.RoundingMode.HALF_UP);
        Decimal exActualSlowCollectionAmount = baseAmountActual * jobCom.Actual_Slow_Collection_Incentive__c;
        exActualSlowCollectionAmount = exActualSlowCollectionAmount.setScale(2, System.RoundingMode.HALF_UP);
        Decimal exDefaultCommissionAmount = baseAmountDefault * (jobCom.Default_Deposit_1st_Payment_Incentive__c + jobCom.Default_Quick_Collection_Incentive__c + jobCom.Default_Slow_Collection_Incentive__c);
        exDefaultCommissionAmount = exDefaultCommissionAmount.setScale(2, System.RoundingMode.HALF_UP);
        Decimal exDefaultDepositFirstPaymentAmount = baseAmountDefault * jobCom.Default_Deposit_1st_Payment_Incentive__c;
        exDefaultDepositFirstPaymentAmount = exDefaultDepositFirstPaymentAmount.setScale(2, System.RoundingMode.HALF_UP);
        Decimal exDefaultQuickCollectionAmount = baseAmountDefault * jobCom.Default_Quick_Collection_Incentive__c;
        exDefaultQuickCollectionAmount = exDefaultQuickCollectionAmount.setScale(2, System.RoundingMode.HALF_UP);
        Decimal exDefaultSlowCollectionAmount = baseAmountDefault * jobCom.Default_Slow_Collection_Incentive__c;
        exDefaultSlowCollectionAmount = exDefaultSlowCollectionAmount.setScale(2, System.RoundingMode.HALF_UP);

        Assert.areEqual(exActualCommissionAmount , ec.Actual_Commission_Amount__c, 'Failed:  actual commission amount doesn\'t match');
        Assert.areEqual(exActualDepositFirstPaymentAmount, ec.Actual_DepositFirst_Payment_Amount__c, 'Failed:  actual deposit first payment amount doesn\'t match');
        Assert.areEqual(exActualQuickCollectionAmount, ec.Actual_Quick_Collection_Amount__c, 'Failed: actual quick collections amount doesn\'t match');
        Assert.areEqual(exActualSlowCollectionAmount, ec.Actual_Slow_Collection_Amount__c, 'Failed:  actual slow collection amount doesn\'t match');
        Assert.areEqual(exDefaultCommissionAmount, ec.Default_Commission_Amount__c, 'Failed: default commission amount doesn\'t work');
        Assert.areEqual(exDefaultDepositFirstPaymentAmount, ec.Default_DepositFirst_Payment_Amount__c, 'Failed: default deposit 1st payment incentive failed');
        Assert.areEqual(exDefaultQuickCollectionAmount, ec.Default_Quick_Collection_Amount__c, 'Failed: default quick collection amount');
        Assert.areEqual(exDefaultSlowCollectionAmount, ec.Default_Slow_Collection_Amount__c, 'Failed: default slow collection amount');
        Assert.areEqual(jobCom.Name+'-'+ec.Employee__r.ADP_Associate_OID__c, ec.Employee_Commission_ID__c, 'Failed: Job Commission record doesn\'t match');
        Assert.areEqual(jobCom.Name+'-'+ec.Employee__r.LastName+', '+ec.Employee__r.FirstName, ec.Name, 'Failed:  Named not matched');
        Assert.areEqual(ec.Employee__c, ec.OwnerId, 'Failed:  Owner should match employee');
        Assert.areEqual(jobCom.Job__c, ec.Job__c, 'Failed:  job not referenced on Employee Reference');
        Assert.areEqual(jobCom.Id, ec.Job_Commission__c, 'Failed: Employee Commission doesn\'t have job commission');
        //TODO:  add assertion for  status field
    }

    public static void assertSetOfConfigParameters(Job_Commission_Configuration__mdt config, Job_Commission__c jobCom) {
        Assert.areEqual(config.Collection_Incentive_Threshold__c, jobCom.Collection_Incentive_Threshold__c, 'Failed: not matching incentive threshold');
        Assert.areEqual(config.Deposit1st_Payment_Incentive_Threshold__c, jobCom.Deposit1st_Payment_Incentive_Threshold__c, 'Failed:  not matching Deposit/1st Payment Incentive Threshold');
        Assert.areEqual(config.DepositFirst_Payment_Incentive__c, jobCom.Deposit_First_Payment_Incentive__c, 'Failed:  not matching Deposit First Payment Incentive');
        Assert.areEqual(config.DeveloperName, jobCom.Margin_Tier__c, 'Failed: not matching margin tier');
        Assert.areEqual(config.Maximum_Margin_for_Tier__c, jobCom.Maximum_Margin_for_Tier__c, 'Failed:  not matching Maximum Margin For Tier');
        Assert.areEqual(config.Minimum_Margin_for_Tier__c, jobCom.Minimum_Margin_for_Tier__c, 'Failed: not matching Minimum Margin for Tier');
        Assert.areEqual(config.Quick_Collection_Incentive__c, jobCom.Quick_Collection_Incentive__c, 'Failed:  not matching Quick Collection Incentive');
        Assert.areEqual(config.Slow_Collection_Incentive__c, jobCom.Slow_Collection_Incentive__c, 'Failed: not matching Slow Collection Incentive');
    }

    public static void assertSetOfMultiplierParameters(Job_Commission_Multiplier__mdt jcm, Job_Commission__c jobCom) {
        Assert.areEqual(jcm.Split_Multiplier__c, jobCom.Split_Multiplier__c,  'Failed: expected Split Multiplier to match');
        Assert.areEqual(jcm.Max_Split_Percent_for_One_EC__c, jobCom.Max_Split_Percentage__c, 'Failed: Max Split Percentage doesn\'t match');
        Assert.areEqual(jcm.Max_Number_of_Employee_Commissions__c, jobCom.Max_Number_of_Employee_Commissions__c, 'Failed:  Max Number of Employee Commissions doesn\'t match');
        Assert.areEqual(jcm.Min_Number_of_Employee_Commissions__c, jobCom.Min_Number_of_Employee_Commissions__c, 'Failed: Min Number of Employee Commissions doesn\'t match');
        Assert.areEqual(jcm.Max_Total_Sharable_Percent__c, jobCom.Max_Total_Sharable_Percentage__c, 'Failed: Max Total Sharable Percentage doesn\'t match');
    }

    public static String convertCheckboxToYesNo(Boolean value) {
        if (value) {
            return SalesIncentivePlanConstants.YES;
        }else { 
            return SalesIncentivePlanConstants.NO;
        }
    }
    
    public static String oppositeYesNo(String value) {
        if (value == SalesIncentivePlanConstants.YES) {
            return SalesIncentivePlanConstants.NO;
        } else {
            return SalesIncentivePlanConstants.YES;
        }
    }
}