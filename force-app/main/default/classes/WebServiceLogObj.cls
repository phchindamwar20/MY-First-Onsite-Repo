/**
 * @description       : This is used to log web service request and response callouts in Bolt Logs
 * @author            : Arpit Vashishtha
 * @group             : 
 * @last modified on  : 02-20-2024
 * @last modified by  : Terri Jiles
**/
public class WebServiceLogObj {
    public String endpoint {get;set;}
    public String requestBody {get;set;}
    public String responseBody {get;set;}
    public Integer statusCode {get;set;}
    public String userId {get;set;}
    public String apexClass {get;set;}
    public String methodName {get;set;}
    public String httpMethod {get;set;}
    public String statusMessage {get;set;}
    public String recordType {get;set;}
    public String recordId {get;set;}
    public String ids {get;set;}
    public String objectName {get;set;}
    public Set<Id> setOfIds = new Set<Id>();

    
    public WebServiceLogObj(String userId, String apexClass, String methodName, String httpMethod, String recordId, Set<Id> recordIdSet){ 
        if(recordIdSet != null) {
            this.ids = convertSetToString(recordIdSet);
            this.setOfIds = recordIdSet;
        }//End of if(recordIdsSet != null)
        
        if(recordId != null) {
            String sObjName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
            this.objectName = sObjName;
            this.ids = recordId;
            /*if(sObjName == 'WorkOrder') {
                this.jobId = Id.valueOf(recordId);
            } else if(sObjName == 'Contract') {
                this.contractId = Id.valueOf(recordId);
            }*/
            
            if (this.setOfIds == null || this.setOfIds.isEmpty()) {
                this.setOfIds = new Set<Id>{recordId};
            }
        }
        
        this.userId = userId;
        this.apexClass = apexClass;
        this.methodName = methodName;
        this.httpMethod = httpMethod;
    }

    public WebServiceLogObj(HttpRequest req, HttpResponse res, String userId, String apexClass, String methodName, String httpMethod, String recordId, Set<Id> recordIdSet){
        this(userId, apexClass, methodName, httpMethod, recordId, recordIdSet);
        this.endpoint = req.getEndpoint();
        this.requestBody = req.getBody();
        if(res != null) {
            this.responseBody = res.getBody();
        	this.statusCode = res.getStatusCode();
            this.statusMessage = res.getStatus();
        }//End of if(res != null)
    }

    public void setRequestInfo(HttpRequest req) {
        endpoint = req.getEndpoint();
        requestBody = req.getBody();
    }

    public void setResponseInfo(HttpResponse res) {
        if(res != null) {
            responseBody = res.getBody();
        	statusCode = res.getStatusCode();
            statusMessage = res.getStatus();
        }
    }

    @TestVisible
    private static String convertSetToString(Set<Id> recordIdsSet) {
        String idString='';
        if(recordIdsSet != null && recordIdsSet.size() > 0) {
            if (recordIdsSet != null) {
                Integer maxIt = recordIdsSet.size() - 1;
                List<Id> idLst = new List<Id>(recordIdsSet);
                
                for (Integer i=0 ; i<=maxIt ; i++) {
                    idString += '\''+idLst[i]+'\'';
                    idString += i<maxIt ? ',' : '';
                }//End of for (Integer i=0 ; i<=maxIt ; i++)
            }//End of if (recordIdsSet != null) 
        }//End of if(recordIdsSet != null && recordIdsSet.size() > 0)
        return idString;
    }//End of convertSetToString method
}