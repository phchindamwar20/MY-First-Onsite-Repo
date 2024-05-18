/**
 * @description       : This class provides the business logic for
 *                      1. Initializing job commissions
 *                      2. Syncing BD/ECs
 *                      covers stories STAR-6037, STAR-6264
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-17-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class CommissionService {
    public void createJobCommissions(List<WorkOrder> jobLst) {
        //configure job commissions
        List<Job_Commission__c> jobComLst = configureJobCommissions(jobLst);
        
        Map<String, Set<Database.Error>> errorMsgsByJcId = DynamicApexService.createRecs(jobComLst, false);

        //log errors, if any
        //TODO:

        //update jobs
        Map<Id, WorkOrder> jobById= new Map<Id, WorkOrder>(linkJobCommissionToJob(jobComLst));
        Map<String, Set<Database.Error>> errorMsgsByJobId = DynamicApexService.updateRecs(jobById, false);

        //log errors, if any
        //TODO:
        
    }

       
   public void  syncBdECs(List<Job_Commission__c> jobComLst) {
        List<Job_Commission__c> updateJobComLst = new List<Job_Commission__c>();
        List<Employee_Commission__c> insertEmpComLst = new List<Employee_Commission__c>();
        List<Employee_Commission__c> updateEmpComLst = new List<Employee_Commission__c>();
        List<Employee_Commission__c> deleteEmpComLst = new List<Employee_Commission__c>();
        //get Commissionable Sales BDs on Jobs, set up ECs for upsert on open Job Commissions on open job commissions
        for (Job_Commission__c jobCom : [SELECT Id, Custom_Splits__c, Commission_Status__c, Commission_Close_Date__c, Commission_Payment_Date__c, Job__c, Job__r.Job_Commission__r.Commission_Close_Date__c,
                                        Job_Amount__c, Actual_Commissionable__c, Default_Commissionable__c, Number_of_Commissionable_Employees__c, 
                                        Actual_Deposit_1st_Payment_Incentive__c, Actual_Quick_Collection_Incentive__c, Actual_Slow_Collection_Incentive__c,
                                        Default_Deposit_1st_Payment_Incentive__c, Default_Quick_Collection_Incentive__c, Default_Slow_Collection_Incentive__c,
                                        Job__r.BD_Account_Manager__c, Job__r.BD_Account_Manager__r.Sales_Commissionable_User__c, Job__r.BD_Account_Manager__r.ADP_Associate_OID__c, Margin_Tier__c,
                                        Job__r.BD_Account_Manager_2__c, Job__r.BD_Account_Manager_2__r.Sales_Commissionable_User__c, Job__r.BD_Account_Manager_2__r.ADP_Associate_OID__c,
                                        Job__r.BD_Account_Manager_3__c, Job__r.BD_Account_Manager_3__r.Sales_Commissionable_User__c, Job__r.BD_Account_Manager_3__r.ADP_Associate_OID__c,
                                        (SELECT Id, Employee_Commission_ID__c, Employee__c, Employee__r.Sales_Commissionable_User__c, Job__c, Job_Commission__c, Status__c, 
                                            Commission_Payment_Date__c, Individual_Split_Percentage__c FROM Employee_Commissions__r)
                                        FROM Job_Commission__c WHERE Id IN: jobComLst AND
                                        Custom_Splits__c =: SalesIncentivePlanConstants.NO AND Commission_Status__c=:SalesIncentivePlanConstants.JC_STATUS_OPEN]) {
            
            Boolean isSyncBds = isEcsEligibleForSync(jobCom);
            
            //Only process open job commissions
            if (isSyncBds == true) {
                //get commissionable sales BDs from job
                Set<Id> salesBDs = getJobCommissionableBds(jobCom);
                Set<Id> empKeeps = new Set<Id>();
                List<Employee_Commission__c> empComKeepLst = new List<Employee_Commission__c>();
                List<Employee_Commission__c> empComDelLst = new List<Employee_commission__c>();
                
                for (Employee_Commission__c ec : jobCom.Employee_Commissions__r) {
                    //keep - update
                    if (salesBDs.contains(ec.Employee__c)) {
                        empComKeepLst.add(ec);
                        empKeeps.add(ec.Employee__c);
                    } else {
                    //remove - delete
                        empComDelLst.add(ec);
                    }
                }

                //keep - insert
                Set<Id> empAdds = new Set<Id>(salesBDs);
                empAdds.removeAll(empKeeps);
                for(Id empToAdd : empAdds) {
                    empComKeepLst.add(new Employee_Commission__c(Job_Commission__c=jobCom.Id, Job__c=jobCom.Job__c, Employee__c=empToAdd, Individual_Split_Percentage__c=0.0000));
                }

                //calculate auto splits
                empComKeepLst = autoCalculateSplits(empComKeepLst);
                
                //add to processing list
                Integer numOfEcs = empComKeepLst == null ? 0 : empComKeepLst.size();
                updateJobComLst.add(new Job_Commission__c(Id=jobCom.Id, Number_of_Commissionable_Employees__c=numOfEcs, BDs_Synced_to_ECs__c=isSyncBds, Margin_Tier__c=jobCom.Margin_Tier__c));
                if (empComKeepLst != null) {
                    for (Employee_Commission__c ec : empComKeepLst) {
                        if (ec?.Id != null) {
                            updateEmpComLst.add(ec);
                        } else {
                            insertEmpComLst.add(ec);
                        }
                    }
                }
                deleteEmpComLst.addAll(empComDelLst);
            } else {
                //for the job commission number of commissionable employees remain the same, Synced = false
                updateJobComLst.add(new Job_Commission__c(Id=jobCom.Id, Number_of_Commissionable_Employees__c=jobCom.Number_of_Commissionable_Employees__c, BDs_Synced_to_ECs__c=isSyncBds, Margin_Tier__c=jobCom.Margin_Tier__c));
            }
        }

        //update multiplier information on job commission
        updateJobComLst = CommissionMultiplierConfigurationService.setMultiplierInfo(updateJobComLst);

        //save records
        saveSyncRecords(updateJobComLst, insertEmpComLst, updateEmpComLst, deleteEmpComLst);
    }

    public void updateCommissions(List<Job_Commission__c> jobComLst) {
        Map<Id, List<Database.Error>> errorLstByJobId = new Map<Id, List<Database.Error>>();
        List<Job_Commission__c> jobCommissionLst = new List<Job_Commission__c>();

        //refresh financial fields from job
        for (WorkOrder job : [SELECT Id, Bad_Debt__c, Date_of_First_Payment__c, ROM_Contracted_Sales__c, Expected_Margin__c,
                                        Final_Margin__c, In_Collections__c, Legal__c, House_Account__c, Status, Start_Date__c,
                                        Work_Complete_Date__c, First_Payment_Amount__c, Date_Fully_Collected__c, Close_Date__c,
                                        Job_Commission__c, Job_Commission__r.Number_of_Commissionable_Employees__c
                                FROM WorkOrder WHERE Job_Commission__c IN: jobComLst]) {
            Job_Commission__c jobCom = setFinancialFields(job);
            jobCom.Id=job.Job_Commission__c;
            jobCom.Number_of_Commissionable_Employees__c = job.Job_Commission__r.Number_of_Commissionable_Employees__c;
            jobCom = setStatusAndCommissionCloseDate(job, jobCom);
        }
        
        //Get commission tier and associated parameters
        jobCommissionLst = CommissionConfigurationService.setTiers(jobCommissionLst);
        
        //Get Multiplier Info based on number of commissionable BDs
        jobCommissionLst = CommissionMultiplierConfigurationService.setMultiplierInfo(jobCommissionLst);

        //calculate job commission
        jobCommissionLst = calculateJobCommission(jobCommissionLst);

        //update job coms
        Database.SaveResult[] updJcResultLst = Database.update(jobCommissionLst, false);
        errorLstByJobId = DynamicApexService.getErrorsFromResult(updJcResultLst,  jobCommissionLst, 'Job__c', errorLstByJobId);

        //publish errors
        if(!errorLstByJobId.isEmpty()) {
            BoltLogPublisherService.publishErrorsByJobId(errorLstByJobId, 'CommissionService', 'updateCommissions', SalesIncentivePlanConstants.BOLT_LOG_RT_Name);
        }
    }

    public List<Job_Commission__c> configureJobCommissions(List<WorkOrder> jobLst) {
        List<Job_Commission__c> jobCommissionLst = new List<Job_Commission__c>();
        //Get Commissionable Sales BDs
        for (WorkOrder job : [SELECT Id, BD_Account_Manager__c, BD_Account_Manager__r.Sales_Commissionable_User__c,
                                        BD_Account_Manager_2__c, BD_Account_Manager_2__r.Sales_Commissionable_User__c,
                                        BD_Account_Manager_3__c, BD_Account_Manager_3__r.Sales_Commissionable_User__c,
                                        Bad_Debt__c, Date_of_First_Payment__c, ROM_Contracted_Sales__c, Expected_Margin__c,
                                        Final_Margin__c, In_Collections__c, Legal__c, House_Account__c, Status, Start_Date__c,
                                        Work_Complete_Date__c, First_Payment_Amount__c, Date_Fully_Collected__c, Close_Date__c,
                                        Job_Commission__c, (SELECT Id FROM Job_Commissions__r)
                                FROM WorkOrder WHERE Id IN: jobLst]) {

            if (job.Job_Commission__c == null && job.Job_Commissions__r.isEmpty()) {
                //Configure Job Commission with fianical commission fields from job
                Job_Commission__c jobCom =  setFinancialFields(job);

                //Get Number of Commissionable Sales BDs
                Integer numCommissionableBds = 0;
                if (job?.BD_Account_Manager__r.Sales_Commissionable_User__c) {
                    numCommissionableBds++;
                }
                if  (job?.BD_Account_Manager_2__r.Sales_Commissionable_User__c) {
                    numCommissionableBds++;
                }
                if (job?.BD_Account_Manager_3__r.Sales_Commissionable_User__c) {
                    numCommissionableBds++;
                }
                jobCom.Number_of_Commissionable_Employees__c = numCommissionableBds;
                jobCommissionLst.add(jobCom);

                //set status and commission close date, if applicable
                jobCom = setStatusAndCommissionCloseDate(job, jobCom);
            }
        }

        //Get commission tier and associated parameters
        jobCommissionLst = CommissionConfigurationService.setTiers(jobCommissionLst);
        
        //Get Multiplier Info based on number of commissionable BDs
        jobCommissionLst = CommissionMultiplierConfigurationService.setMultiplierInfo(jobCommissionLst);

        //calculate job commission
        jobCommissionLst = calculateJobCommission(jobCommissionLst);


        return jobCommissionLst;
    }

    private Job_Commission__c setFinancialFields(WorkOrder job){
        Job_Commission__c jobCom = new Job_Commission__c(Job__c=job.Id);

        //Configure Job Commission with fianical commission fields from job
        Map<String,Object> valueByName = new Map<String, Object>();
        valueByName.put('varR_Job', job); //using map as input parameter because the query to get BDs and related info doesn't include all fields needed
        valueByName.put('varR_JobCommission', jobCom);
        Flow.Interview.Job_Subflow_SetFinanicalFieldsOnJobCommission configJobCom = new Flow.Interview.Job_Subflow_SetFinanicalFieldsOnJobCommission(valueByName);
        configJobCom.start();
        jobCom=configJobCom.varR_JobCommission;

        return jobCom;
    }

    @TestVisible 
    private List<Job_Commission__c> calculateJobCommission(List<Job_Commission__c> jobCommissionLst) {
        //calculate job commission
        List<Job_Commission__c> jobCommissionCalLst = new List<Job_Commission__c>();
        for (Job_Commission__c jobCom : jobCommissionLst) {
            Map<String,Object> valueByName = new map<String, Object>();
            valueByName.put('varR_JobCommission', jobCom);
            Flow.Interview.JobCommissionCal_Subflow_CalculateJobCommission calJobCom = new Flow.Interview.JobCommissionCal_Subflow_CalculateJobCommission(valueByName);
            calJobCom.start();
            jobCom=calJobCom.varR_JobCommission;
            System.debug('~~~~ CommissionService::configureJobCommission: jobCom - ' + jobCom);
            jobCommissionCalLst.add(jobCom);
        }

        return jobCommissionCalLst;
    }

    private Job_Commission__c setStatusAndCommissionCloseDate(WorkOrder job, Job_Commission__c jobCom) {
        if (job.Close_Date__c != null ) {
            jobCom.Commission_Close_Date__c = job.Close_Date__c;
        }
        return jobCom;
    }

    public List<WorkOrder> linkJobCommissionToJob(List<Job_Commission__c> jobCommissionLst) {
        List<WorkOrder> jobLst = new List<WorkOrder>();

        for (Job_Commission__c jobCom : [SELECT Id, Job__c FROM Job_Commission__c WHERE Id IN: jobCommissionLst]) {
            jobLst.add(new WorkOrder(Id=jobCom.Job__c, Job_Commission__c=jobCom.Id));
        }

        return jobLst;
    }

    private Set<Id> getJobCommissionableBds(Job_Commission__c jobCom) {
       Set<Id> salesBDs = new Set<Id>();

        if (jobCom.Job__r?.BD_Account_Manager__r.Sales_Commissionable_User__c) {
            salesBDs.add(jobCom.JOb__r.BD_Account_Manager__c);
        }
        if (jobCom.Job__r?.BD_Account_Manager_2__r.Sales_Commissionable_User__c) {
            salesBDs.add(jobCom.Job__r.BD_Account_Manager_2__c);
        }
        if (jobCom.Job__r?.BD_Account_Manager_3__r.Sales_Commissionable_User__c) {
            salesBDs.add(jobCom.Job__r.BD_Account_Manager_3__c);
        }

        return salesBDs;
    }

    @TestVisible
    private Boolean isEcsEligibleForSync(Job_Commission__c jobCom) {
        Boolean isJcOpened=JobCom.Commission_Status__c==SalesIncentivePlanConstants.JC_STATUS_OPEN ? true : false;
        Boolean isNotCustomSplits=jobCom.Custom_Splits__c == SalesIncentivePlanConstants.YES ? false : true;
        Boolean isNotPaid=true;
        Boolean isCommissionableSales=true;
        Boolean hasNoMoreThan3 =  jobCom?.Employee_Commissions__r.size() > 3 ? false : true;

        for (Employee_Commission__c ec : jobCom.Employee_Commissions__r) {
            if (ec.Employee__r.Sales_Commissionable_User__c==false) {
                isCommissionableSales=false;
            }
            if (ec.Status__c==SalesIncentivePlanConstants.EC_STATUS_PAID){
                isNotPaid=false;
            }
        }        
        return (isJcOpened && isNotCustomSplits && isNotPaid && isCommissionableSales && hasNoMoreThan3);
    }

    private List<Employee_Commission__c> autoCalculateSplits(List<Employee_Commission__c> empComLst) {
        Map<String,Object> valueByName = new Map<String, Object>();
        valueByName.put('varR_IncomingEmployeeCommissions', empComLst); 
        Flow.Interview.EmployeeCommissionCal_Subflow_CalculateAutoSplits autoSplitEmpComs = new Flow.Interview.EmployeeCommissionCal_Subflow_CalculateAutoSplits(valueByName);
        autoSplitEmpComs.start();
        empComLst=autoSplitEmpComs.varR_OutgoingEmployeeCommissions;
        return empComLst;
    }

    private void saveSyncRecords(List<Job_Commission__c> jobComUpdLst, List<Employee_Commission__c> empComInsLst, 
                                List<Employee_Commission__c> empComUpdLst, List<Employee_Commission__c> empComDelLst) {
        Map<Id, List<Database.Error>> errorLstByJobId = new Map<Id, List<Database.Error>>();

        //update Jcs
        Database.SaveResult[] updJcResultLst = Database.update(jobComUpdLst, false);
        errorLstByJobId = DynamicApexService.getErrorsFromResult(updJcResultLst,  jobComUpdLst, 'Job__c', errorLstByJobId);
        
        //remove ECs
        empComDelLst = removeRecsAssociatedWithErrorJobs(empComDelLst, errorLstByJobId.keySet(), 'Job__c');
        Database.DeleteResult[] delEcResultLst =  Database.delete(empComDelLst, false);
        errorLstByJobId = DynamicApexService.getErrorsFromDelResult(delEcResultLst,  empComDelLst, 'Job__c', errorLstByJobId);

        //insert ECs
        empComInsLst = removeRecsAssociatedWithErrorJobs(empComInsLst, errorLstByJobId.keySet(), 'Job__c');
        Database.SaveResult[] insEcResultLst = Database.insert(empComInsLst, false);
        errorLstByJobId = DynamicApexService.getErrorsFromResult(insEcResultLst,  empComInsLst, 'Job__c', errorLstByJobId);

        //update Ecs
        empComUpdLst = removeRecsAssociatedWithErrorJobs(empComUpdLst, errorLstByJobId.keySet(), 'Job__c');
        Database.SaveResult[] updEcResultLst = Database.update(empComUpdLst, false);
        errorLstByJobId = DynamicApexService.getErrorsFromResult(updEcResultLst,  empComUpdLst, 'Job__c', errorLstByJobId);

        //publish errors
        if(!errorLstByJobId.isEmpty()) {
            BoltLogPublisherService.publishErrorsByJobId(errorLstByJobId, 'CommissionService', 'saveSyncrecords', SalesIncentivePlanConstants.BOLT_LOG_RT_Name);
        }
    }

    @TestVisible
    private List<SObject> removeRecsAssociatedWithErrorJobs(List<SObject> recLst, Set<Id> errorJobIds, String field) {
        if (!errorJobIds?.isEmpty()) {
            List<SObject> remRecLst = new List<SObject>();
            for (SObject rec : recLst) {
                if (rec?.get(field) != null && errorJobIds.contains((Id)rec.get(field))) {
                    remRecLst.add(rec);
                }
            }

            for (SObject rec : remRecLst) {
                recLst.remove(recLst.indexOf(rec));
            }
        }

        return recLst;
    }
}