/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-19-2023
 * @last modified by  : Terri Jiles
**/
public with sharing class AccountLifetimeRollupService {  
    private static boolean executeAgain = true;

    public static void rollUpJobsOnAccounts(List<Account> accLst) {
        Map<Id, AccountSummary> mapSummaryByAccId = getRollupLifetimeSummariesForAccounts(accLst);
        List<Account> accUpdLst = setRollupLifetimeSummariesOnAccounts(mapSummaryByAccId);

        //update accounts with lifetime summaries
        if (!accUpdLst.isEmpty()) {
            update accUpdLst;

            //get parents
            Set<Id> parentIds = new Set<Id>();
            for (AccountSummary summaryRec : mapSummaryByAccId.values()) {
                if (summaryRec.ParentId != null) 
                    parentIds.add(summaryRec.ParentId);
            }

            //determine if more parent accounts to process higher up the hierarchy
            if (!parentIds.isEmpty())
                executeAgain = true;

            //process a level up recursively using parents as children           
            if (executeAgain) {
                rollUpJobsOnAccounts([SELECT Id, Name, ParentId 
                                        FROM Account 
                                        WHERE ID IN: parentIds 
                                            AND RecordType.DeveloperName IN ('Parent', 'Account')]); 
            }
        }
    }

    private static Map<Id, AccountSummary> getRollupLifetimeSummariesForAccounts(List<Account> accLst) {
        Map<Id, AccountSummary> mapSummaryByAccId = new Map<Id, AccountSummary>();
        
        //Initialize account summaries
        for (Account acc : accLst) {
            mapSummaryByAccId.put(acc.Id, new AccountSummary(acc));
        }
 
        //Rollup lifetime calculations of all jobs on an account
        for (AggregateResult sumAccByJobs : [SELECT AccountId, SUM(Paid_to_Date__c) Lifetime_Total_Revenue__c, SUM(AR_Balance__c) Lifetime_Open_Collections__c, COUNT(Id) Lifetime_Number_of_Jobs__c, SUM(ROM_Contracted_Sales__c) Lifetime_Contracted_Sales__c 
                                                FROM WorkOrder 
                                                WHERE AccountId IN: mapSummaryByAccId.keySet()  
                                                    AND Account.RecordType.DeveloperName IN ('Parent', 'Account')
                                                    AND Status IN ('Pre-production','In Progress','Work Complete','AR Pending','AP Pending','Closed')
                                                    AND (AR_Balance__c > 0 OR Paid_to_Date__c > 0 OR ROM_Contracted_Sales__c > 0)
                                                GROUP BY AccountId ]) {
            Id accId = (Id)sumAccByJobs.get('AccountId');  
            AccountSummary summaryRec = mapSummaryByAccId.get(accId);
            summaryRec.totalLifetimeRevenueOfThis = sumAccByJobs.get('Lifetime_Total_Revenue__c') != null ? (Decimal)sumAccByJobs.get('Lifetime_Total_Revenue__c') : 0;
            summaryRec.openCollections = sumAccByJobs.get('Lifetime_Open_Collections__c') != null ? (Decimal)sumAccByJobs.get('Lifetime_Open_Collections__c') : 0 ;
            summaryRec.numberOfJobs = sumAccByJobs.get('Lifetime_Number_of_Jobs__c') != null ? Integer.valueOf(sumAccByJobs.get('Lifetime_Number_of_Jobs__c')): 0;
            summaryRec.lifetimeContractedSalesOfThis = sumAccByJobs.get('Lifetime_Contracted_Sales__c') != null ? (Decimal)sumAccByJobs.get('Lifetime_Contracted_Sales__c') : 0;
        }

        //Rollup lifetime calculations of all child accounts on an account
        for (AggregateResult sumAccByJobs : [SELECT ParentId, SUM(Lifetime_Contracted_Sales__c) Lifetime_Contracted_Sales__c, SUM(Lifetime_Contracted_Sales_Children__c) Lifetime_Contracted_Sales_Children__c, SUM(Lifetime_Total_Revenue__c) Lifetime_Total_Revenue__c, SUM(Lifetime_Total_Revenue_Children__c) Lifetime_Total_Revenue_Children__c, SUM(Lifetime_Number_of_Jobs__c) Lifetime_Number_of_Jobs__c, SUM(Lifetime_Number_of_Jobs_Children__c) Lifetime_Number_of_Jobs_Children__c, SUM(Lifetime_Open_Collections__c) Lifetime_Open_Collections__c, SUM(Lifetime_Open_Collections_Children__c) Lifetime_Open_Collections_Children__c 
                                                    FROM Account 
                                                    WHERE ParentId IN: mapSummaryByAccId.keySet()  
                                                        AND RecordType.DeveloperName IN ('Parent', 'Account')
                                                        AND Parent.RecordType.DeveloperName IN ('Parent', 'Account')
                                                    GROUP BY ParentId ]) {
            Id accId = (Id)sumAccByJobs.get('ParentId');  
            //System.debug('~~~~ AccountRollupService::rollUpJobsOnAccounts: recId ' + recId);
            AccountSummary summaryRec = mapSummaryByAccId.get(accId);
            summaryRec.totalLifetimeRevenueOfChildren = (sumAccByJobs.get('Lifetime_Total_Revenue__c') != null ? (Decimal)sumAccByJobs.get('Lifetime_Total_Revenue__c') : 0) + (sumAccByJobs.get('Lifetime_Total_Revenue_Children__c') != null ? (Decimal)sumAccByJobs.get('Lifetime_Total_Revenue_Children__c') : 0);
            summaryRec.openCollectionsOfChildren = (sumAccByJobs.get('Lifetime_Open_Collections__c') != null ? (Decimal)sumAccByJobs.get('Lifetime_Open_Collections__c') : 0) + (sumAccByJobs.get('Lifetime_Open_Collections_Children__c') != null ? (Decimal)sumAccByJobs.get('Lifetime_Open_Collections_Children__c') : 0);
            summaryRec.numberOfChildJobs =  (sumAccByJobs.get('Lifetime_Number_of_Jobs__c') != null ? Integer.valueOf(sumAccByJobs.get('Lifetime_Number_of_Jobs__c')) : 0)  + (sumAccByJobs.get('Lifetime_Number_of_Jobs_Children__c') != null ? Integer.valueOf(sumAccByJobs.get('Lifetime_Number_of_Jobs_Children__c')) : 0); 
            summaryRec.lifetimeContractedSalesOfChildren =  (sumAccByJobs.get('Lifetime_Contracted_Sales__c') != null ? (Decimal)sumAccByJobs.get('Lifetime_Contracted_Sales__c') : 0)  + (sumAccByJobs.get('Lifetime_Contracted_Sales_Children__c') != null ? (Decimal)sumAccByJobs.get('Lifetime_Contracted_Sales_Children__c') : 0);
        }

        return mapSummaryByAccId;
    }

    private static List<Account> setRollupLifetimeSummariesOnAccounts(Map<Id, AccountSummary> mapSummaryByAccId) {
        List<Account> accUpdLst = new List<Account>();

        //set lifetime summaries on account records
        for (Id accId : mapSummaryByAccId.keySet()) {
            Account acc = new Account(Id=accId); 
            AccountSummary summaryRec = mapSummaryByAccId.get(accId);  
            acc.Lifetime_Total_Revenue__c = summaryRec.totalLifetimeRevenueOfThis;
            acc.Lifetime_Total_Revenue_Children__c = summaryRec.totalLifetimeRevenueOfChildren;
            acc.Lifetime_Contracted_Sales__c = summaryRec.lifetimeContractedSalesOfThis;
            acc.Lifetime_Contracted_Sales_Children__c = summaryRec.lifetimeContractedSalesOfChildren;
            acc.Lifetime_Open_Collections__c = summaryRec.openCollections;
            acc.Lifetime_Open_Collections_Children__c = summaryRec.openCollectionsOfChildren;
            acc.Lifetime_Number_of_Jobs__c = summaryRec.numberOfJobs;
            acc.Lifetime_Number_of_Jobs_Children__c = summaryRec.numberOfChildJobs;
            accUpdLst.add(acc);
        }
        
        return accUpdLst;
    }

    private class AccountSummary {
        public AccountSummary(Account acc) {
            this.accountId=acc.Id;
            this.totalLifetimeRevenueOfThis=0;
            this.totalLifetimeRevenueOfChildren=0;
            this.lifetimeContractedSalesOfThis=0;
            this.lifetimeContractedSalesOfChildren=0;
            this.openCollections=0;
            this.openCollectionsOfChildren=0;
            this.numberOfJobs=0;
            this.numberOfChildJobs=0;
            this.parentId=acc.ParentId;
        }
		
        public String accountId;
        public Decimal totalLifetimeRevenueOfThis = 0;
        public Decimal totalLifetimeRevenueOfChildren = 0;
        public Decimal lifetimeContractedSalesOfThis=0;
        public Decimal lifetimeContractedSalesOfChildren=0;        
        public Decimal openCollections = 0;
        public Decimal openCollectionsOfChildren = 0;
        public Integer numberOfJobs = 0;
        public Integer numberOfChildJobs = 0;
        public String parentId = null; 
    }
}