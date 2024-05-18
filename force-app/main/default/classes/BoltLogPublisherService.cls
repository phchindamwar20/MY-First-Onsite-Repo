/**
 * @description       : This post bolt events to create a bolt log
 *                         TODO:  This needs to be refactored to clean it up
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-30-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class BoltLogPublisherService {
    private static List<Bolt_Event__e> boltEventLst = new List<Bolt_Event__e>();

    public static void publishBoltErrorEvent(Integer statusCode, String responseBody, String requestBody, String integrationDirection, String method, Set<Id> ids, String className) {
        Bolt_Event__e be = new Bolt_Event__e();
        String idString='';

        if (ids != null) {
            Integer maxIt = ids.size() - 1;
            List<Id> idLst = new List<Id>(ids);

            for (Integer i=0 ; i<=maxIt ; i++) {
                idString += '\''+idLst[i]+'\'';
                idString += i<maxIt ? ',' : '';

                if (be.Object__c == null && idLst[i] != null) {
                    be.Object__c=String.valueOf(idLst[0].getSObjectType());
                }
            }
        }

        be.Status_Code__c=statusCode;
        be.Status_Message__c=responseBody;
        be.Request_Body__c=requestBody;
        be.Apex_Class__c=className;
        be.Apex_Method__c=method;
        be.Ids__c=idString;
        be.Record_Type__c=BoltConstants.RT_BL_ERROR;
        be.Integration_Direction__c=integrationDirection;
        be.Type__c=setTypeByKeywordMatch(responseBody);

        System.debug('~~~~BoltErrorPublisher::publishBoltErrorEvent: be - ' + be);
        
        //List<Bolt_Event__e> boltEventLst = new List<Bolt_Event__e>();
        boltEventLst.add(be);

        List<Database.SaveResult> results = EventBus.publish(boltEventLst);
        boltEventLst.clear();
    }

    public static void publishBoltMultipleErrorEvents(List<Integer> statusCodeLst, List<String> errorMsgLst, List<String> recordLst, String integrationDirection, String method, List<Id> idLst, String className) {
        //List<Bolt_Event__e> boltEventLst = new List<Bolt_Event__e>();
        for (Integer i=0 ; i < idLst.size() ; i++) {
            Bolt_Event__e be = new Bolt_Event__e();

            be.Status_Code__c=statusCodeLst[i];
            be.Status_Message__c=errorMsgLst[i];
            be.Request_Body__c=recordLst[i];
            be.Apex_Class__c=className;
            be.Apex_Method__c=method;
            be.Ids__c=idLst[i];
            be.Record_Type__c=BoltConstants.RT_BL_ERROR;
            be.Integration_Direction__c=integrationDirection;
            be.Type__c=setTypeByKeywordMatch(errorMsgLst[i]);
        
            if (idLst[i] != null) {
                be.Object__c=String.valueOf(idLst[i].getSObjectType());
            }

            System.debug('~~~~BoltErrorPublisher::publishBoltMultipleErrorEvents: be - ' + be);
            
            boltEventLst.add(be);
        }

        List<Database.SaveResult> results = EventBus.publish(boltEventLst);
        boltEventLst.clear();
    }

    public static void publishBoltIntegrationOffEvent(String requestBody, String integrationDirection, String method, String className) {
        Bolt_Event__e be = new Bolt_Event__e();

        be.Status_Message__c=System.Label.BOLT_INTEGRATION_OFF;
        be.Request_Body__c=requestBody;
        be.Apex_Class__c=className;
        be.Apex_Method__c=method;
        be.Record_Type__c=BoltConstants.RT_BL_INTEGRATION_OFF;
        be.Integration_Direction__c=integrationDirection;

        System.debug('~~~~BoltErrorPublisher::publishBoltIntegrationOffEvent: be - ' + be);
        
        //List<Bolt_Event__e> boltEventLst = new List<Bolt_Event__e>();
        boltEventLst.add(be);

        List<Database.SaveResult> results = EventBus.publish(boltEventLst);
        boltEventLst.clear();
    }    
    

    public static void generateWebExceptionForICertis(Exception exceptionObj, Set<Id> ids, WebServiceLogObj wslo) {
        Bolt_Event__e boltEventObj = new Bolt_Event__e();
        boltEventObj = configureBoltEventFromException(wslo.apexClass, wslo.methodName, exceptionObj, ids, boltEventObj, ICertisConstants.SF_TO_ICERTIS);
        boltEventObj = configureBoltEventFromWebServiceLogObj(wslo, boltEventObj, ICertisConstants.SF_TO_ICERTIS);
        boltEventLst.add(boltEventObj);
        List<Database.SaveResult> results = EventBus.publish(boltEventLst);
        boltEventLst.clear();
    }

    //TODO:  Refactor this later...
    public static void generateNewExceptionLogEntries(String className, String methodName, Exception exceptionObj, Set<Id> ids) {
        Bolt_Event__e boltEventObj = new Bolt_Event__e();
        boltEventObj = configureBoltEventFromException(className, methodName, exceptionObj, ids, boltEventObj, ICertisConstants.SF_TO_ICERTIS);

        //List<Bolt_Event__e> boltEventLst = new List<Bolt_Event__e>();
        boltEventLst.add(boltEventObj);
		System.debug('boltEventLst:::'+boltEventLst);
        List<Database.SaveResult> results = EventBus.publish(boltEventLst);
        //System.debug('Error results:::'+results);
        boltEventLst.clear();
    }

    public static void generateHttpLogEntries(List<WebServiceLogObj> webServiceObjList) {
        List<Bolt_Event__e> httpLogList = new List<Bolt_Event__e>();
        System.debug('webServiceObjList:::'+webServiceObjList);
        for(WebServiceLogObj wrapObj : webServiceObjList) {
            System.debug('wrapObj:::'+wrapObj);
            Bolt_Event__e webServiceObj = new Bolt_Event__e();
            webServiceObj = configureBoltEventFromWebServiceLogObj(wrapObj, webServiceObj, ICertisConstants.SF_TO_ICERTIS);

            webServiceObj.Type__c = setTypeByKeywordMatch(wrapObj.responseBody);
            System.debug('wrapObj.objectName:::'+wrapObj.objectName);
            System.debug('wrapObj.ids:::'+wrapObj.ids);
            System.debug('webServiceObj.Type__c:::'+webServiceObj.Type__c);
            httpLogList.add(webServiceObj);
        }//End of for(WebServiceLogObj wrap : webServiceObjList)
        System.debug('httpLogList:::'+httpLogList);
        if(httpLogList.size() > 0) {
            List<Database.SaveResult> results = EventBus.publish(httpLogList);
            //System.debug('results:::'+results);
        }//End of if(httpLogList.size() > 0)
        
    }//End of generateHttpLogEntries method

    public static void publishErrorsByJobId(Map<Id, List<Database.Error>> errorLstByJobId, String className, String methodName, String recordTypeName) {
        List<Bolt_Event__e> boltEventLst = new List<Bolt_Event__e>();

        for (Id thisId : errorLstByJobId.keySet()) {
            String sObjName = thisId.getSObjectType().getDescribe().getName();
            for (Database.Error err : errorLstByJobId.get(thisId)) {
                Bolt_Event__e be = new Bolt_Event__e();

                be.Status_Message__c=System.Label.BOLT_INTEGRATION_OFF;
                be.Apex_Class__c=className;
                be.Apex_Method__c=methodName;
                be.Record_Type__c=recordTypeName;
                be.Type__c=setTypeByKeywordMatch(err.getMessage());
                be.Exception_Message__c=String.valueOf(err.getStatusCode());
                be.Ids__c=thisId;
            }
        }
        List<Database.SaveResult> results = EventBus.publish(boltEventLst);
    }

    private static Bolt_Event__e configureBoltEventFromException(String className, String methodName, Exception exceptionObj, Set<Id> ids, Bolt_Event__e boltEventObj, String integrationDirection) {
        String idString='';
        
        if (ids != null) {
            Integer maxIt = ids.size() - 1;
            List<Id> idLst = new List<Id>(ids);
            
            for (Integer i=0 ; i<=maxIt ; i++) {
                idString += '\''+idLst[i]+'\'';
                idString += i<maxIt ? ',' : '';
            }

            if (idLst[0] != null && boltEventObj.Object__c == null) {
                boltEventObj.Object__c=String.valueOf(idLst[0].getSObjectType());
            }
        }

        boltEventObj.Apex_Class__c = className;
        boltEventObj.Ids__c = idString;
        if(exceptionObj.getMessage().length() >= 131070) {
            boltEventObj.Exception_Message__c = exceptionObj.getMessage().substring(0, 131070);
        } else {
            boltEventObj.Exception_Message__c = exceptionObj.getMessage();
        }
        boltEventObj.Apex_Method__c = methodName;
        if(exceptionObj.getStackTraceString().length() >= 131070) {
            boltEventObj.Stack_Trace__c = exceptionObj.getStackTraceString().substring(0, 131070);
        } else {
            boltEventObj.Stack_Trace__c = exceptionObj.getStackTraceString();
        }
        boltEventObj.Exception_Type__c = exceptionObj?.getTypeName();
        boltEventObj.Record_Type__c = ICertisConstants.ICERTIS_ERROR;
        boltEventObj.Integration_Direction__c = integrationDirection;
        boltEventObj.Type__c = boltEventObj.Type__c != null ? boltEventObj.Type__c : setTypeByKeywordMatch(exceptionObj.getMessage());

        return boltEventObj;
    }

    private static Bolt_Event__e configureBoltEventFromWebServiceLogObj(WebServiceLogObj wslo, Bolt_Event__e boltEventObj, String integrationDirection) {
        boltEventObj.Http_Method__c = wslo.httpMethod;
        boltEventObj.Apex_Class__c = wslo.apexClass;
        if(wslo.endpoint != null && wslo?.endpoint.length() >= 131070) {
            boltEventObj.Endpoint__c = wslo?.endpoint.substring(0, 131070);
        } else if (wslo.endpoint != null) {
            boltEventObj.Endpoint__c = wslo?.endpoint;
        }
        boltEventObj.Apex_Method__c = wslo?.methodName;
        boltEventObj.Request_Body__c = wslo?.requestBody;
        boltEventObj.Response_Body__c = wslo?.responseBody;
        boltEventObj.Status_Message__c = wslo?.statusMessage;
        boltEventObj.Status_Code__c = wslo?.statusCode != null ? Decimal.valueOf(wslo?.statusCode) : null;
        boltEventObj.User__c = wslo?.userId;
        boltEventObj.Record_Type__c = boltEventObj.Record_Type__c != null ? boltEventObj.Record_Type__c : wslo?.recordType;
        boltEventObj.Integration_Direction__c = integrationDirection;
        
        if(wslo.ids != null) {
            if(wslo?.ids.length() >= 131070) {
                boltEventObj.Ids__c = wslo?.ids.substring(0, 131070);
            } else {
                boltEventObj.Ids__c = wslo?.ids;
            }    
        }
        
        //assumes all ids are of the same type
        if (boltEventObj.Object__c == null) {
            if (wslo.setOfIds != null) {
                for (Id thisId : wslo.setOfIds) {
                    if (boltEventObj.Object__c == null && thisId != null) {
                        boltEventObj.Object__c = String.valueOf(thisId.getSObjectType());
                    }
                }
            } else if (wslo.recordId != null) {
                boltEventObj.Object__c = String.valueOf(((Id)wslo.recordId).getSObjectType());
            }
        }
        boltEventObj.Type__c = boltEventObj.Type__c != null ? boltEventObj.Type__c : setTypeByKeywordMatch(wslo?.responseBody);
        
        return boltEventObj;
    }
    
    @TestVisible
    private static String setTypeByKeywordMatch(String errorMsg) {
        String boltErrorType=null, defaultErrorType=null;
        Boolean breakFromLoop = false;

        for (Bolt_Integration_Error_Type__mdt bie : [SELECT Priority__c, Keyword_Match__c, Bolt_Error_Type__c, Default__c FROM Bolt_Integration_Error_Type__mdt ORDER BY Priority__c]) {
            if (errorMsg.contains(bie.Keyword_Match__c)) {
                boltErrorType=bie.Bolt_Error_Type__c;
                breakFromLoop = true;
            }
            if (bie.Default__c == true) {
                defaultErrorType=bie.Bolt_Error_Type__c;
            }
            if (breakFromLoop) 
                break;
        }

        boltErrorType = boltErrorType != null ? boltErrorType : defaultErrorType;

        return boltErrorType;
    }
}