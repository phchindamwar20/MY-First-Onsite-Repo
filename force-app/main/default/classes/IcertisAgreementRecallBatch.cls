/**
 * @File Name          : IcertisAgreementRecallBatch.cls
 * @Description        : this find and recalls duplicate icertis agreements related to CWA jobs
 * @Author             : Arpit Vashishtha
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 02-19-2024
 * @Modification Log   :  
 * Ver       Date            Author      		    Modification
**/
global class IcertisAgreementRecallBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    global List<WebServiceLogObj> logRecallWrapperList = new List<WebServiceLogObj>();
    
    global Iterable<AggregateResult> start(Database.BatchableContext BC) {
        Set<String> statuses = new Set<String>{ICertisConstants.CS_APPROVED, ICertisConstants.CS_EXECUTED};
        return [SELECT Job__c, COUNT (Id) cnt FROM Contract 
                    WHERE Status IN: statuses AND Job__r.IC_Bolt_CWA__c=true AND IC_Recalled__c=false  
                    GROUP BY Job__c
                    HAVING COUNT(Id) > 1];
    }

    global void execute(Database.BatchableContext bc, List<AggregateResult> scope){
        Map<Id, String> errorMsgById = new Map<Id, String>();
        List<WebServiceLogObj> logWrapperList = new List<WebServiceLogObj>();
        try {

            Set<Id> jobIds = new Set<Id>();
            for (AggregateResult result : scope) {
                jobIds.add((Id)result.get('Job__c'));
            }

            List<Contract> initialContractLst = getStartRecordsForRecall(jobIds);
            //recall CWA agreements
            List<Contract> contractLst = ICertisRemoveDupCWAsService.recallContracts(initialContractLst, logWrapperList);
            Map<Id, Contract> contractById = new Map<Id, Contract>(contractLst);

            //update contracts
            errorMsgById = DynamicApexService.updateRecs(contractById);

            if (!errorMsgById.isEmpty()) {
                //TODO:  take info from errorMsgById and log errors 
                throw new IcertisAgreementRecallBatchException();
            }
        } catch (IcertisAgreementRecallBatchException e) {
            //TODO:  log errors
        } catch (Exception e) {
            //TODO:  log errors
        }
        System.debug('logWrapperList in recall:::'+logWrapperList.size());
        logRecallWrapperList.addAll(logWrapperList);
        System.debug('logRecallWrapperList in recall:::'+logRecallWrapperList.size());
    }    
    global void finish(Database.BatchableContext bc){

        if(!logRecallWrapperList.IsEmpty()){
            BoltLogPublisherService.generateHttpLogEntries(logRecallWrapperList);
            System.debug('Published logRecallWrapperList in recall:::'+logRecallWrapperList.size());
        }
        Datetime sysTime = System.now(); 
        sysTime = sysTime.addSeconds(60); 
        String chron_exp = sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year(); 
        system.debug(chron_exp); 
        System.schedule('IcertisAgreementCancelSchedule:Running at '+System.now().format() + sysTime.getTime(),chron_exp, new IcertisAgreementCancelSchedule());
    }

    private List<Contract> getStartRecordsForRecall(Set<Id> jobIds) {
        List<Contract> recLst = new List<Contract>();

        Map<String, Contract> contractByCode = ICertisRemoveDupCWAsService.getContractsToRecall(jobIds);
        if (!contractByCode.isEmpty()) {
            recLst = contractByCode.values();
        }

        return recLst;
    }

    public class IcertisAgreementRecallBatchException extends Exception {}
}