/**
 * @File Name          : IcertisService.cls
 * @Description        : This calls iCertis business apis Users to 1. verify an iCertis external user exists 2. create or update an external iCertis user 3. find icertis agrements 4. post update to agreement
 *                          documentation on iCertis webservices used in this class found here https://firstonsitedev-business-api.icertis.com/api/swagger/ui/index
 * @Author             : Arpit Vashishtha
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 02-20-2024
 * @Modification Log   :  
 * Ver       Date            Author                 Modification
 * 1.0      10/06/2020        AVashishtha           INITIAL DEVELOPMENT STAR-5366
**/
public without sharing class IcertisService {
    
    //public static List<WebServiceLogObj> logWrapperList = new List<WebServiceLogObj>();

    //method to verify Icertis User, 
    //  1. if user exist by matching on the email and first name/last name the same then do not create it 
    //  2. else if the first name and/or last name changed and it exists, update the user, 
    //  3. else create the user.
    public static List<WorkOrder> verifyICIUserCallout(Set<Id> jobIds) {
        List<WorkOrder> jobUpdLst = new List<WorkOrder>();
        List<WebServiceLogObj> logWrapperList = new List<WebServiceLogObj>();
        try {
            //TODO:  Edge Case Scenario so not likely to happen because we create one agreement at a time - Future: See if iCertis can make the callout to their web service a bulk call.  Salesforce govenor limit is 100 callouts in a transaction.  A Salesforce trigger can process up to 200 records in a transaction 
            List<WorkOrder> workOrderList = [SELECT Id, IC_Bolt_CWA__c, IC_Signatory_Email__c, IC_External_Last_Name__c, IC_External_First_Name__c, Icertis_User_Id__c FROM WorkOrder WHERE Id IN: jobIds];
            String token = generateAzureToken(jobIds, logWrapperList);
            String baseURL = System.Label.ICAPIEndpoint;
            
            for(WorkOrder workOrderObj : workOrderList) {
                WorkOrder job = new WorkOrder(Id=workOrderObj.Id);
                
                try {
                    ICertisUsersGetObj result  = findUserBySignatoryEmail(baseURL, workOrderObj, token, logWrapperList);
                    
                    if (result?.Data != null && !result.Data.isEmpty() && result.Data[0]?.SysId != null) {
                        job.Icertis_User_Id__c = result.Data[0].SysId;
                        
                        if (result.Data[0]?.FirstName != workOrderObj?.IC_External_First_Name__c || result.Data[0]?.LastName != workOrderObj?.IC_External_Last_Name__c) {
                            //do an put to update because the first or last name has changed
                            job.Icertis_User_Id__c = createOrUpdateUser(baseURL, workOrderObj, token, GeneralConstants.PUT, result.Data[0].SysId, logWrapperList);
                        }
                    } else {
                        //do a post to create, user not found
                        job.Icertis_User_Id__c = createOrUpdateUser(baseURL, workOrderObj, token, GeneralConstants.POST, null, logWrapperList);
                    }
                    
                } catch (IcertisServiceException e) {
                    //these are mostly thrown when status not equal to 200 and are already logged, else these are thrown when number of callouts exceeded and we do need to log the error
                    //clear Icertis User id because of error
                    job.Icertis_User_Id__c = null;
                    if (e.getMessage().contains('callouts')) {
                        BoltLogPublisherService.generateNewExceptionLogEntries('IcertisService','verifyICIUserCallout',e,new Set<Id>{workOrderObj.Id});               
                    }
                } catch (Exception e) {
                    //clear Icertis User id because of error
                    //these errors need to be catched AND logged
                    job.Icertis_User_Id__c = null;
                    BoltLogPublisherService.generateNewExceptionLogEntries('IcertisService','verifyICIUserCallout',e,new Set<Id>{workOrderObj.Id});
                } finally {
                    jobUpdLst.add(job);
                }
            }
            if(!logWrapperList.IsEmpty()){
                BoltLogPublisherService.generateHttpLogEntries(logWrapperList);
            }
        } catch (IcertisServiceException e) {
            //do nothing
        } 
        catch(Exception ex) {
            BoltLogPublisherService.generateNewExceptionLogEntries('IcertisService','verifyICIUserCallout',ex,jobIds);
        }
        //BoltLogPublisherService.publishBoltEvents();
        return jobUpdLst;
    }
    
    @TestVisible
    //iCertis callout to verify if the iCertis user exists using the IC Signatory Email
    private static ICertisUsersGetObj findUserBySignatoryEmail(String baseURL, WorkOrder job, String token, List<WebServiceLogObj> logWrapperList) {
        ICertisUsersGetObj result = null;
        if (String.isNotBlank(job.IC_Signatory_Email__c)) {
            String urlWithoutEncode = EncodingUtil.urlEncode('EmailID $eq \'' + String.valueOf(job.IC_Signatory_Email__c) + '\'', 'UTF-8');
            urlWithoutEncode = urlWithoutEncode.replace('+', '%20');
            String jsonBody = CreateUserWrapper.prepareCreateUserBody(job, '');
            HTTPResponse res = sendHttpRequest('findUserBySignatoryEmail', GeneralConstants.GET, '', token, baseURL+'/'+ICertisConstants.EP_Users+'?Filter='+urlWithoutEncode, job.Id, null, logWrapperList);  
            if(res.getStatusCode() == 200) {
                result = ICertisUsersGetObj.parse(res.getBody()); 
            } else {
                throw new IcertisServiceException('An error occurred while making an iCertis callout to find user by signatory email - ' + res.getBody());
            }
        } 
        return result;
    }

    @TestVisible
    //iCertis callout to create or update an iCertis User
    //If Bolt sends an internal user  email (A person who is in the iCertis system as an internal user), an error will be thrown.
    //An internal user is anyone who is a business user who has a FirstOnsite iCertis account to use the iCertis application (i.e. SF Admin, Legal)
    private static String createOrUpdateUser(String baseURL, WorkOrder job, String token, String method, String sysId, List<WebServiceLogObj> logWrapperList) {
        String jsonBody = CreateUserWrapper.prepareCreateUserBody(job, sysId);
        HTTPResponse response;
        String returnedSyId=null;

        if (method == GeneralConstants.POST) {
            response = sendHttpRequest('createOrUpdateUser', GeneralConstants.POST, jsonBody, token, baseURL+'/'+ICertisConstants.EP_USERS, job.Id, null, logWrapperList);
        } else if (method ==  GeneralConstants.PUT) {
            response = sendHttpRequest('createOrUpdateUser', GeneralConstants.PUT, jsonBody, token, baseURL+'/'+ICertisConstants.EP_USERS+'/'+sysId, job.Id, null, logWrapperList);
        }
        if(response != null) {
            CreateUserWrapper rec = CreateUserWrapper.parse(response.getBody());  
            if (response.getStatusCode() >= 200 && response.getStatusCode() < 299) {
                returnedSyId = rec.Data.Id;                
            } else {
                throw new IcertisServiceException('An error occurred while attempting to create or Update iCertis user via web service callout ' + response.getBody());
            }
        }
        return returnedSyId;
    }

    
    //Future method to send agreement for signing
    public static Map<Id, Contract> sendAgreementForSigning(Set<Id> agreementIdSet) {
        Map<Id, Contract> contractById = new Map<Id, Contract>();
        List<WebServiceLogObj> logWrapperList = new List<WebServiceLogObj>();
        String token = generateAzureToken(agreementIdSet, logWrapperList);
        System.debug('~~~~ IcertisService::sendAgreementForSigning: token in sendAgreementForSigning:::'+token);
        String baseURL = System.Label.ICAPIEndpoint;
        ICertisAgreementsGetObj agreementFind =  null; 
        ICertisAgreementsPostPutObj agreementForSignature = null;
        
        for (Contract contractObj:  [SELECT Id, IC_Agreement_Code__c FROM Contract WHERE Id IN: agreementIdSet]) {
            //find iCertis agreement
            agreementFind = findAgreementsByICAgrementCode(baseURL, contractObj, token, logWrapperList);

            if(agreementFind.Data[0]?.SysId != null) {
                //post action to send for signature
                agreementForSignature = sendAgreementOfIcmCWAtypeForSignatory(baseURL, contractObj, token, agreementFind.Data[0].sysId, logWrapperList);
                System.debug('~~~~ IcertisService::sendAgreementForSigning: agreementForSignature.getBody() ' + Json.serializePretty(agreementForSignature));
                contractById.put(contractObj.Id, new Contract(Id=contractObj.Id, IC_Esign_Date__c=System.now()));

            } else {
                throw new ICertisServiceException('iCertis Agreement not found for IC Agreement Code, ' + contractObj.IC_Agreement_Code__c + '  As a result, unable to sent for external signature.');
            }
        }

        if(!logWrapperList.IsEmpty()) {
            BoltLogPublisherService.generateHttpLogEntries(logWrapperList);
        }

        return contractById;
    }

    @TestVisible
    //iCertis callout to verify if the iCertis user exists using the IC Signatory Email
    private static ICertisAgreementsGetObj findAgreementsByICAgrementCode(String baseURL, Contract contractObj, String token, List<WebServiceLogObj> logWrapperList) {
        ICertisAgreementsGetObj result = null;

        if(String.isNotBlank(contractObj.IC_Agreement_Code__c)) {
            String urlWithoutEncode = EncodingUtil.urlEncode('ICMAgreementCode $eq \'' + String.valueOf(contractObj.IC_Agreement_Code__c) + '\'', 'UTF-8');
            urlWithoutEncode = urlWithoutEncode.replace('+', '%20');
            String endURL = '?Filter='+urlWithoutEncode + '&Select=sysId,ICMAgreementCode,Name,Status';
        
            result = getICertisAgreementsCallout(baseURL, token, ICertisConstants.CTN_ICMCWA, endURL, contractObj.Id, null, logWrapperList);
        }

        return result;
    }
    

    @TestVisible
    //iCertis callout to verify if the iCertis user exists using the IC Signatory Email
    private static ICertisAgreementsPostPutObj sendAgreementOfIcmCWAtypeForSignatory(String baseURL, Contract contractObj, String token, String sysId, List<WebServiceLogObj> logWrapperList) {
        String endURL = sysId+'/actions/Send%20For%20External%20Signature';
        ICertisAgreementsPostPutObj result = postOrPutAgreementCallout (baseURL, token, ICertisConstants.CTN_ICMCWA, endURL, GeneralConstants.POST, contractObj.Id, logWrapperList);

        return result;
    }

    public static ICertisAgreementsGetObj getICertisAgreementsCallout(String baseURL, String token, String contractTypeName, String endURL, String contractId, Set<Id> recordIdSet, List<WebServiceLogObj> logWrapperList) {
        ICertisAgreementsGetObj result = null;
        String endpoint = baseURL+'/'+ICertisConstants.EP_AGREEMENTS+'/'+contractTypeName+endURL;
        
        HTTPResponse res = sendHttpRequest('getICertisAgreementsCallout', GeneralConstants.GET, '', token, endpoint, contractId, recordIdSet, logWrapperList);        

        result = ICertisAgreementsGetObj.parse(res.getBody());

        if (res.getStatusCode() == 200) {
            //Do not do anything
        } else {
            throw new IcertisServiceException('An error occurred while attempting to send an agreement for signatory - ' + res.getBody());
        }

        return result;
    }


    //iCertis callout to post or put an agreement
    public static ICertisAgreementsPostPutObj postOrPutAgreementCallout (String baseURL, String token, String contractTypeName, String endURL, String method, String contractId, List<WebServiceLogObj> logWrapperList) {
        ICertisAgreementsPostPutObj result = null;
        String endpoint = baseURL+'/'+ ICertisConstants.EP_AGREEMENTS +'/'+ICertisConstants.CTN_ICMCWA+'/'+endURL;
        
        HTTPResponse res = sendSigningHttpRequest('postOrPutAgreementCallout', method, '', token, endpoint, contractId, logWrapperList);
        result = ICertisAgreementsPostPutObj.parse(res.getBody());

        if (res.getStatusCode() == 200) {
            //Do not do anything
        } else {
            //TODO:  1. capture response error 2. thorw ICertisServiceException
            throw new IcertisServiceException('An error occurred while attempting to make a callout to iCertis to post or put an agreement - ' + Json.serializePretty(result));
        }

        return result;
    }

    public static HTTPResponse sendHttpRequest(String methodName, String methodType, String jsonBody, String sasToken, String url, String recordId, Set<Id> recordIdSet, List<WebServiceLogObj> logWrapperList) {
        WebServiceLogObj webServiceObj = new WebServiceLogObj(UserInfo.getUserId(),'IcertisService',methodName, methodType, recordId, recordIdSet);
        try {
            if (Limits.getCallouts() < Limits.getLimitCallouts()) {
                HttpRequest req = new HttpRequest();
                
                req.setEndpoint(url);
                req.setMethod(methodType);
                req.setHeader('Accept', '*/*');
                req.setHeader('Authorization', 'Bearer ' + sasToken);
                req.setTimeout(ICertisConstants.CALLOUT_TIMEOUT);
                if((methodType == GeneralConstants.POST || methodType == GeneralConstants.PUT) && String.isNotBlank(jsonBody)) {
                    req.setBody(jsonBody);
                    req.setHeader('Content-Length', String.valueOf(jsonBody.length()));
                    req.setHeader('Content-Type', 'application/json');
                }
                webServiceObj.setRequestInfo(req);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                webServiceObj.setResponseInfo(res);
                
                if(res.getStatusCode() >= 200 && res.getStatusCode() < 299) {
                    webServiceObj.recordType = ICertisConstants.ICERTIS_LOG;
                } else {
                    webServiceObj.recordType = ICertisConstants.ICERTIS_ERROR;
                }
                logWrapperList.add(webServiceObj);
                return res;
            } else {
                //this needs to be added because iCertis callouts to put/postaren't bulkified; salesforce is limited to 100 callouts in a transaction, yet a trigger can handle 200 records
                throw new IcertisServiceException('Can\'t make any more callouts:  made ' + Limits.getCallouts() + ' of ' + Limits.getLimitCallouts() + ' callouts');
            }
        } catch (Exception e) {
            BoltLogPublisherService.generateWebExceptionForICertis(e, new Set<Id>{recordId}, webServiceObj);
            throw new IcertisServiceException('An exception occurred while calling web service ' + methodName, e);
        }
    }//End of sendHttpRequest method
    
    //Method to send the HTTP request to ICI
    public static HTTPResponse sendSigningHttpRequest(String methodName, String methodType, String jsonBody, String sasToken, String url, String recordId, List<WebServiceLogObj> logWrapperList) {
        WebServiceLogObj webServiceObj = new WebServiceLogObj(UserInfo.getUserId(),'IcertisService',methodName, methodType, recordId, null);
        try {
            if (Limits.getCallouts() < Limits.getLimitCallouts()) {
                String baseURL = System.Label.ICAPIEndpoint;
                baseURL = baseURL.subStringAfter('//').subStringBefore('/');
                
                
                HttpRequest req = new HttpRequest();
                
                req.setEndpoint(url);
                req.setMethod(methodType);
                req.setHeader('Authorization', 'Bearer ' + sasToken);
                req.setHeader('Content-Length', '0');
                req.setHeader('Host', baseURL);
                req.setTimeout(ICertisConstants.CALLOUT_TIMEOUT);
                webSErviceObj.setREquestInfo(req);
                Http http = new Http();
                
                HTTPResponse res = http.send(req);
                webSErviceObj.setResponseInfo(res);
                if(res.getStatusCode() == 200) {
                    webServiceObj.recordType = ICertisConstants.ICERTIS_LOG;
                } else {
                    webServiceObj.recordType = ICertisConstants.ICERTIS_ERROR;
                }
                logWrapperList.add(webServiceObj);
                return res;
            } else {
                //this needs to be added because iCertis callouts to put/postaren't bulkified; salesforce is limited to 100 callouts in a transaction, yet a trigger can handle 200 records
                throw new IcertisServiceException('Salesforce can\'t make any more callouts:  made ' + Limits.getCallouts() + ' of ' + Limits.getLimitCallouts() + ' callouts');
            }
        } catch (Exception e) {
            BoltLogPublisherService.generateWebExceptionForICertis(e, new Set<Id>{recordId}, webServiceObj);
            throw new ICertisServiceException('An exception occurred while calling web service ' + methodName, e);
        }
    }//End of sendHttpRequest method
        
    public static String generateAzureToken(Set<Id> jobIds, List<WebServiceLogObj> logWrapperList) {
        WebServiceLogObj webServiceObj = new WebServiceLogObj(UserInfo.getUserId(),'IcertisService','generateAzureToken', 'POST', null, jobIds);
        try {
            if (Limits.getCallouts() < Limits.getLimitCallouts()) {
                String token = '';

                IC_API__c icertisCustomSettingObj = IC_API__c.getOrgDefaults();
                
                HttpRequest req = new HttpRequest();
                
                String tanentId = icertisCustomSettingObj.Tenant_Id__c;
                String clientId = icertisCustomSettingObj.Client_Id__c;
                String clientSecret = icertisCustomSettingObj.Client_Secret__c;
                String jsonBody = 'grant_type=client_credentials&scope=api://'+clientId+'/.default&client_id='+clientId+'&client_secret='+clientSecret;
                
                req.setEndpoint(icertisCustomSettingObj.Azure_Endpoint__c+tanentId+'/oauth2/v2.0/token');        
                req.setMethod(GeneralConstants.POST);
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                req.setHeader('Accept', 'application/json');
                req.setBody(jsonBody);
                req.setTimeout(ICertisConstants.CALLOUT_TIMEOUT);
                webServiceObj.setRequestInfo(req);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                webServiceObj.setResponseInfo(res);
                
                if(res.getStatusCode() == 200) {
                    webServiceObj.recordType = ICertisConstants.ICERTIS_LOG;
                    Map<String, Object> listJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    if(listJson.containsKey('access_token')) {
                        token = String.valueOf(listJson.get('access_token'));
                    }
                } else {
                    webServiceObj.recordType = ICertisConstants.ICERTIS_ERROR;
                }
                logWrapperList.add(webServiceObj);
                        
                return token;
            } else {
                //this needs to be added because iCertis callouts to put/postaren't bulkified; salesforce is limited to 100 callouts in a transaction, yet a trigger can handle 200 records
                throw new IcertisServiceException('Error recevied while atttempting to get generate Azure token.  Salesforce can\'t make any more callouts:  made ' + Limits.getCallouts() + ' of ' + Limits.getLimitCallouts() + ' callouts');
            }
        } catch (Exception e) {
            BoltLogPublisherService.generateWebExceptionForICertis(e, jobIds, webServiceObj);
            throw new IcertisServiceException('Error occurred while generating the Azure Token', e);
        }
    }//End of generateAzureToken method

    public class IcertisServiceException extends Exception {}

}//End of IcertisService class