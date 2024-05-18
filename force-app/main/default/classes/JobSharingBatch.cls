/**
 * @File Name          : JobSharingBatch.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 08-17-2023
 * @Modification Log   : Change Construction Manager label and API name to  RM/CM/OM
 * Ver       Date            Author      		    Modification
 * 1.0    2/23/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 * 2.0    30/03/2021   Praveenbabu M                          STAR-2199
**/
global  without sharing class JobSharingBatch implements Database.Batchable<sObject> {
    global JobSharingBatch() {}

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([Select Id, OwnerId, BD_Account_Manager__c, Project_Director__c, Project_Manager__c, AP_Approver__c, BD_Account_Manager_2__c, 
		//  STAR-2199
		RM_CM_OM__c,  Regional_Coordinator__c, BD_Account_Manager_3__c,
        //STAR-4435
        Senior_Project_Manager__c,
        ServiceTerritoryId From WorkOrder]);
    }

    global void execute(Database.BatchableContext BC, List<WorkOrder> scope) {
        Map<Id, WorkOrder> jobsById = new Map<Id, WorkOrder>((List<WorkOrder>)scope);
        JobSharingService jobService = new JobSharingService();
        WorkOrderTriggerHandler.isDefaultOverride = false;
        jobService.shareUnShareJobChanges((Map<Id, WorkOrder>)jobsById, null);  
    }

    global void finish (Database.BatchableContext BC) {

    }
}