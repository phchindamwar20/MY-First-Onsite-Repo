/**
 * @description       : This is the bolt engine for the SF=>Bolt outbound integration.  This class is a part of the queueable chain of responsibility framework, because it extends GenericQueueable.
 *                      Outside of conigurations required by the framework, this BoltCalloutEngineQueueable requires SF to Bolt Integration Engine Config custom metadata type
 *                      Each record should specify the 
 *                          - Bolt Web Service Name (the web service callout to bolt)
 *                          - Object Type (the api name of the object
 *                          - Selection Name (name of the selection class)
 *                          - Label using naming convention ObjectLabelNameDescriptionOfAction
 *                      That setting is used to math a selection and object type combination to the Bolt Webservice.  
 *                      
 *                      The BoltCalloutEngineQueue utilizes the following classes for bolt SF=>Bolt Integration
 *                          - BoltCallouts... BoltCallouts utlizes classes BoltConstants, BoltLogPublisherService, and BoltService
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-06-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class BoltCalloutEngineQueueable extends GenericQueueable {
    @TestVisible
    private static Boolean isBoltCalloutMade = false;

    @TestVisible
    private static String methodName = '';

    public override void execute (QueueableContext context) {
        pushToBolt();
    }

    private void pushToBolt() {
        try {
            if (!currentSelection.getRecIds().isEmpty()) {
                SF_to_Bolt_Integration_Engine_Config__mdt config = getBoltCalloutInfo();
                //System.debug('~~~~ BoltCalloutEngineQueueable::pushToBolt: config - ' + config);

                Set<Id> recIds = currentSelection.getRecIds();
                methodName = config.Bolt_Webservice_Name__c;
                //System.debug('~~~~ BoltCalloutEngineQueueable::pushToBolt: methodName - ' + methodName);

                isBoltCalloutMade = true;

                if(!Test.isRunningTest()) {
                    //System.debug('~~~~ BoltCalloutEngineQueueable::pushToBolt: isBoltCalloutMade - ' + isBoltCalloutMade);
                    BoltCallouts.sendRecords(recIds, methodName, currentClassName);
                }
            }

            //execute next queuable in the list if executed successfully
            handleNext();
        } catch (Exception e) {
            handleError(e);
        }
    }

    public override void handleError(Exception e) {
        if ((e.getMessage().contains(GeneralConstants.LOCK_ERROR) || e.getMessage().contains(GeneralConstants.QUERY_EXCEPTION)) && retryNumber<GeneralConstants.MAX_RETRIES) {
            //retry again
            retryNumber++;

            //add this back in the execution item list to reprocess 
            setUpHandler(executionItemLst, currentSelection, currentClassName, retryNumber, triggerEvent, objectName);
        } else {
            //log error
            String errorMsg ='Cause: ' + e.getCause() + '\nStackTrace: ' + e.getStackTraceString() + '\nMessage: '+ e.getMessage() + '\nType: ' + e.getTypeName() + '\nLine Number: ' + e.getLineNumber() +'\nRetry: ' + retryNumber;
            BoltLogPublisherService.publishBoltErrorEvent(500, errorMsg, '', BoltConstants.SF_TO_BOLT , methodName, currentSelection.getRecIds(), currentClassName);
            if (!Test.isRunningTest()) {
                handleNext();
            }
        } 
    }

    private SF_to_Bolt_Integration_Engine_Config__mdt getBoltCalloutInfo() {
        SF_to_Bolt_Integration_Engine_Config__mdt config = [SELECT Id, Bolt_Webservice_Name__c, Object_Type__c, Selection_Name__c
                                                            FROM SF_to_Bolt_Integration_Engine_Config__mdt
                                                            WHERE Object_Type__c =: objectName AND
                                                                    Selection_Name__c =: currentSelection.getSelectionName() 
                                                            LIMIT 1];
        //System.debug('~~~~ BoltCalloutEngineQueueable::getBoltCalloutInfo: config = ' + config);
        return config;
    }
}