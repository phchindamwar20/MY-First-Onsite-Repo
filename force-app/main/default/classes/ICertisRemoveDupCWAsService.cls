/**
 * @description       : This contains the maajority of the functionality required to recall and cancel icertis CWA duplicate agreements
 *                         NO DMLs are preformed in this class.  It is expected the calling classes will perform DMLs
 * @author            : Arpit Vashishtha
 * @group             : 
 * @last modified on  : 02-19-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class ICertisRemoveDupCWAsService {
	
    public static List<Contract> recallContracts(List<Contract> contractLst, List<WebServiceLogObj> logWrapperList) {
        List<Contract> recallContractsLst = new List<Contract>();
        Set<Id> contractIdsSet = (new Map<Id,Contract>(contractLst)).keySet().clone();
        
        //get only CWA Jobs's approved contracts where there are multiple contracts AND it has at least one executed contract AND at least one approved contracts
        Map<String, Contract> recallContractByIcaCode = new Map<String, Contract>();
        for (Contract c : contractLst) {
            recallContractByIcaCode.put(c.IC_Agreement_Code__c, c);
        }

        if(!recallContractByIcaCode.isEmpty()) {
            String agreementCodesJson = JSON.serialize(recallContractByIcaCode.keySet()).replace('"','\'');
            String token = IcertisService.generateAzureToken(contractIdsSet, logWrapperList);
            String baseURL = System.Label.ICAPIEndpoint;

            try {
                //make callout to get the iCertis contracts to recall
                ICertisAgreementsGetObj agreementsToRecallObj = findAgreementsByDateWaitingForSignatoryCodes(baseURL, agreementCodesJson, token, contractIdsSet, logWrapperList); 
				if(agreementsToRecallObj != null && agreementsToRecallObj.Data.size() > 0) {
                    for (ICertisAgreementsGetObj.DataItem iCertisAgreement : agreementsToRecallObj.Data) {
                        System.debug('iCertisAgreement:::'+iCertisAgreement);
                        System.debug('recallContractByIcaCode:::'+recallContractByIcaCode);
                        if (!String.isBlank(iCertisAgreement.SysId) && !String.isBlank(iCertisAgreement.ICMAgreementCode) && recallContractByIcaCode.containsKey(iCertisAgreement.ICMAgreementCode)) {
                            Contract contractRec = recallAndSetContract(baseURL, token, iCertisAgreement, recallContractByIcaCode.get(iCertisAgreement.ICMAgreementCode).Id, logWrapperList);
                            if (contractRec != null) {
                                recallContractsLst.add(contractRec);
                            }
                        }
                    }    
                }
            } catch (IcertisService.IcertisServiceException e) {
                BoltLogPublisherService.generateNewExceptionLogEntries('IcertisService','verifyICIUserCallout',e,contractIdsSet); 
            } catch (Exception e) {
                BoltLogPublisherService.generateNewExceptionLogEntries('IcertisService','verifyICIUserCallout',e,contractIdsSet);
            } finally {
                return recallContractsLst;
            }
        }

        return recallContractsLst;
    }



    //search SF database for a list of contract records to potentially recall from iCertis
    //TODO:  Ask Mr. Arpit to create unit test for the scenarios outlined in the excel spreadsheet for this method
    public static Map<String, Contract> getContractsToRecall(Set<Id> jobIds) {
        Map<Id, Integer> numApprovedContractsByJobId = new Map<Id, Integer>();
        Map<Id, Integer> numExecutedContractsByJobId = new Map<Id, Integer>();
        Map<String, Contract> contractToRecallByIcAgreementCode = new Map<String, Contract>();
        Set<String> statues = new Set<String>{ICertisConstants.CS_APPROVED, ICertisConstants.CS_EXECUTED};

        List<WorkOrder> jobList = [SELECT Id, 
                                    (SELECT Id, IC_Agreement_Code__c, Status 
                                        FROM Contracts__r 
                                        WHERE Status IN: statues) 
                                    FROM WorkOrder 
                                    WHERE Id IN: jobIds AND IC_Bolt_CWA__c=true];                            
        
        //get counts of contracts associated with CWA jobs that have statues of Approved or Executed                            
        for(WorkOrder workOrderObj : jobList) {
            Integer numberOfApprovedContracts = 0; 
            Integer numberOfExecutedContracts = 0;

            for(Contract contractObj : workOrderObj.Contracts__r) {
                if(contractObj.Status == ICertisConstants.CS_APPROVED) {
                    numberOfApprovedContracts++;
                }
                if(contractObj.Status == ICertisConstants.CS_EXECUTED) {
                    numberOfExecutedContracts++;
                }
            }
            numApprovedContractsByJobId.put(workOrderObj.Id, numberOfApprovedContracts);
            numExecutedContractsByJobId.put(workOrderObj.Id, numberOfExecutedContracts);
        }

        System.debug('~~~~ IcertisService::getContractsToRecall: numApprovedContractsByJobId:::'+numApprovedContractsByJobId);
        System.debug('~~~~ IcertisService::getContractsToRecall: numExecutedContractsByJobId:::'+numExecutedContractsByJobId);

        for(WorkOrder workOrderObj : jobList) {
            //If there are multiple CWA contracts associated with the job AND
            // there are both Executed AND Approved Contracts, then recall all the approved contracts
            if( workOrderObj.contracts__r?.size() > 1 &&
                numApprovedContractsByJobId?.get(workOrderObj.Id) >= 1 && 
                numExecutedContractsByJobId?.get(workOrderObj.Id) >= 1 ) {
                    for(Contract contractObj : workOrderObj.Contracts__r) {
                        //only get approved contracts for the recall
                        if (contractObj.Status == ICertisConstants.CS_APPROVED) {
                            contractToRecallByIcAgreementCode.put(contractObj.IC_Agreement_Code__c, contractObj);
                        }
                    }
            }
        }
        System.debug('~~~~ IcertisService::getContractsToRecall: recallContractMap:::'+contractToRecallByIcAgreementCode);        

        return contractToRecallByIcAgreementCode;
    }
    

    @TestVisible
    //iCertis callout to find agreements by date and waiting for signatory codes 
    private static ICertisAgreementsGetObj findAgreementsByDateWaitingForSignatoryCodes(String baseURL, String agreementCodesJson, String token, Set<Id> contractIdsSet, List<WebServiceLogObj> logWrapperList) {
        ICertisAgreementsGetObj result = null; 

        if(String.isNotBlank(agreementCodesJson)) {
            DateTime lastModifiedTime = DateTime.now().addDays(-2);
            String lastModifiedTimeStr = lastModifiedTime.format('yyyy/MM/dd 00:00:00');
            lastModifiedTimeStr = lastModifiedTimeStr.replace(' ', 'T');
            lastModifiedTimeStr = lastModifiedTimeStr.replaceAll('/','-');
            
            //String urlWithoutEncode = EncodingUtil.urlEncode('status $eq \'Waiting for External Signature\' $and ModifiedDate $gt \'2023-01-01T00:00:00\' $and ICMAgreementCode $in ' + agreementCodesJson, 'UTF-8');
            String urlWithoutEncode = EncodingUtil.urlEncode('status $eq \'Waiting for External Signature\' $and ModifiedDate $gt \''+lastModifiedTimeStr+'\' $and ICMAgreementCode $in ' + agreementCodesJson, 'UTF-8');
            String endURL = '?Filter='+urlWithoutEncode + '&count=true&Select=sysId,ICMAgreementCode,Name,Status';
         
            result = IcertisService.getICertisAgreementsCallout(baseURL, token, ICertisConstants.CTN_ICMCWA, endURL, null, contractIdsSet, logWrapperList);
        }

        return result;
    }

    @TestVisible
    private static Contract recallAndSetContract (String baseURL, String token, ICertisAgreementsGetObj.DataItem agreement, Id contractId, List<WebServiceLogObj> logWrapperList ) {
        Contract contractToRecall = null;
		//try {
            String sysId = agreement.sysId;
            ICertisAgreementsPostPutObj result = recallAgreementCallout(baseURL, token, sysId, contractId, logWrapperList);
            //contract successfully recalled
            contractToRecall = new Contract(Id=contractId, Ic_SysId__c=sysId, IC_Recalled__c= true);
        /*} catch (Exception e) { 
            //TODO:  log it?
            //since this method is called in a loop, one agreement may of had a problem but not the other in a list

        } */
        return contractToRecall;
    }

    @TestVisible
    //post an action to recall an agreement using the SysId
    private static ICertisAgreementsPostPutObj recallAgreementCallout(String baseURL, String token, String sysId, String contractId, List<WebServiceLogObj> logWrapperList) {
        ICertisAgreementsPostPutObj result = null;
        String endURL = sysId+'/actions/Recall';
        result = IcertisService.postOrPutAgreementCallout(baseURL, token, ICertisConstants.CTN_ICMCWA, endURL, GeneralConstants.POST, contractId, logWrapperList);
		return result;
    }    

    public static List<Contract> cancelContracts(List<Contract> contractLst, List<WebServiceLogObj> logWrapperList) {
        List<Contract> cancelContractLst = new List<Contract>();
        Set<Id> contractIds = (new Map<Id,Contract>(contractLst)).keySet().clone();
        String token = IcertisService.generateAzureToken(contractIds, logWrapperList);
        String baseURL = System.Label.ICAPIEndpoint;
        for(Contract contractObj : contractLst) {
            //Code added to check actions
            String cancelUrl = checkCancelAction(baseURL, contractObj, token, logWrapperList);
            if(String.isNotBlank(cancelUrl)) {
                cancelContractLst.add(cancelContract(cancelUrl, contractObj, token, logWrapperList));
            }
        }

        return cancelContractLst;
    }
    
    @TestVisible
    private static String checkCancelAction(String baseURL, Contract contractObj, String token, List<WebServiceLogObj> logWrapperList) {
        String cancelUrl = null;
        if (String.isNotBlank(contractObj.IC_SysId__c)) {
            ICertisAgreementsGetObj agreement = findAgreementsToCancelBySysId(baseURL, token, contractObj.IC_SysId__c, contractObj.Id, logWrapperList);
            //there are a lot of different types for items, so we need to loop through all of them
            for (ICertisAgreementsGetObj.DataItem item : agreement.Data) { 
                if (item?.DisplayName == 'Cancel' && String.isNotBlank(item?.Url)) {
                    cancelUrl = item.Url;
                }   
            }
        }
        return cancelUrl;
    }

    @TestVisible
    //iCertis callout to find CWA agreement to cancel by sys id
    private static ICertisAgreementsGetObj findAgreementsToCancelBySysId(String baseURL, String token, String sysId, String recordId, List<WebServiceLogObj> logWrapperList) {
        ICertisAgreementsGetObj result = null;
        if(String.isNotBlank(sysId)) {
            String endURL = '/'+sysId+'/actions';
            result = IcertisService.getICertisAgreementsCallout(baseURL, token, ICertisConstants.CTN_ICMCWA, endURL, recordId, null, logWrapperList);
        }
        return result;
    }    
    
    @TestVisible
    private static Contract cancelContract(String cancelUrl, Contract contractObj, String token, List<WebServiceLogObj> logWrapperList) {
        Contract contractTempObj = new Contract(Id = contractObj.Id);
        if (String.isNotBlank(cancelUrl)) {
            ICertisAgreementsPostPutObj agreementToCancel = cancelAgreementCallout(token, cancelUrl, contractObj.Id, logWrapperList);
            contractTempObj.IC_Cancelled__c = true;   
        }
        return contractTempObj;
    }  
    
    @TestVisible
    //post an action to cancel an agreement using the cancelURL
    private static ICertisAgreementsPostPutObj cancelAgreementCallout(String token, String cancelUrl, String contractId, List<WebServiceLogObj> logWrapperList) {
        ICertisAgreementsPostPutObj result = null;
        	SYstem.debug('Inside cancelAgreementCallout');
            HTTPResponse res = IcertisService.sendSigningHttpRequest('cancelAgreementCallout', GeneralConstants.POST, '', token, cancelUrl, contractId, logWrapperList);
            result = ICertisAgreementsPostPutObj.parse(res.getBody());
            
            return result;
            
    }
}