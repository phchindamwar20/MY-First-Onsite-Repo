/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-19-2023
 * @last modified by  : Terri Jiles
**/
@isTest
public with sharing class AccountLifetimeRollupServiceTest {
    @TestSetup
    static private void makeData(){
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
    static private void testLifetimeRollup() {
        List<Account> grandParentAccountLst = (List<Account>)TestFactory.createSObjectList(new Account(RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId()), 20, 'TestFactoryDefaults.AccountDefaults', false);
        List<WorkOrder> grandParentsJobsLstA = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=10000, AR_Balance__c=0, ROM_Contracted_Sales__c=0, Status='In Progress'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> grandParentsJobsLstB = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=10000, ROM_Contracted_Sales__c=0, Status='AR Pending'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> grandParentsJobsLstC = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=0, ROM_Contracted_Sales__c=10000, Status='AP Pending'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> grandParentsJobsLstD = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=0, ROM_Contracted_Sales__c=0, Status='Pre-production'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> grandParentsJobsLst = new List<WorkOrder>();
        List<Account> parentAccLst1 = (List<Account>)TestFactory.createSObjectList(new Account(RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId()), 20, 'TestFactoryDefaults.AccountDefaults', false);
        List<Account> parentAccLst2 = (List<Account>)TestFactory.createSObjectList(new Account(RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId()), 20, 'TestFactoryDefaults.AccountDefaults', false);
        List<Account> parentAccLst = new List<Account>();
        Integer j=0;
        for (Account grandParentAcc : grandParentAccountLst) {
            grandParentAcc.Name='Grandparent'+j;
            j++;
        }
        insert grandParentAccountLst;

        j=0;
        for (Account grandParentAcc : grandParentAccountLst) {
            grandParentsJobsLstA[j].AccountId=grandParentAcc.Id;
            grandParentsJobsLstB[j].AccountId=grandParentAcc.Id;
            grandParentsJobsLstC[j].AccountId=grandParentAcc.Id;
            grandParentsJobsLstD[j].AccountId=grandParentAcc.Id;
            parentAccLst1[j].ParentId = grandParentAcc.Id;
            parentAccLst1[j].Name='Parent1'+j;
            parentAccLst2[j].ParentId = grandParentAcc.Id;
            parentAccLst2[j].Name='Parent2'+j;
            j++;
        }

        grandParentsJobsLst.addAll(grandParentsJobsLstA);
        grandParentsJobsLst.addAll(grandParentsJobsLstB);
        grandParentsJobsLst.addAll(grandParentsJobsLstC);
        grandParentsJobsLst.addAll(grandParentsJobsLstD);
        insert grandParentsJobsLst;
        parentAccLst.addAll(parentAccLst1);
        parentAccLst.addAll(parentAccLst2);
        insert parentAccLst;

        List<WorkOrder> parentJobLst1A = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=10000, AR_Balance__c=0, ROM_Contracted_Sales__c=0, Status='Pre-production'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> parentJobLst1B = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=10000, ROM_Contracted_Sales__c=0, Status='Work Complete'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> parentJobLst1C = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=0, ROM_Contracted_Sales__c=10000, Status='In Progress'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> parentJobLst1D = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=0, ROM_Contracted_Sales__c=0, Status='AR Pending'), 20, 'TestFactoryDefaults.JobDefaults', false);

        List<WorkOrder> parentJobLst2A = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=10000, AR_Balance__c=0, ROM_Contracted_Sales__c=0, Status='Closed'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> parentJobLst2B = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=10000, ROM_Contracted_Sales__c=0, Status='AR Pending'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> parentJobLst2C = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=0, ROM_Contracted_Sales__c=10000, Status='Pre-production'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> parentJobLst2D = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=0, ROM_Contracted_Sales__c=0, Status='Work Complete'), 20, 'TestFactoryDefaults.JobDefaults', false);        
        
        List<WorkOrder> parentJobLst = new List<WorkOrder>();

        List<Account> childAccountLst1 = (List<Account>)TestFactory.createSObjectList(new Account(RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId()), 20, 'TestFactoryDefaults.AccountDefaults', false);

        for (Integer i=0 ; i<grandParentAccountLst.size() ; i++) {
            parentJobLst1A[i].AccountId=parentAccLst1[i].Id;
            parentJobLst1B[i].AccountId=parentAccLst1[i].Id;
            parentJobLst1C[i].AccountId=parentAccLst1[i].Id;
            parentJobLst1D[i].AccountId=parentAccLst1[i].Id;
            childAccountLst1[i].ParentId=parentAccLst1[i].Id;
            childAccountLst1[i].Name='Child1'+i;
            parentJobLst2A[i].AccountId=parentAccLst2[i].Id;
            parentJobLst2B[i].AccountId=parentAccLst2[i].Id;
            parentJobLst2C[i].AccountId=parentAccLst2[i].Id;
            parentJobLst2D[i].AccountId=parentAccLst2[i].Id;
        }

        parentJobLst.addAll(parentJobLst1A);
        parentJobLst.addAll(parentJobLst1B);
        parentJobLst.addAll(parentJobLst1C);
        parentJobLst.addAll(parentJobLst1D);
        parentJobLst.addAll(parentJobLst2A);
        parentJobLst.addAll(parentJobLst2B);
        parentJobLst.addAll(parentJobLst2C);
        parentJobLst.addAll(parentJobLst2D);
        
        insert parentJobLst;
        insert childAccountLst1;

        List<WorkOrder> childJobLst1A = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=500000, AR_Balance__c=0, ROM_Contracted_Sales__c=0, Status='Closed'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> childJobLst1B = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=500000, ROM_Contracted_Sales__c=0, Status='Pre-production'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> childJobLst1C = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=0, ROM_Contracted_Sales__c=500000, Status='In Progress'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> childJobLst1D = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(Paid_to_Date__c=0, AR_Balance__c=0, ROM_Contracted_Sales__c=0, Status='Work Complete'), 20, 'TestFactoryDefaults.JobDefaults', false);
        List<WorkOrder> childJobLst1 = new List<WorkOrder>();
        j=0;
        for (Account childAccount : childAccountLst1) {
            childJobLst1A[j].AccountId=childAccount.Id;
            childJobLst1B[j].AccountId=childAccount.Id;
            childJobLst1C[j].AccountId=childAccount.Id;
            childJobLst1D[j].AccountId=childAccount.Id;
            j++;
        }
        childJobLst1.addAll(childJobLst1A);
        childJobLst1.addAll(childJobLst1B);
        childJobLst1.addAll(childJobLst1C);
        childJobLst1.addAll(childJobLst1D);

        insert childJobLst1;

        Test.startTest();
        AccountLifetimeRollupService.rollUpJobsOnAccounts([SELECT Id, Name, ParentId, Lifetime_Total_Revenue__c, Lifetime_Total_Revenue_Children__c, Lifetime_Open_Collections__c, Lifetime_Contracted_Sales__c 
                                                            FROM Account 
                                                            WHERE RecordType.DeveloperName IN ('Parent', 'Account')]);
        Test.stopTest();

        //check sample
        for (Account acc : [SELECT Id, Name, ParentId, Lifetime_Total_Revenue__c, Lifetime_Total_Revenue_Children__c, Lifetime_Open_Collections__c, Lifetime_Contracted_Sales__c, Lifetime_Contracted_Sales_Children__c, Lifetime_Number_of_Jobs__c, Lifetime_Number_of_Jobs_Children__c, 
                                (SELECT Id, Paid_to_Date__c, AR_Balance__c, ROM_Contracted_Sales__c, Status FROM WorkOrders) 
                                FROM Account 
                                WHERE Name IN ('Grandparent0', 'Parent10', 'Parent20', 'Child10')]) {
            System.debug('~~~~ AccountLifetimeRollupServiceTest::testLifetimeRollup: acc - ' + acc);
            for (WorkOrder job : acc.WorkOrders) {
                System.debug('~~~~ AccountLifetimeRollupServiceTest::testLifetimeRollup: job - ' + job);
            }
        }

        //check grandparent
        System.assertEquals(20, [SELECT Id FROM Account 
                                    WHERE RecordType.DeveloperName='Parent'
                                        AND Lifetime_Total_Revenue__c=10000 
                                        AND Lifetime_Total_Revenue_Children__c=520000
                                        AND Lifetime_Contracted_Sales__c=10000
                                        AND Lifetime_Contracted_Sales_Children__c=520000
                                        AND Lifetime_Open_Collections__c=10000
                                        AND Lifetime_Open_Collections_Children__c=520000
                                        AND Lifetime_Number_of_Jobs__c=3
                                        AND Lifetime_Number_of_Jobs_Children__c=9].size(), 'Grandparent didn\'t calculate correctly');

        //check parent1
        System.assertEquals(20, [SELECT Id FROM Account 
                                    WHERE RecordType.DeveloperName='Parent'
                                        AND Lifetime_Total_Revenue__c=10000 
                                        AND Lifetime_Total_Revenue_Children__c=500000
                                        AND Lifetime_Contracted_Sales__c=10000
                                        AND Lifetime_Contracted_Sales_Children__c=500000
                                        AND Lifetime_Open_Collections__c=10000
                                        AND Lifetime_Open_Collections_Children__c=500000
                                        AND Lifetime_Number_of_Jobs__c=3
                                        AND Lifetime_Number_of_Jobs_Children__c=3].size(), 'Parent1 didn\'t calculate correctly');

        //check parent2
        System.assertEquals(20, [SELECT Id FROM Account 
                                    WHERE RecordType.DeveloperName='Account'
                                        AND Lifetime_Total_Revenue__c=10000 
                                        AND Lifetime_Total_Revenue_Children__c=0
                                        AND Lifetime_Contracted_Sales__c=10000
                                        AND Lifetime_Contracted_Sales_Children__c=0
                                        AND Lifetime_Open_Collections__c=10000
                                        AND Lifetime_Open_Collections_Children__c=0
                                        AND Lifetime_Number_of_Jobs__c=3
                                        AND Lifetime_Number_of_Jobs_Children__c=0].size(), 'Parent2 didn\'t calculate correctly');

        //check child
        System.assertEquals(20, [SELECT Id FROM Account 
                                    WHERE RecordType.DeveloperName='Account'
                                        AND Lifetime_Total_Revenue__c=500000 
                                        AND Lifetime_Total_Revenue_Children__c=0
                                        AND Lifetime_Contracted_Sales__c=500000
                                        AND Lifetime_Contracted_Sales_Children__c=0
                                        AND Lifetime_Open_Collections__c=500000
                                        AND Lifetime_Open_Collections_Children__c=0
                                        AND Lifetime_Number_of_Jobs__c=3
                                        AND Lifetime_Number_of_Jobs_Children__c=0].size(), 'Child didn\'t calculate correctly');
                                        
    }
}