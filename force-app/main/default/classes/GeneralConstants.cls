/**
 * @description       : General Constants that can be used through the org
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-26-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class GeneralConstants {
    //Record Types Names
    final public static String RT_ACC_PARENT = 'Parent';
    final public static String RT_ACC_ACCOUNT = 'Account';
    final public static String RT_ACC_PROPERTY = 'Property';
    final public static String RT_BL_ERROR = 'Error';
    final public static String RT_BL_DELETE = 'Delete';
    final public static String RT_BL_INTEGRATION_OFF = 'Integration_Off';
    final public static String RT_CONTRACT_CLIENT = 'Client';

    //record type ids
    final public static Id RT_ID_ACC_PARENT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GeneralConstants.RT_ACC_PARENT).getRecordTypeId();
    final public static Id RT_ID_ACC_ACCOUNT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GeneralConstants.RT_ACC_ACCOUNT).getRecordTypeId();
    final public static Id RT_ID_ACC_PROPERTY = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GeneralConstants.RT_ACC_PROPERTY).getRecordTypeId(); 
    final public static Id RT_ID_CONTRACT_CLIENT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get(GeneralConstants.RT_CONTRACT_CLIENT).getRecordTypeId();

    //Error Messages
    final public static String LOCK_ERROR = 'UNABLE_TO_LOCK_ROW';
    final public static String QUERY_EXCEPTION = 'Record Currently Unavailable';
    final public static Integer MAX_RETRIES = 5;

    //Trigger Events
    final public static String AFTER_DELETE = 'AFTER_DELETE';
    final public static String AFTER_INSERT = 'AFTER_INSERT';
    final public static String AFTER_UNDELETE = 'AFTER_UNDELETE';
    final public static String AFTER_UPDATE = 'AFTER_UPDATE';
    final public static String BEFORE_DELETE = 'BEFORE_DELETE';
    final public static String BEFORE_INSERT = 'BEFORE_INSERT';
    final public static String BEFORE_UPDATE = 'BEFORE_UPDATE';

    //API Object Names
    final public static String OBJ_ACCOUNT = 'Account';
    final public static String OBJ_AREA_WIDE_EVENT = 'Area_Wide_Event__c';
    final public static String OBJ_CONTENT_DOCUMENT_LINK = 'ContentDocumentLink';
    final public static String OBJ_CONTRACT = 'Contract';
    final public static String OBJ_USER = 'User';
    final public static String OBJ_JOB = 'WorkOrder';

    //Account Status
    final public static String ACC_STATUS_UNQUALIFIED = 'Unqualified';
    final public static String ACC_STATUS_NEEDS_ASSESSMENT = 'Needs Assessment';

    //Account Contract Type
    final public static String ACC_CONTRACT_TYPE_COVERED_BY_PARENT = 'Covered By Parent';

    //Job Statues
    final public static Set<String> OPEN_JOB_STATUSES = getOpenJobStatuses();
    final public static String  JOB_STATUS_CLOSED = 'Closed';

    // Go/No-Go status
    final public static String GO = 'Go';
    final public static String NO_GO = 'No-Go';

    private static Set<String> getOpenJobStatuses() {
        Set<String> openStatues = new Set<String>();

        for (Open_Job_Status__mdt ojs : [SELECT MasterLabel FROM Open_Job_Status__mdt]) {
            openStatues.add(ojs.MasterLabel);
        }

        return openStatues;
    }

    //default users
    final public static Id USER_ID_SYSTEM_ADMIN = [SELECT Id FROM User WHERE Username LIKE 'salesforce@firstonsite.co%' AND Alias='sfadmin' LIMIT 1].Id;

    //REST Methods
    final public static String POST = 'POST';
    final public static String PUT = 'PUT';
    final public static String GET = 'GET';
}