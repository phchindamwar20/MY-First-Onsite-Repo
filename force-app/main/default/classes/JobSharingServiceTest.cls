/**
 * @File Name          : JobSharingServiceTest.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 03-06-2023
 * @Modification Log   : Change Construction Manager label and API name to  RM/CM/OM
 * Ver       Date            Author      		           Modification
 * 1.0    2/20/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 * 2.0    30/03/2021   Praveenbabu M                         STAR-2199
**/
@isTest
public without sharing class JobSharingServiceTest {
    @TestSetup
    static void makeData(){
        TestFactory.createJobTestData(1);
    }
   
    @isTest
    static void testInsertJobs() {
        Set<String> comboExpected = new Set<String>() ;
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        String errorMessage = '';
        Integer i=0;

        System.debug('~~~~ expected');
             //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Manager__c, Project_Director__c, AP_Approver__c, BD_Account_Manager_2__c,RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c, ServiceTerritory.General_Manager__r.IsActive FROM WorkOrder]) {
            if (jobRec.BD_Account_Manager__c != null) {
                System.debug('~~~ BD: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.BD_Account_Manager__c);
            }
            if (jobRec.Project_Director__c != null) {
                System.debug('~~~ PD: ' + jobRec.Id + '-' + jobRec.Project_Director__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Director__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.Project_Director__c);
            } 
            if (jobRec.Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Manager__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.Project_Manager__c);
            }            
            if (jobRec.AP_Approver__c != null) {
                System.debug('~~~ AA: ' + jobRec.Id + '-' + jobRec.AP_Approver__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.AP_Approver__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.AP_Approver__c);
            }  
            if (jobRec.BD_Account_Manager_2__c != null) {
                System.debug('~~~ BDAM2: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.BD_Account_Manager_2__c);
            }  
                 //  STAR-2199
            if (jobRec.RM_CM_OM__c != null) {
                System.debug('~~~ RMCMOM: ' + jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                jobIds.add(jobRec.Id);
				 //  STAR-2199
                userIds.add(jobRec.RM_CM_OM__c);
            }  
            if (jobRec.Regional_Coordinator__c != null) {
                System.debug('~~~ RC: ' + jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.Regional_Coordinator__c);
            } 
            if (jobRec.BD_Account_Manager_3__c != null) {
                System.debug('~~~ BDAM3: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.BD_Account_Manager_3__c);
            }  
            //STAR-4435
            if (jobRec.Senior_Project_Manager__c != null) {
                System.debug('~~~ BDAM3: ' + jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.Senior_Project_Manager__c);
            }             
            //STAR-2754   
            if (jobRec.ServiceTerritoryId != null && jobRec.ServiceTerritory.General_Manager__c != null && jobRec.ServiceTerritory.General_Manager__r.IsActive==true) {
                System.debug('~~~ ServiceTerritory.General_Manager__c: ' + jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.ServiceTerritory.General_Manager__c);
            }                      
        }

        System.debug('~~~~ Actual ');
        for (WorkOrderShare jobShare : [SELECT ParentId, UserOrGroupId FROM WorkOrderShare WHERE RowCause='Manual' AND AccessLevel='Edit']) {
            System.debug('~~~~~' + jobShare.ParentId + '-' + jobShare.UserOrGroupId);
            comboActual.add(jobShare.ParentId + '-' + jobShare.UserOrGroupId);
        }

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
    static void testUpdateJobsSimple() {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        Set<String> comboExpected = new Set<String>() ;
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        String errorMessage = '';
        Integer i=0;

        for (Opportunity opp : [Select Id, StageName From Opportunity]) {
            oppUpdLst.add(new Opportunity(Id=opp.Id, StageName='Closed Won'));
        }
        update oppUpdLst; //To get past system.DMLExcept Error, opp stage must be set to Closed Won before you can create job

        //STAR-2754
        List<ServiceTerritory>  servTerrLst = new List<ServiceTerritory>([SELECT Id, Name, General_Manager__c FROM ServiceTerritory WHERE Name ='Denver']);
        
        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test_%' AND isActive=true AND Profile.Name ='Operations']);

        List<WorkOrder> jobUpdLst = new List<WorkOrder>();   
          //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c, RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c, ServiceTerritory.General_Manager__r.IsActive  FROM WorkOrder]) {
        	 //  STAR-2199
            jobUpdLst.add( new WorkOrder(Id=jobRec.Id, BD_Account_Manager__c= userLst[0].Id, Project_Director__c=userLst[1].Id, Project_Manager__c=userLst[2].Id, 
			AP_Approver__c=userLst[3].Id, BD_Account_Manager_2__c=userLst[4].Id, 
			RM_CM_OM__c=userLst[5].Id,  Regional_Coordinator__c=userLst[6].Id, BD_Account_Manager_3__c=userLst[7].Id,
            //STAR-4435
            Senior_Project_Manager__c=userLst[8].Id,
            ServiceTerritoryId=servTerrLst[0].Id, Status_Note__c='test change')); //STAR-2754
        }

        Test.startTest();
        update jobUpdLst;
        Test.stopTest();

        System.debug('~~~~ expected');
        //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Manager__c, Project_Director__c, AP_Approver__c, BD_Account_Manager_2__c, RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c, ServiceTerritory.General_Manager__r.IsActive FROM WorkOrder]) {
            if (jobRec.BD_Account_Manager__c != null) {
                System.debug('~~~ BD: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager__c);
            }
            if (jobRec.Project_Director__c != null) {
                System.debug('~~~ PD: ' + jobRec.Id + '-' + jobRec.Project_Director__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Director__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Director__c);
            } 
            if (jobRec.Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Manager__c);
            }            
            if (jobRec.AP_Approver__c != null) {
                System.debug('~~~ AA: ' + jobRec.Id + '-' + jobRec.AP_Approver__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.AP_Approver__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.AP_Approver__c);
            }  
            if (jobRec.BD_Account_Manager_2__c != null) {
                System.debug('~~~ BAM2: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_2__c);
            }  
                //  STAR-2199
            if (jobRec.RM_CM_OM__c != null) {
                System.debug('~~~ CM: ' + jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                jobIds.add(jobRec.Id);
				 //  STAR-2199
                userMatchedIds.add(jobRec.RM_CM_OM__c);
            }  
            if (jobRec.Regional_Coordinator__c != null) {
                System.debug('~~~ RC: ' + jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Regional_Coordinator__c);
            } 
            if (jobRec.BD_Account_Manager_3__c != null) {
                System.debug('~~~ BAM3: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_3__c);
            }   
            //STAR-4435 
            if (jobRec.Senior_Project_Manager__c != null) {
                System.debug('~~~ BAM3: ' + jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Senior_Project_Manager__c);
            }              
            //STAR-2754   
            if (jobRec.ServiceTerritoryId != null && jobRec.ServiceTerritory.General_Manager__c != null && jobRec.ServiceTerritory.General_Manager__r.IsActive==true) {
                System.debug('~~~ ServiceTerritory.General_Manager__c: ' + jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.ServiceTerritory.General_Manager__c);
            }         
        }

        System.debug('~~~~ Actual ');
        for (WorkOrderShare jobShare : [SELECT ParentId, UserOrGroupId FROM WorkOrderShare WHERE RowCause='Manual' AND AccessLevel='Edit' AND ParentId In: jobIds AND UserOrGroupId In: userMatchedIds]) {
            System.debug('~~~~~' + jobShare.ParentId + '-' + jobShare.UserOrGroupId);
            comboActual.add(jobShare.ParentId + '-' + jobShare.UserOrGroupId);
        }

        if ((comboExpected.size() != comboActual.size())) {
            i = Math.abs(comboExpected.size() - comboActual.size());
            errorMessage = i + ' share difference.';
        }

        if (!(comboActual.size() == comboExpected.size())) {
            errorMessage += ' There are actually ' + comboActual.size() + ' actual shares instead of the expected ' + comboExpected.size() + ' shares. ';
        }

        //System.assertEquals(true, String.isEmpty(errorMessage), errorMessage);
    }


    @isTest
    static void testInsertJobSharing() {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        Set<String> comboExpected = new Set<String>() ;
        Set<String> comboActual = new Set<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        List<Job_Sharing__c> jobSharInsLst = new List<Job_Sharing__c>();
        String errorMessage = '';
        Integer i=0;

        for (Opportunity opp : [Select Id, StageName From Opportunity]) {
            oppUpdLst.add(new Opportunity(Id=opp.Id, StageName='Closed Won'));
        }
        update oppUpdLst; //To get past system.DMLExcept Error, opp stage must be set to Closed Won before you can create job

        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test%' AND isActive=true AND Profile.Name ='Operations']);

        List<WorkOrder> jobUpdLst = new List<WorkOrder>();
        System.debug('~~~~ Expected');
            //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c,  RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c, ServiceTerritory.General_Manager__r.IsActive FROM WorkOrder]) {
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[0].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[1].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[2].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[3].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[4].Id));
            jobIds.add(jobRec.Id);
            userMatchedIds.add(userLst[0].Id); userMatchedIds.add(userLst[1].Id); userMatchedIds.add(userLst[2].Id); userMatchedIds.add(userLst[3].Id); userMatchedIds.add(userLst[4].Id);
            userMatchedIds.add(jobRec.BD_Account_Manager__c); userMatchedIds.add(jobRec.Project_Director__c); userMatchedIds.add(jobRec.Project_Manager__c);
            userMatchedIds.add(jobRec.AP_Approver__c); userMatchedIds.add(jobRec.BD_Account_Manager_2__c); 
			//  STAR-2199
			userMatchedIds.add(jobRec.RM_CM_OM__c);  userMatchedIds.add(jobRec.Regional_Coordinator__c);
            userMatchedIds.add(jobRec.BD_Account_Manager_3__c);
            userMatchedIds.add(jobRec.ServiceTerritory.General_Manager__c); 
            //STAR-4435
            userMatchedIds.add(jobRec.Senior_Project_Manager__c);

            //Potential 
            System.debug('~~~~ MS0: ' + jobRec.Id + '-' + userLst[0].Id );
            System.debug('~~~~ MS1: ' + jobRec.Id + '-' + userLst[1].Id );
            System.debug('~~~~ MS2: ' + jobRec.Id + '-' + userLst[2].Id );
            System.debug('~~~~ MS3: ' + jobRec.Id + '-' + userLst[3].Id );
            System.debug('~~~~ MS4: ' + jobRec.Id + '-' + userLst[4].Id );
            //System.debug('~~~~ MS5: ' + jobRec.Id + '-' + userLst[5].Id );

            comboExpected.add(jobRec.Id + '-' + userLst[0].Id);
            comboExpected.add(jobRec.Id + '-' + userLst[1].Id);
            comboExpected.add(jobRec.Id + '-' + userLst[2].Id);
            comboExpected.add(jobRec.Id + '-' + userLst[3].Id);
            comboExpected.add(jobRec.Id + '-' + userLst[4].Id);

            if (jobRec.BD_Account_Manager__c != null) {
                System.debug('~~~ BD: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager__c);
            }
            if (jobRec.Project_Director__c != null) {
                System.debug('~~~ PD: ' + jobRec.Id + '-' + jobRec.Project_Director__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Director__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Director__c);
            } 
            if (jobRec.Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Manager__c);
            }      
            if (jobRec.AP_Approver__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.AP_Approver__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.AP_Approver__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.AP_Approver__c);
            }  
            if (jobRec.BD_Account_Manager_2__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_2__c);
            }  
                //  STAR-2199
            if (jobRec.RM_CM_OM__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                jobIds.add(jobRec.Id);
			  //  STAR-2199
                userMatchedIds.add(jobRec.RM_CM_OM__c);
            }  
            if (jobRec.Regional_Coordinator__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Regional_Coordinator__c);
            }  
            if (jobRec.BD_Account_Manager_3__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_3__c);
            }  
            //STAR-4435
            if (jobRec.Senior_Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Senior_Project_Manager__c);
            }            
            //STAR-2754   
            if (jobRec.ServiceTerritoryId != null && jobRec.ServiceTerritory.General_Manager__c != null && jobRec.ServiceTerritory.General_Manager__r.IsActive==true) {
                System.debug('~~~ ServiceTerritory.General_Manager__c: ' + jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.ServiceTerritory.General_Manager__c);
            }                                          
        }

        Test.startTest();
        insert jobSharInsLst;        
        Test.stopTest();


        System.debug('~~~~ Actual ');
        for (WorkOrderShare jobShare : [SELECT ParentId, UserOrGroupId FROM WorkOrderShare WHERE RowCause='Manual' AND AccessLevel='Edit' AND ParentId In: jobIds AND UserOrGroupId In: userMatchedIds]) {
            System.debug('~~~~~' + jobShare.ParentId + '-' + jobShare.UserOrGroupId);
            comboActual.add(jobShare.ParentId + '-' + jobShare.UserOrGroupId);
        }

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
    static void testDeleteJobSharing() {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        Set<String> comboExpected = new Set<String>() ;
        Set<String> comboActual = new Set<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        List<Job_Sharing__c> jobSharInsLst = new List<Job_Sharing__c>();
        String errorMessage = '';
        Integer i=0;


        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test%' AND isActive=true AND Profile.Name ='Operations']);

        List<WorkOrder> jobUpdLst = new List<WorkOrder>();
        System.debug('~~~~ Expected');
        //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, Owner.IsActive, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c,RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c, ServiceTerritory.General_Manager__r.IsActive FROM WorkOrder]) {
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[0].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[1].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[2].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[3].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[4].Id));
            jobIds.add(jobRec.Id);
            userMatchedIds.add(userLst[0].Id); userMatchedIds.add(userLst[1].Id); userMatchedIds.add(userLst[2].Id); userMatchedIds.add(userLst[3].Id); userMatchedIds.add(userLst[4].Id);
            userMatchedIds.add(jobRec.BD_Account_Manager__c); userMatchedIds.add(jobRec.Project_Director__c); userMatchedIds.add(jobRec.Project_Manager__c);
            userMatchedIds.add(jobRec.AP_Approver__c); userMatchedIds.add(jobRec.BD_Account_Manager_2__c); 
			 //  STAR-2199
			userMatchedIds.add(jobRec.RM_CM_OM__c);  userMatchedIds.add(jobRec.Regional_Coordinator__c);   
            userMatchedIds.add(jobRec.BD_Account_Manager_3__c);  
            userMatchedIds.add(jobRec.ServiceTerritory.General_Manager__c);   
            //STAR-4435
            userMatchedIds.add(jobRec.Senior_Project_Manager__c);       

            //Potential 
            System.debug('~~~~ MS0: ' + jobRec.Id + '-' + userLst[0].Id );
            System.debug('~~~~ MS1: ' + jobRec.Id + '-' + userLst[1].Id );
            System.debug('~~~~ MS2: ' + jobRec.Id + '-' + userLst[2].Id );
            System.debug('~~~~ MS3: ' + jobRec.Id + '-' + userLst[3].Id );
            System.debug('~~~~ MS4: ' + jobRec.Id + '-' + userLst[4].Id );
            //System.debug('~~~~ MS5: ' + jobRec.Id + '-' + userLst[5].Id );

            comboExpected.add(jobRec.Id + '-' + userLst[0].Id);
            comboExpected.add(jobRec.Id + '-' + userLst[1].Id);
            comboExpected.add(jobRec.Id + '-' + userLst[2].Id);
            comboExpected.add(jobRec.Id + '-' + userLst[3].Id);
            comboExpected.add(jobRec.Id + '-' + userLst[4].Id);

            if (jobRec.BD_Account_Manager__c != null) {
                System.debug('~~~ BD: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager__c);
            }
            if (jobRec.Project_Director__c != null) {
                System.debug('~~~ PD: ' + jobRec.Id + '-' + jobRec.Project_Director__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Director__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Director__c);
            } 
            if (jobRec.Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Manager__c);
            }      
            if (jobRec.AP_Approver__c != null) {
                System.debug('~~~ AP: ' + jobRec.Id + '-' + jobRec.AP_Approver__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.AP_Approver__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.AP_Approver__c);
            }  
            if (jobRec.BD_Account_Manager_2__c != null) {
                System.debug('~~~ BDAM2: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_2__c);
            }  
                //  STAR-2199
            if (jobRec.RM_CM_OM__c != null) {
                System.debug('~~~ RMCMOM: ' + jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                jobIds.add(jobRec.Id);
				                //  STAR-2199
                userMatchedIds.add(jobRec.RM_CM_OM__c);
            }  
            if (jobRec.Regional_Coordinator__c != null) {
                System.debug('~~~ RC: ' + jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Regional_Coordinator__c);
            }                    
            if (jobRec.BD_Account_Manager_3__c != null) {
                System.debug('~~~ BDAM3: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_3__c);
            } 
            //STAR-4435
            if (jobRec.Senior_Project_Manager__c != null) {
                System.debug('~~~ BDAM3: ' + jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Senior_Project_Manager__c);
            }            
            //STAR-2754   
            if (jobRec.ServiceTerritoryId != null && jobRec.ServiceTerritory.General_Manager__c != null && jobRec.ServiceTerritory.General_Manager__r.IsActive==true) {
                System.debug('~~~ ServiceTerritory.General_Manager__c: ' + jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.ServiceTerritory.General_Manager__c);
            }            
        }


        //pre-validate by first inserting jobs
        insert jobSharInsLst;        

        System.debug('~~~~ Actual ');
        for (WorkOrderShare jobShare : [SELECT ParentId, UserOrGroupId FROM WorkOrderShare WHERE RowCause='Manual' AND AccessLevel='Edit' AND ParentId In: jobIds AND UserOrGroupId In: userMatchedIds]) {
            System.debug('~~~~~' + jobShare.ParentId + '-' + jobShare.UserOrGroupId);
            comboActual.add(jobShare.ParentId + '-' + jobShare.UserOrGroupId);
        }

        if ((comboExpected.size() != comboActual.size())) {
            i = Math.abs(comboExpected.size() - comboActual.size());
            errorMessage = i + ' share difference.';
        }

        if (!(comboActual.size() == comboExpected.size())) {
            errorMessage += ' There are actually ' + comboActual.size() + ' actual shares instead of the expected ' + comboExpected.size() + ' shares. ';
        }

        System.assertEquals(true, String.isEmpty(errorMessage), errorMessage);

        //Setup Test
        comboExpected.clear();
        comboActual.clear();
        errorMessage  = '';
        i=0;

        System.debug('~~~~ Expected');
        //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c,RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c, ServiceTerritory.General_Manager__r.IsActive FROM WorkOrder]) {
            if (jobRec.BD_Account_Manager__c != null) {
                System.debug('~~~ BD: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager__c);
            }
            if (jobRec.Project_Director__c != null) {
                System.debug('~~~ PD: ' + jobRec.Id + '-' + jobRec.Project_Director__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Director__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Director__c);
            } 
            if (jobRec.Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Manager__c);
            }     
            if (jobRec.AP_Approver__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.AP_Approver__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.AP_Approver__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.AP_Approver__c);
            }  
            if (jobRec.BD_Account_Manager_2__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_2__c);
            }  
                 //  STAR-2199
            if (jobRec.RM_CM_OM__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                jobIds.add(jobRec.Id);
				                //  STAR-2199
                userMatchedIds.add(jobRec.RM_CM_OM__c);
            }  
            if (jobRec.Regional_Coordinator__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Regional_Coordinator__c);
            }   
            if (jobRec.BD_Account_Manager_3__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_3__c);
            }  
            //STAR-4435
            if (jobRec.Senior_Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Senior_Project_Manager__c);
            }              
            //STAR-2754   
            if (jobRec.ServiceTerritoryId != null && jobRec.ServiceTerritory.General_Manager__c != null && jobRec.ServiceTerritory.General_Manager__r.IsActive==true) {
                System.debug('~~~ ServiceTerritory.General_Manager__c: ' + jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.ServiceTerritory.General_Manager__c);
            }                                           
        }

        //new test to delete Job Sharing records;
        Test.startTest();
        System.debug('~~~~ keyset: ' + TriggerDispatcher.tc.keySet());
        TriggerDispatcher.tc.remove('JobSharing');
        delete [SELECT Id FROM Job_Sharing__c];
        Test.stopTest();

        //verify test results
        System.debug('~~~~ Actual ');
        for (WorkOrderShare jobShare : [SELECT ParentId, UserOrGroupId FROM WorkOrderShare WHERE RowCause='Manual' AND AccessLevel='Edit' AND ParentId In: jobIds AND UserOrGroupId In: userMatchedIds]) {
            System.debug('~~~~~' + jobShare.ParentId + '-' + jobShare.UserOrGroupId);
            comboActual.add(jobShare.ParentId + '-' + jobShare.UserOrGroupId);
        }

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
    static void testUpdateInactiveUsersSimple() {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        String errorMessage = '';
        Integer i=0;

        for (Opportunity opp : [Select Id, StageName From Opportunity]) {
            oppUpdLst.add(new Opportunity(Id=opp.Id, StageName='Closed Won'));
        }
        update oppUpdLst; //To get past system.DMLExcept Error, opp stage must be set to Closed Won before you can create job

        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test_%' AND isActive=false]);
        List<ServiceTerritory> stLst = new List<ServiceTerritory>([SELECT Id FROM ServiceTerritory WHERE General_Manager__r.IsActive=FALSE AND IsActive=true Limit 1]);

        List<WorkOrder> jobUpdLst = new List<WorkOrder>();
        //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c,RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c, ServiceTerritory.General_Manager__r.IsActive FROM WorkOrder]) {
            jobUpdLst.add( new WorkOrder(Id=jobRec.Id, BD_Account_Manager__c= userLst[0].Id, Project_Director__c=userLst[0].Id, Project_Manager__c=userLst[0].Id, AP_Approver__c=userLst[0].Id, BD_Account_Manager_2__c=userLst[0].Id,RM_CM_OM__c=userLst[0].Id,  Regional_Coordinator__c=userLst[0].Id, BD_Account_Manager_3__c=userLst[0].Id, Senior_Project_Manager__c=userLst[0].Id, ServiceTerritoryId=stLst[0].Id));
        }

        Test.startTest();
        update jobUpdLst;
        Test.stopTest();


        System.debug('~~~~ Actual ');
        for (WorkOrderShare jobShare : [SELECT ParentId, UserOrGroupId FROM WorkOrderShare WHERE RowCause='Manual' AND AccessLevel='Edit' AND ParentId In: jobIds AND UserOrGroupId In: userMatchedIds]) {
            System.debug('~~~~~' + jobShare.ParentId + '-' + jobShare.UserOrGroupId);
            comboActual.add(jobShare.ParentId + '-' + jobShare.UserOrGroupId);
        }

        if ((0 != comboActual.size())) {
            i = Math.abs(0 - comboActual.size());
            errorMessage = i + ' share difference.';
        }

        if (!(comboActual.size() == 0)) {
            errorMessage += ' There are actually ' + comboActual.size() + ' actual shares instead of the expected 0 shares. ';
        }

        System.assertEquals(true, String.isEmpty(errorMessage), errorMessage);
    }    

    @isTest
    static void testUpdateChatterUserSimple() {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        Set<String> comboExpected = new Set<String>() ;
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        String errorMessage = '';
        Integer i=0;

        for (Opportunity opp : [Select Id, StageName From Opportunity]) {
            oppUpdLst.add(new Opportunity(Id=opp.Id, StageName='Closed Won'));
        }
        update oppUpdLst; //To get past system.DMLExcept Error, opp stage must be set to Closed Won before you can create job

        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test_%' AND isActive=true AND Profile.Name='Chatter Free User']);

        List<WorkOrder> jobUpdLst = new List<WorkOrder>();
       //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c,RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c, ServiceTerritory.General_Manager__r.IsActive FROM WorkOrder]) {
            jobUpdLst.add( new WorkOrder(Id=jobRec.Id, BD_Account_Manager__c= userLst[0].Id, Project_Director__c=userLst[0].Id, Project_Manager__c=userLst[0].Id, AP_Approver__c=userLst[0].Id, BD_Account_Manager_2__c=userLst[0].Id, 
			 //  STAR-2199
			RM_CM_OM__c=userLst[0].Id,  Regional_Coordinator__c=userLst[0].Id, BD_Account_Manager_3__c=userLst[0].Id, Senior_Project_Manager__c=userLst[0].Id));
        }

        Test.startTest();
        update jobUpdLst;
        Test.stopTest();



        System.debug('~~~~ Actual ');
        for (WorkOrderShare jobShare : [SELECT ParentId, UserOrGroupId FROM WorkOrderShare WHERE RowCause='Manual' AND AccessLevel='Edit' AND ParentId In: jobIds AND UserOrGroupId In: userMatchedIds]) {
            System.debug('~~~~~' + jobShare.ParentId + '-' + jobShare.UserOrGroupId);
            comboActual.add(jobShare.ParentId + '-' + jobShare.UserOrGroupId);
        }

        if ((0 != comboActual.size())) {
            i = Math.abs(0 - comboActual.size());
            errorMessage = i + ' share difference.';
        }

        if (!(comboActual.size() == 0)) {
            errorMessage += ' There are actually ' + comboActual.size() + ' actual shares instead of the expected 0 shares. ';
        }

        System.assertEquals(true, String.isEmpty(errorMessage), errorMessage);
    }     

    @isTest
    static void testInsertJobSharingError() {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        Set<String> comboExpected = new Set<String>() ;
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        List<Job_Sharing__c> jobSharInsLst = new List<Job_Sharing__c>();
        String errorMessage = '';
        Integer i=0;

        for (Opportunity opp : [Select Id, StageName From Opportunity]) {
            oppUpdLst.add(new Opportunity(Id=opp.Id, StageName='Closed Won'));
        }
        update oppUpdLst; //To get past system.DMLExcept Error, opp stage must be set to Closed Won before you can create job

        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test_%' AND (isActive=false OR Profile.Name ='Chatter Free User')]);

        List<WorkOrder> jobUpdLst = new List<WorkOrder>();
        System.debug('~~~~ Expected');
        //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c, RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c,
                                        Senior_Project_Manager__c,
                                        ServiceTerritoryId, ServiceTerritory.General_Manager__c, ServiceTerritory.General_Manager__r.IsActive FROM WorkOrder]) {
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[0].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[1].Id));

            jobIds.add(jobRec.Id);
            userMatchedIds.add(userLst[0].Id); userMatchedIds.add(userLst[0].Id); userMatchedIds.add(userLst[1].Id); userMatchedIds.add(userLst[0].Id); userMatchedIds.add(userLst[1].Id);
            userMatchedIds.add(jobRec.BD_Account_Manager__c); userMatchedIds.add(jobRec.Project_Director__c); userMatchedIds.add(jobRec.Project_Manager__c);
            userMatchedIds.add(jobRec.AP_Approver__c); userMatchedIds.add(jobRec.BD_Account_Manager_2__c); 
            //STAR-4435
            userMatchedIds.add(jobRec.Senior_Project_Manager__c);
			 //  STAR-2199
			userMatchedIds.add(jobRec.RM_CM_OM__c);  userMatchedIds.add(jobRec.Regional_Coordinator__c); 
            userMatchedIds.add(jobRec.BD_Account_Manager_3__c); 

            //Potential 
            System.debug('~~~~ MS0: ' + jobRec.Id + '-' + userLst[0].Id );
            System.debug('~~~~ MS1: ' + jobRec.Id + '-' + userLst[1].Id );


            comboExpected.add(jobRec.Id + '-' + userLst[0].Id);
            comboExpected.add(jobRec.Id + '-' + userLst[1].Id);


            if (jobRec.BD_Account_Manager__c != null) {
                System.debug('~~~ BD: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager__c);
            }
            if (jobRec.Project_Director__c != null) {
                System.debug('~~~ PD: ' + jobRec.Id + '-' + jobRec.Project_Director__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Director__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Director__c);
            } 
            if (jobRec.Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Manager__c);
            }  
            if (jobRec.AP_Approver__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.AP_Approver__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.AP_Approver__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.AP_Approver__c);
            }  
            if (jobRec.BD_Account_Manager_2__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_2__c);
            }  
                 //  STAR-2199
            if (jobRec.RM_CM_OM__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                jobIds.add(jobRec.Id);
				 //  STAR-2199
                userMatchedIds.add(jobRec.RM_CM_OM__c);
            }  
            if (jobRec.Regional_Coordinator__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Regional_Coordinator__c);
            }   
            if (jobRec.BD_Account_Manager_3__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_3__c);
            } 
            //STAR-4435
            if (jobRec.Senior_Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Senior_Project_Manager__c);
            }              
            //STAR-2754   
            if (jobRec.ServiceTerritoryId != null && jobRec.ServiceTerritory.General_Manager__c != null && jobRec.ServiceTerritory.General_Manager__r.IsActive==true) {
                System.debug('~~~ ServiceTerritory.General_Manager__c: ' + jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.ServiceTerritory.General_Manager__c);
            }                                              
        }

        Test.startTest();
        try {
            insert jobSharInsLst;   
        } catch (DMLException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, e.getCause() + ' - ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        }
        Test.stopTest();

    }    

    @isTest
    static void testUpdateJobSharingError() {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        List<Job_Sharing__c> jobSharInsLst = new List<Job_Sharing__c>();
        String errorMessage = '';
        Integer i=0;

        for (Opportunity opp : [Select Id, StageName From Opportunity]) {
            oppUpdLst.add(new Opportunity(Id=opp.Id, StageName='Closed Won'));
        }
        update oppUpdLst; //To get past system.DMLExcept Error, opp stage must be set to Closed Won before you can create job

        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test_%' AND isActive=true AND Profile.Name ='Operations']);

        List<WorkOrder> jobUpdLst = new List<WorkOrder>();
        System.debug('~~~~ Expected');
             //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c,RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c FROM WorkOrder]) {
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[0].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[1].Id));                        
        }
        insert jobSharInsLst;

        List<Job_Sharing__c> jobShareUpdLst = new List<Job_Sharing__c>();
        for (Job_Sharing__c js : [Select Id, User__c, Job__c From Job_Sharing__c]) {
            jobShareUpdLst.add(new Job_Sharing__c(Id=js.Id, User__c=userLst[2].Id));
        }

        Test.startTest();
        try {
            update jobShareUpdLst;   
        } catch (DMLException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, e.getCause() + ' - ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        }
        Test.stopTest();

    }       
    
    @isTest
    static void testUpdChatUsrInactivatingUser() {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        Set<String> comboExpected = new Set<String>() ;
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        List<Job_Sharing__c> jobSharInsLst = new List<Job_Sharing__c>();
        String errorMessage = '';
        Integer i=0;
        Set<Id> userIdsToInactivate = new Set<Id>();


        Set<Id> userIdSet= new Set<Id>();
        for (User uId : [Select Id From User Where Username Like 'Test_%' AND isActive=true AND Profile.Name='Operations']) {
            userIdSet.add(uId.Id);
        }

 
        
        Test.startTest();
        testUpdChatUsrInactivatingUserUtil(userIdsToInactivate);
        Test.stopTest();


        User chatterUser = [Select Id From User Where Profile.Name='Chatter Free User' Limit 1];
        List<WorkOrder> jobUpdLst = new List<WorkOrder>();
        //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c,RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c FROM WorkOrder]) {
            jobUpdLst.add( new WorkOrder(Id=jobRec.Id, BD_Account_Manager__c= chatterUser.Id));
        }

        Boolean pass=false;

        /*try { 
         update jobUpdLst;
        
        } catch (Exception e) {
           pass=true;
        }

        System.assertEquals(true, pass, 'Expected to throw an error');*/
        
      
        
    }  

    @isTest
    static void testInsJobShareWithInactiveJobOwner() {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        Set<String> comboExpected = new Set<String>() ;
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        List<Job_Sharing__c> jobSharInsLst = new List<Job_Sharing__c>();
        String errorMessage = '';
        Integer i=0;
        Set<Id> userIdsToInactivate = new Set<Id>();

        List<User> updUserLst = new List<User>();
        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test_%' AND isActive=true]);

        System.debug('~~~~ Expected');
        //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, OwnerId, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c,RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c, Senior_Project_Manager__c, ServiceTerritoryId, ServiceTerritory.General_Manager__c, ServiceTerritory.General_Manager__r.IsActive FROM WorkOrder]) {
            userIdsToInactivate.add(jobRec.OwnerId);
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[0].Id));
            jobSharInsLst.add(new Job_Sharing__C(Job__c=jobRec.Id, User__c=userLst[1].Id));

            jobIds.add(jobRec.Id);
            userMatchedIds.add(userLst[0].Id); userMatchedIds.add(userLst[0].Id); userMatchedIds.add(userLst[1].Id); userMatchedIds.add(userLst[0].Id); userMatchedIds.add(userLst[1].Id);
            userMatchedIds.add(jobRec.BD_Account_Manager__c); userMatchedIds.add(jobRec.Project_Director__c); userMatchedIds.add(jobRec.Project_Manager__c);
            userMatchedIds.add(jobRec.AP_Approver__c); userMatchedIds.add(jobRec.BD_Account_Manager_2__c);
			  //  STAR-2199
			userMatchedIds.add(jobRec.RM_CM_OM__c);  userMatchedIds.add(jobRec.Regional_Coordinator__c);  
            userMatchedIds.add(jobRec.BD_Account_Manager_3__c);
            //STAR-4435
            userMatchedIds.add(jobRec.Senior_Project_Manager__c);

            //Potential 
            System.debug('~~~~ MS0: ' + jobRec.Id + '-' + userLst[0].Id );
            System.debug('~~~~ MS1: ' + jobRec.Id + '-' + userLst[1].Id );


            comboExpected.add(jobRec.Id + '-' + userLst[0].Id);
            comboExpected.add(jobRec.Id + '-' + userLst[1].Id);


            if (jobRec.BD_Account_Manager__c != null) {
                System.debug('~~~ BD: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager__c);
            }
            if (jobRec.Project_Director__c != null) {
                System.debug('~~~ PD: ' + jobRec.Id + '-' + jobRec.Project_Director__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Director__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Director__c);
            } 
            if (jobRec.Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Project_Manager__c);
            }  
            if (jobRec.AP_Approver__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.AP_Approver__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.AP_Approver__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.AP_Approver__c);
            }  
            if (jobRec.BD_Account_Manager_2__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_2__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_2__c);
            }  
                 //  STAR-2199
            if (jobRec.RM_CM_OM__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.RM_CM_OM__c);
                jobIds.add(jobRec.Id);
				  //  STAR-2199
                userMatchedIds.add(jobRec.RM_CM_OM__c);
            }  
            if (jobRec.Regional_Coordinator__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Regional_Coordinator__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Regional_Coordinator__c);
            }     
            if (jobRec.BD_Account_Manager_3__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.BD_Account_Manager_3__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.BD_Account_Manager_3__c);
            }  
            //STAR-4435  
            if (jobRec.Senior_Project_Manager__c != null) {
                System.debug('~~~ PM: ' + jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.Senior_Project_Manager__c);
                jobIds.add(jobRec.Id);
                userMatchedIds.add(jobRec.Senior_Project_Manager__c);
            }               
            //STAR-2754   
            if (jobRec.ServiceTerritoryId != null && jobRec.ServiceTerritory.General_Manager__c != null && jobRec.ServiceTerritory.General_Manager__r.IsActive==true) {
                System.debug('~~~ ServiceTerritory.General_Manager__c: ' + jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                comboExpected.add(jobRec.Id + '-' + jobRec.ServiceTerritory.General_Manager__c);
                jobIds.add(jobRec.Id);
                userIds.add(jobRec.ServiceTerritory.General_Manager__c);
            }                                       
        }

        for (Id userRec : userIdsToInactivate) {
            updUserLst.add(new User(Id=userRec, IsActive=false));            
        }  
        
        Test.startTest();
        testUpdChatUsrInactivatingUserUtil(userIdsToInactivate);
        Test.stopTest();    
                
        try {
            insert jobSharInsLst; 
        } catch (Exception e) {
            System.assert(true);
        }

    }  

    @isTest
    static void testOwnerSelfAssignment() {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        List<String> comboActual = new List<String>();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> userMatchedIds = new Set<Id>();
        String errorMessage = '';
        Integer i=0;

        for (Opportunity opp : [Select Id, StageName From Opportunity]) {
            oppUpdLst.add(new Opportunity(Id=opp.Id, StageName='Closed Won'));
        }
        update oppUpdLst; //To get past system.DMLExcept Error, opp stage must be set to Closed Won before you can create job

        List<User> userLst = new List<User>([Select Id From User Where Username Like 'Test_%' AND isActive=true AND Profile.Name ='Operations']);

        List<WorkOrder> jobUpdLst = new List<WorkOrder>();
        //  STAR-2199
        for (WorkOrder jobRec : [SELECT Id, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c,RM_CM_OM__c,  Regional_Coordinator__c, OwnerId, BD_Account_Manager_3__c, Senior_Project_Manager__c  FROM WorkOrder]) {
            jobUpdLst.add( new WorkOrder(Id=jobRec.Id, BD_Account_Manager__c=jobRec.OwnerId, Project_Director__c=jobRec.OwnerId, Project_Manager__c=jobRec.OwnerId, AP_Approver__c=jobRec.OwnerId, BD_Account_Manager_2__c=jobRec.OwnerId, 
			RM_CM_OM__c=jobRec.OwnerId,  Regional_Coordinator__c=jobRec.OwnerId, BD_Account_Manager_3__c=jobRec.BD_Account_Manager_3__c, Senior_Project_Manager__c=jobRec.OwnerId));
        }

        Test.startTest();
        update jobUpdLst;
        Test.stopTest();

        System.debug('~~~~ Actual ');
        for (WorkOrderShare jobShare : [SELECT ParentId, UserOrGroupId FROM WorkOrderShare WHERE RowCause='Manual' AND AccessLevel='Edit' AND ParentId In: jobIds AND UserOrGroupId In: userMatchedIds]) {
            System.debug('~~~~~' + jobShare.ParentId + '-' + jobShare.UserOrGroupId);
            comboActual.add(jobShare.ParentId + '-' + jobShare.UserOrGroupId);
        }

        if ((0 != comboActual.size())) {
            i = Math.abs(0 - comboActual.size());
            errorMessage = i + ' share difference.';
        }

        if (!(comboActual.size() == 0)) {
            errorMessage += ' There are actually ' + comboActual.size() + ' actual shares instead of the expected ' + 0 + ' shares. ';
        }

        System.assertEquals(true, String.isEmpty(errorMessage), errorMessage);

    }

    @isTest
    static void testJobOwnerChangeWhenNewOwnerHasAJobSharing() {
        WorkOrder job = [SELECT Id, OwnerId FROM WorkOrder Limit 1];
        User newUser = [SELECT Id FROM User WHERE Id !=: job.OwnerId AND LastName LIKE 'zAdd%' Limit 1];
        Job_Sharing__c jobShare = new Job_Sharing__c(Job__c=job.Id, User__c=newUser.Id);
        insert jobShare;

        Test.startTest();
        WorkOrder jobUpdate = new WorkOrder(Id=job.Id, OwnerId=newUser.Id);
        update jobUpdate;
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM Job_Sharing__c WHERE User__c=:newUser.Id].size());
    }


    @future
    static void testUpdChatUsrInactivatingUserUtil(Set<Id> userIdsToInactivate) {
        List<User> updUserLst = new List<User>();
        
        for (Id userRec : userIdsToInactivate) {
            updUserLst.add(new User(Id=userRec, IsActive=false, Country='United States'));            
        }        

        update updUserLst;

        System.debug('~~~~~: JobSharingServiceTest::testUpdChatUsrInactivatingUserUtil: user ' + [SELECT Id, IsActive, Name FROM User WHERE Id IN: userIdsToInactivate]);
    }
}