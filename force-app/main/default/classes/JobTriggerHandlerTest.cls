/**
 * @File Name          : JobTriggerHandlerTest.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 09-01-2022
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/27/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 * 2.0    05/07/2024  Kiran K (CFS)               STAR-6569 removed unused Sage Fields
**/
@isTest
public without sharing class JobTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getOrgDefaults();
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffFlow__c=true;
        dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.SetupOwnerId=UserInfo.getUserId();
        System.debug('~~~~ JobTriggerHandlerTest::makeData: dataAdmin before DML - ' + dataAdmin);
        insert dataAdmin;  
        System.debug('~~~~ JobTriggerHandlerTest::makeData: dataAdmin AFTER DML - ' + dataAdmin);

       
        TestFactory.createJobTestData(200); 
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
        List<WorkOrder> jobInstLst = new List<WorkOrder>();
        List<Job_Sharing__C> jobSharInsLst = new List<Job_Sharing__c>();
    


        List<User> userLst = [Select Id, IsActive, Profile.Name, ProfileId From User Where Username Like 'Test_%' AND isActive=true AND Profile.Name='Operations'];


        //get expected for jobs
        System.debug(logginglevel.INFO, '~~~~ expected');
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Manager__c, Project_Director__c FROM WorkOrder]) {
            /*if (jobRec.ServiceTerritory.Name != jobRec.Service_Territory_pl__c) {
                errorMessage += 'jobRec with Service Territory picklist value ' + jobRec.Service_Territory_pl__c + ' doesn \'t match the service terrority that should of been set to match the service territory picklist ';
            }
            if (jobRec.WorkType.Name != jobRec.Work_Type_pl__c) {
                errorMessage += 'jobRec with Work Type picklist value ' + jobRec.Work_Type_pl__c + ' doesn \'t match the work type that should of been set to match the work type picklist ';
            }  */          
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
            errorMessage += i + ' share difference.';
        }

        if (!(comboActual.size() == comboExpected.size())) {
            errorMessage += ' There are actually ' + comboActual.size() + ' actual shares instead of the expected ' + comboExpected.size() + ' shares. ';
        }

        System.assertEquals(true, String.isEmpty(errorMessage), errorMessage);
    }    

    @isTest
    static void testUpdate() {
        Set<String> comboExpected = new Set<String>() ;
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        String errorMessage = '';
        Integer i=0;
        List<WorkOrder> jobInstLst = new List<WorkOrder>();
        List<Job_Sharing__C> jobSharInsLst = new List<Job_Sharing__c>();
        List<WorkOrder> jobUpdLst = new List<WorkOrder>();

        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test_%' AND isActive=true AND Profile.Name='Operations']);

        System.debug(logginglevel.INFO, '~~~~~ Before Job Looping jobs ');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());  
        //create many  jobs
 
        for (WorkOrder job : jobInstLst) {
            jobSharInsLst.add(new Job_Sharing__c(User__c=userLst[4].Id, Job__c=job.Id));
            comboExpected.add(job.Id + '-' + userLst[4].Id);
        }

        insert jobInstLst;


        for (WorkOrder job : [Select Id, BD_Account_Manager__c From WorkOrder]) {
            jobUpdLst.add(new WorkOrder(Id=job.Id, BD_Account_Manager__c=userLst[3].Id));
        }

        Test.startTest();
        update jobUpdLst;
        Test.stopTest();

        //get expected for jobs
        System.debug(logginglevel.INFO, '~~~~ expected');
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Manager__c, Project_Director__c FROM WorkOrder]) {
            /*if (jobRec.ServiceTerritory.Name != jobRec.Service_Territory_pl__c) {
                errorMessage += 'jobRec with Service Territory picklist value ' + jobRec.Service_Territory_pl__c + ' doesn \'t match the service terrority that should of been set to match the service territory picklist ';
            }
            if (jobRec.WorkType.Name != jobRec.Work_Type_pl__c) {
                errorMessage += 'jobRec with Work Type picklist value ' + jobRec.Work_Type_pl__c + ' doesn \'t match the work type that should of been set to match the work type picklist ';
            }  */            
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

        //test


        //get actual for both
        System.debug(logginglevel.INFO, '~~~~ Actual ');
        for (WorkOrderShare jobShare : [SELECT ParentId, UserOrGroupId FROM WorkOrderShare WHERE RowCause='Manual' AND AccessLevel='Edit' AND ParentId In: jobIds AND UserOrGroupId In: userMatchedIds]) {
            System.debug(logginglevel.INFO, '~~~~~' + jobShare.ParentId + '-' + jobShare.UserOrGroupId);
            comboActual.add(jobShare.ParentId + '-' + jobShare.UserOrGroupId);
        }

        //verify results
        if ((comboExpected.size() != comboActual.size())) {
            i = Math.abs(comboExpected.size() - comboActual.size());
            errorMessage += i + ' share difference.';
        }

        if (!(comboActual.size() == comboExpected.size())) {
            errorMessage += ' There are actually ' + comboActual.size() + ' actual shares instead of the expected ' + comboExpected.size() + ' shares. ';
        }

        System.assertEquals(true, String.isEmpty(errorMessage), errorMessage);
    } 

    @isTest
    static private void testPreventBoltJobClone() {
        Id accId = [SELECT Id FROM Account Limit 1].Id;

        List<WorkOrder> jobCloneLst = new List<WorkOrder>();

        for (WorkOrder job : [SELECT Id, Integrate_with_Bolt__c, ServiceTerritoryId, WorkTypeId, Vertical__c, Subvertical__c FROM WorkOrder]) {
        //for (WorkOrder job : [SELECT Id, Integrate_with_Bolt__c, ServiceTerritoryId, WorkTypeId, Vertical__c, Subvertical__c, Job_Number_Claim__c, AccountId FROM WorkOrder]) {
            System.debug('~~~~ JobTriggerHandlerTest::testPreventBoltJobClone: job ' + job);
            jobCloneLst.add(job.clone(false, false, false, false));
        }

        try {
            insert jobCloneLst;
            System.assert(false, 'expected error to be thrown when job associated with a bolt branch');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(label.BOLT_EXCEPTION_CLONE), 'expected error to be thrown when job associated with a bolt branch');
        }
        
    }

    @isTest
    static void testSetIntegrateWithBolt(){
        //insert case, expect job to be set as Integrate with Bolt = true
        System.assert([SELECT Id FROM WorkOrder WHERE Integrate_with_Bolt__c=true].size()>0, 'Did not set Integrate with Bolt flag');

        //Change branch Integrate with Bolt flag from true to false, update Job Status, expect Job's Integrate with Bolt to remain true
        Map<Id,ServiceTerritory> branchUpdById = new Map<Id,ServiceTerritory>();
        Map<Id,WorkOrder> jobUpdBrnchById = new Map<Id,WorkOrder>();
        for (ServiceTerritory branch : [SELECT Id FROM ServiceTerritory WHERE Integrate_with_Bolt__c=true]) {
            branchUpdById.put(branch.Id, new ServiceTerritory(Id=branch.Id, Integrate_with_Bolt__c=false));
        }
        update branchUpdById.values();
        for(WorkOrder job : [SELECT Id FROM WorkOrder WHERE Integrate_with_Bolt__c=true AND ServiceTerritoryId In: branchUpdById.keySet()]) {
            jobUpdBrnchById.put(job.Id, new WorkOrder(Id=job.Id, Status='Closed'));
        }
        update jobUpdBrnchById.values();
        System.assert([SELECT Id FROM WorkOrder WHERE Integrate_with_Bolt__c=true AND Id In: jobUpdBrnchById.keySet() AND ServiceTerritoryId In: branchUpdById.keySet()].size() > 0, 'Failed:  Expected Integrate with Bolt to remain true');

        //update case job's Integrate with Bolt to false, expect it to remain false
        List<WorkOrder> updJobLst = new List<WorkOrder>();
        for (WorkOrder job : [SELECT Id FROM WorkOrder WHERE Integrate_with_Bolt__c=true]) {
            updJobLst.add(new WorkOrder(Id=job.Id, Integrate_with_Bolt__c=false));
        }
        update updJobLst;
        System.assert([SELECT Id FROM WorkOrder WHERE Integrate_with_Bolt__c=true].size()==0, 'Fail:  Expected no results to return with Integrate with Bolt');

    }

    @isTest
    static private void testInactiveOwnerReassignGM() {
        String profileId = [SELECT Id FROM Profile WHERE Name='Operations' Limit 1].Id;
        Set<Id> activeUserIds = new Set<Id>();
        List<WorkOrder> jobLst = new List<WorkOrder>();
        User inactiveOwner = [SELECT Id FROM User WHERE Profile.Name='Operations' AND IsActive=false Limit 1];

        //get branches's active general manager
        for (ServiceTerritory branch : [SELECT Id, OwnerId, Name, General_Manager__c, General_Manager__r.IsActive FROM ServiceTerritory WHERE General_Manager__r.IsActive=true]) {
            activeUserIds.add(branch.General_Manager__c);
            System.debug('~~~~ JobTriggerHandlerTest::testInactiveOwnerReassignGM: branch - ' + branch);
        }

        //get owners of jobs and set as inactive
        for (WorkOrder job : [SELECT Id, OwnerId, Owner.Name, Owner.IsActive, ServiceTerritoryId, ServiceTerritory.Name, ServiceTerritory.General_Manager__r.Name FROM WorkOrder ]) {
            jobLst.add(new WorkOrder(Id=job.Id, OwnerId=inactiveOwner.Id));
            System.debug('~~~~~ JobTriggerHandlerTest::testInactiveOwnerReassignGM: job - ' + job);
        }

        Test.startTest();        
        update jobLst;
        Test.stoptest();

        System.assert(![SELECT Id FROM WorkOrder WHERE OwnerId IN: activeUserIds].isEmpty(), 'Fail:  Owner not set to the General Manager of the Branch');
    }

    @isTest
    static private void testInactiveOwnerReassignGMDefault() {
        String profileId = [SELECT Id FROM Profile WHERE Name='Operations' Limit 1].Id;
        List<ServiceTerritory> branchLst = new List<ServiceTerritory>();
        List<WorkOrder> jobLst = new List<WorkOrder>();
        List<User> inactiveOwnerLst = [SELECT Id FROM User WHERE Profile.Name='Operations' AND IsActive=false Limit 2];
        Id reAssignQueueId = [SELECT UserId__c FROM JobShareSettings__mdt Limit 1].UserId__c;

        //update branches to have inactive general managers
        for (ServiceTerritory branch : [SELECT Id, OwnerId, Name, General_Manager__c, General_Manager__r.IsActive FROM ServiceTerritory WHERE General_Manager__r.IsActive=true]) {
            branchLst.add(new ServiceTerritory(Id=branch.Id, General_Manager__c=inactiveOwnerLst[0].Id));
            System.debug('~~~~ JobTriggerHandlerTest::testInactiveOwnerReassignGM: branch - ' + branch);
        }
        update branchLst;

        //get owners of jobs and set as inactive
        for (WorkOrder job : [SELECT Id, OwnerId, Owner.Name, Owner.IsActive, ServiceTerritoryId, ServiceTerritory.Name, ServiceTerritory.General_Manager__r.Name FROM WorkOrder ]) {
            jobLst.add(new WorkOrder(Id=job.Id, OwnerId=inactiveOwnerLst[1].Id));
            System.debug('~~~~~ JobTriggerHandlerTest::testInactiveOwnerReassignGM: job - ' + job);
        }

        Test.startTest();        
        update jobLst;
        Test.stoptest();

        System.assert(![SELECT Id FROM WorkOrder WHERE OwnerId =: reAssignQueueId].isEmpty(), 'Fail:  Owner not set to the General Manager of the Branch');
    }
}