/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Update "additional Emails" in Email Alert with suffix sandbox name.
Class:     		UpdateEmailAlert.cls

History:
When        	Who         		What
28-June-2022	Arpit				Added code for Update "additional Emails" in Email Alert with suffix sandbox name.

*************************************************************************************/
public class UpdateEmailAlert {
    
    //Get WorkflowAlert records using tooling API
    public static void getEmailAlert(){
        
        Map<Id,Map<String,Object>> mapAlertIdWithDetails = new Map<Id,Map<String,Object>>();
            
        String SFdomainUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String sandboxName = EnvironmentHelper.getSandboxName();
        String query='Select+id,CcEmails+from+WorkflowAlert'; //use this query to get Workflow Rule
        try{
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
            req.setHeader('Content-Type', 'application/json');
            req.setEndpoint(SFdomainUrl+'/services/data/v53.0/tooling/query/?q='+query);
            req.setMethod('GET');
            
            Http h = new Http();
            HttpResponse response = h.send(req);
            System.debug('response Body ==> '+response.getBody());
            
            WorkflowAlertWrapper obj = WorkflowAlertWrapper.parse(response.getBody());
            
            for(WorkflowAlertWrapper.Records recObj : obj.records) {
                String recordId = recObj.Id;
                String SingleAlertUrl = recObj.attributes.url;
                if(String.isNotBlank(recordId) && String.isNotBlank(recObj.CcEmails)){
                    getSingleEmailAlert(SFdomainUrl+SingleAlertUrl, mapAlertIdWithDetails, sandboxName);
                }//End of if    
            }//End of for(WorkflowAlertWrapper.Records recObj : obj.records)
            
            System.debug('mapAlertIdWithDetails ==>' + mapAlertIdWithDetails);
            System.debug('mapAlertIdWithDetails.size() ==>' + mapAlertIdWithDetails.Size());
            updateUsingMetadataAPI(mapAlertIdWithDetails);
            
        }catch(Exception e){
            System.debug('Error::'+e.getStackTraceString() + '====' + e.getMessage());
        }
    }
    
    //Get details of single WorkflowAlert using tooling API
    public static void getSingleEmailAlert(String alertUrl, Map<Id,Map<String,Object>> mapAlertIdWithDetails, String sandboxName){
        String mergeCCEmailAfterUpdation ='';
        String alertDetails = '';
        
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(alertUrl);
        req.setMethod('GET');
        
        Http h = new Http();
        HttpResponse response = h.send(req);
        
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(response.getBody()); 
		
        String Id = (String)result.get('Id');
        String fullName = (String)result.get('FullName');
        
        // add suffix "." sandbox name to ccEmail
        Map<String,Object> result_Metadata = (Map<String,Object>)result.get('Metadata');
        SYstem.debug('result_Metadata:::'+result_Metadata);
        List<String> list_ccEmails = new List<String>();
        String additionalEmails = '';
        for(Object ccEmail :(List<Object>)result_Metadata.get('ccEmails')){
            String ccEmailWithComma = (String)ccEmail;
            if(ccEmailWithComma.contains(',')) {
                ccEmailWithComma = ccEmailWithComma.removeEnd(',');
            }
            if(ccEmailWithComma.contains(';')) {
                ccEmailWithComma = ccEmailWithComma.removeEnd(';');
            }
            if(String.isBlank(additionalEmails)) {
                additionalEmails = ccEmailWithComma+'.'+sandboxName;
            } else {
                additionalEmails += ',' + ccEmailWithComma+'.'+sandboxName;
            }
            list_ccEmails.add(ccEmailWithComma+'.'+sandboxName);
        }
		
        result_Metadata.put('ccEmails',list_ccEmails);// ccEmail in metadata Map
        result_Metadata.put('FullName',fullName);// create fullName in metadata Map so as to avoid unnecessary values from main Map
        
        mapAlertIdWithDetails.put(Id, result_Metadata);
        
    }
    
    //Bulk update WorkflowAlert using Metadata API
    public static void updateUsingMetadataAPI(Map<Id, Map<String,Object>> mapAlertIdWithDetails){
        List<MetadataService.Metadata> allMetadataList = new List<MetadataService.Metadata>();
        
        if(mapAlertIdWithDetails != null && mapAlertIdWithDetails.size()>0){
            for(Id record_Id : mapAlertIdWithDetails.keySet()){
                Map<String,Object> map_AlertMetadataDetails = mapAlertIdWithDetails.get(record_Id);
                
                System.debug(record_Id);
                System.debug(map_AlertMetadataDetails);
                
                // Store values in WorkflowAlert Metadata
                MetadataService.WorkflowAlert obj_WorkflowAlert = new MetadataService.WorkflowAlert();
                obj_WorkflowAlert.ccEmails = (List<String>)map_AlertMetadataDetails.get('ccEmails');
                obj_WorkflowAlert.fullName = (String)map_AlertMetadataDetails.get('FullName');
                obj_WorkflowAlert.senderType = (String)map_AlertMetadataDetails.get('senderType');
                obj_WorkflowAlert.description = (String)map_AlertMetadataDetails.get('description');
                obj_WorkflowAlert.template = (String)map_AlertMetadataDetails.get('template');
                obj_WorkflowAlert.protected_x = (Boolean)map_AlertMetadataDetails.get('protected');
                obj_WorkflowAlert.senderAddress =(String)map_AlertMetadataDetails.get('senderAddress');
                
                // Fetch recipient Values from Map
                List<MetadataService.WorkflowEmailRecipient> list_recipients = new List<MetadataService.WorkflowEmailRecipient>();
                for(Object obj_Recipients :(List<Object>)map_AlertMetadataDetails.get('recipients')){
                    Map<String,Object> rMap = (Map<String,Object>)obj_Recipients;
                    MetadataService.WorkflowEmailRecipient recipients = new MetadataService.WorkflowEmailRecipient();
                    recipients.field = (String)rMap.get('field');
                    recipients.recipient = (String)rMap.get('recipient');
                    recipients.type_x = (String)rMap.get('type');
                    list_recipients.add(recipients);
                }
                
                obj_WorkflowAlert.recipients = list_recipients;
                System.debug(obj_WorkflowAlert);
                
                allMetadataList.add(obj_WorkflowAlert);
            }
            
            Database.executeBatch(new UpdateMetadataBatch(allMetadataList),10);
        }//End of if(mapAlertIdWithDetails != null && mapAlertIdWithDetails.size()>0)
    }//End of updateUsingMetadataAPI method
}