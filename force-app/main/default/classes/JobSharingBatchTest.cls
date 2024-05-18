/**
 * @File Name          : JobSharingBatchTest.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 09-21-2023
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/23/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 * 2.0    05/07/2024  Kiran K (CFS)               STAR-6569 removed unused Sage Fields
**/
@isTest
public without sharing class JobSharingBatchTest {
    @TestSetup
    static void makeData(){
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        DataAdmin__c dataAdmin = DataAdmin__c.getOrgDefaults();
        dataAdmin.TurnOffTrigger__c=true;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.TurnOffFlow__c=true;
        dataAdmin.SetupOwnerId=UserInfo.getOrganizationId();
        insert dataAdmin;

        Test.startTest();
        Account acc = (Account)TestFactory.createSObject(new Account(Name='House Account',  Status__c='Dormant', Drive_Down__c='No', National_Account__c='Yes', Contract_Type__c='MSA Only',Number_of_Active_Contracts__c=0, CurrencyIsoCode='USD'),
            'TestFactoryDefaults.AccountDefaults', true);
        System.debug(logginglevel.INFO, '~~~~~ After account insert');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());

        //SandboxTestData sbtd = new SandboxTestData();
     
        TestFactory.createUsers();
        createData();
        Test.stopTest();
                 

        dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=false;
        dataAdmin.TurnOffProcessBuilder__c=false;
        dataAdmin.TurnOffValidationRules__c=false;
        dataAdmin.TurnOffFlow__c=true;
        dataAdmin.SetupOwnerId=UserInfo.getOrganizationId();
        update dataAdmin;  
        System.debug(logginglevel.INFO, '~~~~~ After DataAdmin update');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());                 
    }

    @isTest
    static void batchTest() {
        Set<String> comboExpected = new Set<String>() ;
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        String errorMessage = '';
        Integer i=0;
        List<WorkOrder> jobInstLst = new List<WorkOrder>();
        List<Job_Sharing__C> jobSharInsLst = new List<Job_Sharing__c>();


        //setup test data
        System.assertEquals(0, [Select Id From WorkOrderShare WHERE RowCause='Manual'].size(), 'Shares not deleted');

        //test
        Test.startTest();
        Id result = Database.executeBatch(new JobSharingBatch(), 200);
        Test.stopTest();

        //get expected for jobs
        System.debug(logginglevel.INFO, '~~~~ expected');
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Manager__c, Project_Director__c, Senior_Project_Manager__c FROM WorkOrder]) {
            if (jobRec.BD_Account_Manager__c != null) {
                System.debug(logginglevel.INFO, '~~~ BD: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager__c);
            }
            if (jobRec.Project_Director__c != null) {
                System.debug(logginglevel.INFO, '~~~ PD: ' + jobRec.Id + '-' + jobRec.Project_Director__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Director__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Director__c);
            } 
            if (jobRec.Project_Manager__c != null) {
                System.debug(logginglevel.INFO, '~~~ PM: ' + jobRec.Id + '-' + jobRec.Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Manager__c);
            } 
            //STAR-4435          
            if (jobRec.Senior_Project_Manager__c != null) {
                System.debug(logginglevel.INFO, '~~~ PM: ' + jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Senior_Project_Manager__c);
            } 
        }

        //get expected for job sharing
        for (Job_Sharing__c js : [SELECT Job__c, User__c FROM Job_Sharing__c]) {
            System.debug(logginglevel.INFO, '~~~~ UR3: ' + js.Job__c + '-' + js.User__c);
            comboExpected.add(js.Job__c + '-' + js.User__c);
            jobIds.add(js.Job__c);
            userMatchedIds.add(js.User__c);
        }

        //get actual for both
        System.debug(logginglevel.INFO, '~~~~ Actual ');
        for (WorkOrderShare jobShare : [SELECT ParentId, UserOrGroupId FROM WorkOrderShare WHERE RowCause='Manual' AND AccessLevel='Edit' AND ParentId In: jobIds AND UserOrGroupId In: userMatchedIds]) {
            System.debug(logginglevel.INFO, '~~~~~' + jobShare.ParentId + '-' + jobShare.UserOrGroupId);
            comboActual.add(jobShare.ParentId + '-' + jobShare.UserOrGroupId);
        }

        //verify results
        if ((comboExpected.size() != comboActual.size())) {
            i = Math.abs(comboExpected.size() - comboActual.size());
            errorMessage = i + ' share difference.';
        }

        if (!(comboActual.size() == comboExpected.size())) {
            errorMessage += ' There are actually ' + comboActual.size() + ' actual shares instead of the expected ' + comboExpected.size() + ' shares. ';
        }

        System.assertEquals(true, String.isEmpty(errorMessage), errorMessage);
    }    

    @future
    static void createData() {
        Integer i=0;
        List<WorkOrder> jobInstLst = new List<WorkOrder>();
        List<Job_Sharing__C> jobSharInsLst = new List<Job_Sharing__c>();   
        List<User> userLst = new List<User>([Select Id From User Where  Username Like 'Test_%' AND isActive=true AND Profile.Name ='Operations']);

        System.debug(logginglevel.INFO, '~~~~~ Before Job Looping jobs ');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());  
        //create many  jobs
        Account acc = [Select Id From Account Limit 1];
        for (Integer x=0 ; X <200 ; x++) {
            System.debug(logginglevel.INFO, '~~~~~ ********** x ' + x + ' **************');
            System.debug(logginglevel.INFO, '~~~~~ Inside Beginning Job Looping jobs ');
            System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
            System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
            System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());             
            //List<String> args = new String[]{'0','number','0000-00-0000'};

            //String jobNumber = String.format(x.format(), args);
            //System.debug(logginglevel.INFO, '~~~~~ Inside Middle Job Looping jobs ' + jobNumber);
            System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
            System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
            System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());                        
            jobInstLst.add(new WorkOrder(Job_Name__c='Brookdale-Tempe', Job_Number_Claim__c=x.format(), AccountId=acc.Id, Status='In Progress',
            Estimated_Completion_Date__c=Date.newInstance(2020,02,02), 
            Original_Contract_Amount__c=23760, BD_Account_Manager__c=userLst[0].Id, Project_Director__c=userLst[1].Id, Project_Manager__c=userLst[2].Id,
            Date_of_Call__c=Date.newInstance(2020,01,13), Date_of_Loss__c=Date.newInstance(2020,01,130), Vertical__c='Healthcare', Subvertical__c='Hospital', Street='1610 E Guadalupe Rd.', City='Tempe', StateCode='AZ', PostalCode='85283', CountryCode='US'));  
            System.debug(logginglevel.INFO, '~~~~~ End Beginning Job Looping jobs ');
            System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
            System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
            System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());                               
        }
        System.debug(logginglevel.INFO, '~~~~~ Before Job Insert');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());          
        insert jobInstLst;

        System.debug(logginglevel.INFO, '~~~~~ After jobs insert');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());     

        //job sharing
        for (WorkOrder job : jobInstLst) {
            jobSharInsLst.add(new Job_Sharing__c(Job__c=job.Id, User__c=userLst[3].Id));
            jobSharInsLst.add(new Job_Sharing__c(Job__c=job.Id, User__c=userLst[4].Id));
        }
        insert jobSharInsLst; 
        System.debug(logginglevel.INFO, '~~~~~ After worktype insert');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());        

        //delete shares
        delete [Select Id From WorkOrderShare WHERE RowCause='Manual'];    
        System.debug(logginglevel.INFO, '~~~~~ After WorkOrderShare delete');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements()); 
    }
}