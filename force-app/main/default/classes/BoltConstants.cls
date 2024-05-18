/**
 * @description       : These constants are used only for the Bolt Integration
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-31-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class BoltConstants {

    //Bolt Integration Direction and web services: SF to Bolt
    final public static String SF_TO_BOLT = 'SfToBolt';
    final public static String WS_BOLT_ACCOUNT = 'createAccount';
    final public static String WS_BOLT_PROPERTY = 'sendProperties';
    final public static String WS_BOLT_JOB = 'createJob';
    final public static String WS_BOLT_AREA_WIDE_EVENT = 'upsertAreaWideEvent';
    final public static String WS_BOLT_DEL_ACCOUNTS = 'deleteAccounts';
    final public static String WS_BOLT_DEL_PROPERTIES = 'deleteProperties';
    final public static STRING WS_BOLT_USER = 'updateUser';

    //Icertis Integration Constants
    final public static String IC_External_Signatory_Title = 'Authorized Signatory'; 

    //Bolt Integration Direction and web services: Bolt to SF
    final public static String BOLT_TO_SF = 'BoltToSF';
    final public static String WS_BOLT_ACCOUNT_CREATE = 'createAccount';
    final public static String WS_BOLT_ACCOUNT_UPDATE = 'updateAccount';
    final public static String WS_BOLT_PROPERTY_CREATE = 'createProperty';
    final public static String WS_BOLT_PROPERTY_UPDATE = 'updateProperty';    
    final public static String WS_BOLT_JOB_CREATE = 'createJob';
    final public static String WS_BOLT_JOB_UPDATE = 'updateJob';
    final public static String WS_BOLT_USER_CREATE = 'createUser';
    final public static String WS_BOLT_USER_UPDATE = 'updateUser';

    //Record Types Names
    final public static String RT_ACC_PARENT = 'Parent';
    final public static String RT_ACC_ACCOUNT = 'Account';
    final public static String RT_ACC_PROPERTY = 'Property';
    final public static String RT_BL_ERROR = 'Error';
    final public static String RT_BL_DELETE = 'Delete';
    final public static String RT_BL_INTEGRATION_OFF = 'Integration_Off';

    //record type ids
    final public static Id RT_ID_ACC_PARENT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PARENT).getRecordTypeId();
    final public static Id RT_ID_ACC_ACCOUNT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_ACCOUNT).getRecordTypeId();
    final public static Id RT_ID_ACC_PROPERTY = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BoltConstants.RT_ACC_PROPERTY).getRecordTypeId(); 

    //Error
    final public static String LOCK_ERROR = 'UNABLE_TO_LOCK_ROW';
    final public static String QUERY_EXCEPTION = 'Record Currently Unavailable';
    final public static Integer MAX_RETRIES = 5;

    //Bolt trigger field name
    final public static String BOLT_UPDATE_TRIGGER_FIELD = 'BOLTUpdateTrigger__c';

    //Bolt chain of responsibility queueable
    final public static String BOLT_CHAIN_OF_RESPONS_QUEUEABLE = 'BoltCalloutEngineQueueable'; //Name of the Bolt Callout Engine Chain of responsibility queueable class

    //Bolt chain of responsibility selections
    final public static String BOLT_SEL_ACC = 'SelectionBoltCalloutAccount';
    final public static String BOLT_SEL_AWE = 'SelectionBoltCalloutAreaWideEvent';
    final public static String BOLT_SEL_CHNG_FROM_ACC_RT = 'SelectionBoltCalloutChangeFromAcctRT';
    final public static String BOLT_SEL_CHNG_FROM_PROP_RT = 'SelectionBoltCalloutChangeFromPropertyRT';
    final public static String BOLT_SEL_DEL_ACC = 'SelectionBoltalloutDeleteAccounts';
    final public static String BOLT_SEL_DEL_PROP = 'SelectionBoltCalloutDeleteProperties';
    final public static String BOLT_SEL_JOB = 'SelectionBoltCalloutJob';
    final public static String BOLT_SEL_PROP = 'SelectionBoltCalloutProperty';
    final public static String BOLT_SEL_USER = 'SelectionBoltCalloutUser';
}