/**
 * @description       : This is the constants file used for iCertis functionality
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-18-2024
 * @last modified by  : Terri Jiles
**/
public without Sharing class ICertisConstants {
    //Icertis Integration Constants
    final public static String IC_EXTERNAL_SIGNATORY_TITLE = 'Authorized Signatory'; 
    final public static String IC_FIELDS_UPDATE = 'Fields Updated';
    
    //Integration direction
    final public static String SF_TO_ICERTIS = 'SfToIcertis';

    //contract statuses
    final public static String CS_APPROVED = 'Approved';
    final public static String CS_EXECUTED = 'Executed';
    final public static String CS_SEND_FOR_APPROVAL = 'Send for Approval';
    final public static String CS_DRAFT = 'Draft';

    //bolt log record types
    final public static String ICERTIS_ERROR = 'Icertis_Error';
    final public static String ICERTIS_LOG = 'Icertis_Log';

    //iCertis endpoints used in endpoint url of callout
    final public static String EP_AGREEMENTS = 'agreements';
    final public static String EP_USERS = 'users';

    //iCertis contractTypeName parameters for use in iCertis agreements endpoints
    final public static String CTN_ICMCWA = 'ICMCWA'; 

    //configurations
    final private static iCertis_Configuration__mdt defaultConfig = iCertis_Configuration__mdt.getInstance('Default');
    final public static Integer BATCH_SIZE_RECALL = (Integer)defaultConfig.Recall_Batch_Size__c;
    final public static Integer BATCH_SIZE_CANCEL = (Integer)defaultConfig.Cancel_Batch_Size__c;
    final public static Integer CALLOUT_TIMEOUT = (Integer)defaultConfig.Callout_Timeout__c;
    
    //Job object
    final public static String IC_WORKORDER = 'WorkOrder';
    
    //Bolt Log Type
    final public static String IC_OTHER_TYPE = 'Other';
}