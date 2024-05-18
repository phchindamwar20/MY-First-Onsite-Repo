/**
 * @File Name          : IcertisAgreementCancelBatch.cls
 * @Description        :
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 02-19-2024
 * @Modification Log   :  
 * Ver       Date            Author      		    Modification
 * 1.0      13/12/2020        AVashishtha           INITIAL DEVELOPMENT STAR-5366
**/
global class IcertisAgreementCancelBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
     
    global List<WebServiceLogObj> logCancelWrapperList = new List<WebServiceLogObj>();
    public static List<Contract> contractList = new List<Contract>();
    private static Map<Id, String> errorMsgById = new Map<Id, String>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, IC_SysId__c FROM Contract WHERE Status = \''+IcertisConstants.CS_APPROVED +'\' AND IC_Recalled__c = TRUE AND IC_Cancelled__c = FALSE';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Contract> scope){
        List<WebServiceLogObj> logWrapperList = new List<WebServiceLogObj>();
        try {
            contractList = ICertisRemoveDupCWAsService.cancelContracts(scope, logWrapperList);
        } catch(Exception ex) {
            
        }//End of try catch
        logCancelWrapperList.addAll(logWrapperList);
    }    
    global void finish(Database.BatchableContext bc){
        try {
            if(!logCancelWrapperList.IsEmpty()){
                BoltLogPublisherService.generateHttpLogEntries(logCancelWrapperList);
            }
            
            Map<Id, Contract> contractById = new Map<Id, Contract>(contractList);

            //update contracts
            errorMsgById = DynamicApexService.updateRecs(contractById);

            if (!errorMsgById.isEmpty()) {
                //TODO:  take info from errorMsgById and log errors 
                throw new IcertisAgreementCancelBatchException();
            }
        } catch (IcertisAgreementCancelBatchException e) {
            //log
        }
        
    }

    public class IcertisAgreementCancelBatchException extends Exception {}
}