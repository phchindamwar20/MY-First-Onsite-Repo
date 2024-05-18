/**
 * @File Name          : JobSharingTriggerHandlerTest.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 09-21-2023
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/27/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 * 2.0    05/07/2024  Kiran K (CFS)                 STAR-6569 removed unused Sage Fields
**/
@isTest
public without sharing class JobSharingTriggerHandlerTest {

    @TestSetup
    static void makeData(){
        //List<Opportunity> oppUpdLst = new List<Opportunity>();
        DataAdmin__c dataAdmin = DataAdmin__c.getOrgDefaults();
        dataAdmin.TurnOffFlow__c=true;
        dataAdmin.TurnOffTrigger__c=true;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.SetupOwnerId=UserInfo.getOrganizationId();
        insert dataAdmin;

        Account acc = (Account)TestFactory.createSObject(new Account(Name='House Account', Status__c='Dormant', Drive_Down__c='No', National_Account__c='Yes', Contract_Type__c='MSA Only', Number_of_Active_Contracts__c=0,
                RecordTypeId='0121U000000b3ytQAA', CurrencyIsoCode='USD',Vertical__c = 'Hospitality', Subvertical__c = 'Airlines'), 'TestFactoryDefaults.AccountDefaults', true);
        System.debug(logginglevel.INFO, '~~~~~ After account insert');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());


        Test.startTest();
        TestFactory.createUsers();
        Test.stopTest(); 

        dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=false;
        dataAdmin.TurnOffProcessBuilder__c=false;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.SetupOwnerId=UserInfo.getOrganizationId();
        update dataAdmin;  
        System.debug(logginglevel.INFO, '~~~~~ After DataAdmin update');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());  

        Integer i=0;
        List<WorkOrder> jobInstLst = new List<WorkOrder>();
        List<Job_Sharing__C> jobSharInsLst = new List<Job_Sharing__c>();
       
        
        
        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test_%' AND isActive=true AND Profile.Name ='Operations']);

        System.debug(logginglevel.INFO, '~~~~~ Before Job Looping jobs ');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());  
        //create many  jobs
        //opp = [Select Id, AccountId From Opportunity Limit 1];
        for (Integer x=0 ; x < 2 ; x++) {                      
            jobInstLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(Job_Name__c='Brookdale-Tempe', Job_Number_Claim__c=x.format(), AccountId=acc.Id,  Status='In Progress',
            Estimated_Completion_Date__c=Date.newInstance(2020,02,02),
            Original_Contract_Amount__c=23760,  BD_Account_Manager__c=userLst[0].Id, Project_Director__c=userLst[1].Id,
            Date_of_Call__c=Date.newInstance(2020,01,13), Date_of_Loss__c=Date.newInstance(2020,01,130), Street='1610 E Guadalupe Rd.', City='Tempe', StateCode='AZ', PostalCode='85283', CountryCode='US',Vertical__c = 'Hospitality' , Subvertical__c = 'Airlines'), 'TestFactoryDefaults.JobDefaults'));                               
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

        for (WorkOrder job : jobInstLst) {
            jobSharInsLst.add(new Job_Sharing__c(User__c=userLst[2].Id, Job__c=job.Id));
        }
        
        insert jobSharInsLst;            
                
    }

    @isTest
    static void testInsert() {
        Set<String> comboExpected = new Set<String>() ;
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        String errorMessage = '';
        Integer i=0;
        
        //get expected for jobs
        System.debug(logginglevel.INFO, '~~~~ expected');
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Manager__c, Project_Director__c FROM WorkOrder]) {
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


    @isTest
    static void testDelete() {
        Set<String> comboExpected = new Set<String>() ;
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        String errorMessage = '';
        Integer i=0;
        
        //get expected for jobs
        System.debug(logginglevel.INFO, '~~~~ expected');
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Manager__c, Project_Director__c FROM WorkOrder]) {
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
        
        Test.startTest();
        delete [Select Id From Job_Sharing__c];
        Test.stopTest();

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
    
}