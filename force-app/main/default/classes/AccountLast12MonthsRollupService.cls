/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-12-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AccountLast12MonthsRollupService {
    public static String TIER1 = 'Tier 1';
    public static String TIER2 = 'Tier 2';
    public static String TIER3 = 'Tier 3';
    public static String TIER4 = 'Tier 4';
    public static String CLIENT = 'Client';
    public static Integer TIER_1_JOB_COUNT_MIN = 48;
    public static Integer TIER_2_JOB_COUNT_MIN = 24;
    public static Integer TIER_3_JOB_COUNT_MIN = 12;
    public static Decimal TIER_1_CONTRACT_AMOUNT_MIN = 1000000;
    public static Decimal TIER_2_CONTRACT_AMOUNT_MIN = 500000;
    public static Decimal TIER_3_CONTRACT_AMOUNT_MIN = 100000;
    private static boolean executeAgain = true;

    public static void rollUpJobsOnAccounts(List<Account> accLst) {
        Set<Id> parentIds = new Set<Id>();

        //Rollup and Calculate 12 Month Summaries and Tiers
        Map<Id, AccountSummary> mapSummaryByAccId = get12MonthRollups(accLst);
        List<Account> accUpdLst  = calculate12MonthSummariesAndTiers(mapSummaryByAccId);

        //get parentIds to determine if we need to execute this method again to traverse up the account hiearchy
        for (AccountSummary summaryRec : mapSummaryByAccId.values()) {
            if (summaryRec.parentId != null) {
                parentIds.add(summaryRec.parentId);
            }
        }

        //update accounts
        if (!accUpdLst.isEmpty()) {
            for (Account acc : accUpdLst) {
                System.debug('~~~~ AccountLast12MonthsRollupService::get12MonthRollups: records to update from accUpdLst - '+acc);                
            }
            update accUpdLst;
            executeAgain = parentIds.isEmpty() ? false : true;
            if (executeAgain)
                //call same method recursively if there are parent accounts, to traverse up the tree
                rollUpJobsOnAccounts([SELECT Id, Name, ParentId, Last_12_Months_Contracted_Sales__c, Last_12_Months_Contracted_Sales_Children__c, Last_12_Months_Contracted_Sales_All__c, Last_12_Months_Number_of_Jobs__c, Last_12_Months_Number_of_Jobs_Children__c, Last_12_Months_Number_of_Jobs_All__c, Tier__c, Tier_Override__c, Last_Modified_Tier_By__c, Last_Date_Tier_Set__c, RecordTypeId, RecordType.DeveloperName FROM Account WHERE ID IN: parentIds AND RecordType.DeveloperName In ('Parent', 'Account')]); 
        }
    }

    private static Map<Id, AccountSummary> get12MonthRollups(List<Account> accLst){
        Map<Id, AccountSummary> mapSummaryByAccId = new Map<Id, AccountSummary>();

        for (Account acc : accLst) {
            mapSummaryByAccId.put(acc.Id, new AccountSummary(acc));
            System.debug('~~~~ AccountLast12MonthsRollupService::get12MonthRollups:acc - '+acc);
        }

        //Get Account and related Last 12 Months of Jobs total contracted Sales and Number of Jobs
        for (AggregateResult sumAccByJobs : [SELECT AccountId, SUM(ROM_Contracted_Sales__c) Last12MonthsContractedSales, COUNT(Id) Last12MonthsNumberOfJobs FROM WorkOrder 
                                                WHERE AccountId IN: mapSummaryByAccId.keySet()  
                                                    AND CreatedDate >= LAST_N_MONTHS:12
                                                    AND ROM_Contracted_Sales__c > 0
                                                    AND Status IN ('Pre-production','In Progress','Work Complete','AR Pending','AP Pending','Closed')
                                                    AND Account.RecordType.DeveloperName In ('Parent', 'Account')
                                                GROUP BY AccountId ]) {
            System.debug('~~~~ AccountLast12MonthsRollupService::get12MonthRollups: sumAccByJobs - ' + sumAccByJobs); 

            Id accId = (Id)sumAccByJobs.get('AccountId');  
            AccountSummary summaryRec = mapSummaryByAccId.get(accId);
            summaryRec.last12MonthsContractedSalesOfThis = sumAccByJobs.get('Last12MonthsContractedSales') != null ? (Decimal)sumAccByJobs.get('Last12MonthsContractedSales') : 0;
            summaryRec.last12MonthsContractedSalesOfThisAndChildren = summaryRec.last12MonthsContractedSalesOfThis;

            summaryRec.last12MonthsNumberOfJobs = sumAccByJobs.get('Last12MonthsNumberOfJobs') != null ? Integer.valueOf(sumAccByJobs.get('Last12MonthsNumberOfJobs')) : 0;
            summaryRec.last12MonthsNumberOfJobsAndChildJobs = summaryRec.last12MonthsNumberOfJobs;

            System.debug('~~~~ AccountLast12MonthsRollupService::get12MonthRollups: accId - ' + accId + ', summaryRec - ' + summaryRec); 
        }

        //Get Account's Child Account's Last 12 Months of Job Contracted Sales and Number of Jobs
        for (AggregateResult sumAccByAccount : [SELECT ParentId, SUM(Last_12_Months_Contracted_Sales_All__c) Last12MonthsContractedSalesAll, SUM(Last_12_Months_Number_of_Jobs_All__c) Last12MonthsNumberOfJobsAll 
                                                FROM Account 
                                                WHERE ParentId IN: mapSummaryByAccId.keySet()  
                                                    AND RecordType.DeveloperName In ('Parent', 'Account')
                                                    AND Parent.RecordType.DeveloperName In ('Parent', 'Account')
                                                GROUP BY ParentId ]) {
            Id accId = (Id)sumAccByAccount.get('ParentId'); 
            System.debug('~~~~ AccountLast12MonthsRollupService::get12MonthRollups: sumAccByAccount - '+ sumAccByAccount); 
            AccountSummary summaryRec = mapSummaryByAccId.get(accId);
            summaryRec.last12MonthsContractedSalesOfChildren = sumAccByAccount.get('Last12MonthsContractedSalesAll') != null ? (Decimal)sumAccByAccount.get('Last12MonthsContractedSalesAll') : 0;
            summaryRec.last12MonthsContractedSalesOfThisAndChildren += summaryRec.last12MonthsContractedSalesOfChildren; 
            summaryRec.last12MonthsNumberOfChildJobs = sumAccByAccount.get('Last12MonthsNumberOfJobsAll') != null ? Integer.valueOf(sumAccByAccount.get('Last12MonthsNumberOfJobsAll')) : 0;
            summaryRec.last12MonthsNumberOfJobsAndChildJobs += summaryRec.last12MonthsNumberOfChildJobs;
            System.debug('~~~~ AccountLast12MonthsRollupService::get12MonthRollups: accId as ParentId - ' + accId + ', summaryRec - ' + summaryRec); 
        }

        //set tier calculation
        for (AccountSummary summaryRec : mapSummaryByAccId.values()) {
            //Tier calculations and audit
            summaryRec.calculatedTier = calculateTier(summaryRec.last12MonthsNumberOfJobsAndChildJobs, summaryRec.last12MonthsContractedSalesOfThisAndChildren); 
            summaryRec.lastDateCalculatedTier = Datetime.now();
            if (!summaryRec.tierOverride) {
                summaryRec.tier = summaryRec.calculatedTier;
                summaryRec.lastDateTierSet = summaryRec.lastDateCalculatedTier;
                summaryRec.lastModifiedTierBy = UserInfo.getUserId();
            } 

            System.debug('~~~~ AccountLast12MonthsRollupService::get12MonthRollups: summaryRec during tier calculation - ' + summaryRec); 
        }

        return mapSummaryByAccId;
    }

    private static List<Account> calculate12MonthSummariesAndTiers(Map<Id, AccountSummary> mapSummaryByAccId) {
        List<Account> accUpdLst = new List<Account>();

        //Calculate summaries for accounts
        for (Id accId : mapSummaryByAccId.keySet()) {
            Account acc = new Account(Id=accId); 
            AccountSummary summaryRec = mapSummaryByAccId.get(accId);
            
            //Tier calculations and audit
            acc.Calculated_Tier__c = summaryRec.calculatedTier;
            acc.Last_Date_Calculated_Tier__c = summaryRec.lastDateCalculatedTier;

            if (!summaryRec.tierOverride) {
                acc.Tier__c = summaryRec.tier;
                acc.Last_Date_Tier_Set__c = summaryRec.lastDateTierSet;
                acc.Last_Modified_Tier_By__c = summaryRec.lastModifiedTierBy;
            }    
            
            //Last 12 Months of Contracted Sales
            acc.Last_12_Months_Contracted_Sales__c = summaryRec.last12MonthsContractedSalesOfThis;
            acc.Last_12_Months_Contracted_Sales_Children__c = summaryRec.last12MonthsContractedSalesOfChildren;
            acc.Last_12_Months_Contracted_Sales_All__c = summaryRec.last12MonthsContractedSalesOfThisAndChildren;

            //Last 12 Months of Jobs
            acc.Last_12_Months_Number_of_Jobs__c = summaryRec.last12MonthsNumberOfJobs;
            acc.Last_12_Months_Number_of_Jobs_Children__c = summaryRec.last12MonthsNumberOfChildJobs;
            acc.Last_12_Months_Number_of_Jobs_All__c = summaryRec.last12MonthsNumberOfJobsAndChildJobs;

            System.debug('~~~~ AccountLast12MonthsRollupService::calculate12MonthSummariesAndTiers:acc - ' + acc);
            System.debug('~~~~ AccountLast12MonthsRollupService::calculate12MonthSummariesAndTiers: \n~~~~ job num: ' + acc.Last_12_Months_Number_of_Jobs__c + '\n~~~~ job num children: ' + acc.Last_12_Months_Number_of_Jobs_Children__c + '\n~~~~ job num all: ' + acc.Last_12_Months_Number_of_Jobs_All__c);
            accUpdLst.add(acc);
        }

        return accUpdLst;
    }

    @TestVisible 
    private static String calculateTier(Integer jobCount, Decimal contractAmount) {
        String tier = '';
        
        if(jobCount >= TIER_1_JOB_COUNT_MIN || contractAmount >= TIER_1_CONTRACT_AMOUNT_MIN){
            tier = TIER1;
        }else if((jobCount >= TIER_2_JOB_COUNT_MIN && jobCount < TIER_1_JOB_COUNT_MIN) || (contractAmount >= TIER_2_CONTRACT_AMOUNT_MIN && contractAmount < TIER_1_CONTRACT_AMOUNT_MIN)){
            tier = TIER2;
        }else if((jobCount >= TIER_3_JOB_COUNT_MIN && jobCount < TIER_2_JOB_COUNT_MIN) || (contractAmount >= TIER_3_CONTRACT_AMOUNT_MIN && contractAmount < TIER_2_CONTRACT_AMOUNT_MIN )){
            tier = TIER3;
        }else if(jobCount < TIER_3_JOB_COUNT_MIN ||  contractAmount < TIER_3_CONTRACT_AMOUNT_MIN){
            tier = TIER4;
        }
        
        return tier;
    }

    private class AccountSummary {
        public AccountSummary(Account acc) {
            this.accountId=acc.Id;
            this.tier = acc.Tier__c;
            this.tierOverride = acc.Tier_Override__c;
            this.lastModifiedTierBy = acc.Last_Modified_Tier_By__c;
            this.lastDateTierSet = acc.Last_Date_Tier_Set__c;
            this.parentId = acc.ParentId;

            //last 12 Months of Contracted Sales
            this.last12MonthsContractedSalesOfThis = 0;
            this.last12MonthsContractedSalesOfChildren = 0;
            this.last12MonthsContractedSalesOfThisAndChildren = 0;

            //last 12 Months of Number of Jobs
            this.last12MonthsNumberOfJobs = 0;
            this.last12MonthsNumberOfChildJobs = 0;
            this.last12MonthsNumberOfJobsAndChildJobs = 0;
                
        }
        public String accountId;

        //last 12 Months of Contracted Sales
        public Decimal last12MonthsContractedSalesOfThis = 0;
        public Decimal last12MonthsContractedSalesOfChildren = 0;
        public Decimal last12MonthsContractedSalesOfThisAndChildren = 0;

        //last 12 Months of Number of Jobs
        public Integer last12MonthsNumberOfJobs = 0;
        public Integer last12MonthsNumberOfChildJobs = 0;
        public Integer last12MonthsNumberOfJobsAndChildJobs = 0;

        //tiers
        public String tier=null;
        public String calculatedTier=null;
        public Boolean tierOverride = false;

        //audits
        public String lastModifiedTierBy=null;
        public Datetime lastDateTierSet=null;
        public Datetime lastDateCalculatedTier=null;

        //parent
        public String parentId=null;
    }
}