/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Update "additional Emails" in Email Alert with suffix sandbox name in Batch.
Class:     		UpdateMetadataBatch.cls
Test Class:		UpdateEmailAlertTest.cls

History:
When        	Who         		What
29-July-2022	Arpit				INITIAL DEVELOPMENT

*************************************************************************************/
public class UpdateMetadataBatch implements Database.AllowsCallouts,Database.Batchable<MetadataService.Metadata>{
    
    public List <MetadataService.Metadata> metadataList = new List<MetadataService.Metadata>();
    
    public UpdateMetadataBatch(List<MetadataService.Metadata> allMetadataList){
        metadataList = allMetadataList;          
    }
    
    public Iterable<MetadataService.Metadata> start(Database.BatchableContext BC){
        return metadataList;
    }
    
    public void execute(Database.BatchableContext BC, List<MetadataService.Metadata> scope) {
        MetadataService.MetadataPort service = createService();
        List<MetadataService.SaveResult> results = service.updateMetadata(scope);
        handleSaveResults(results);
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
    
    //Handle bulk update result
    private static void handleSaveResults(List<MetadataService.SaveResult> list_SaveResult){
        for(MetadataService.SaveResult saveResult: list_SaveResult){
            if(saveResult==null || saveResult.success){
                return;
            }
            // Construct error message and throw an exception
            List<String> messages = new List<String>();
            messages.add((saveResult.errors.size()==1 ? 'Error ' : 'Errors ') + 'occured processing component ' + saveResult.fullName + '.');
            for(MetadataService.Error error : saveResult.errors){
                messages.add(error.message + ' (' + error.statusCode + ').' + ( error.fields!=null && error.fields.size()>0 ? ' Fields ' + String.join(error.fields, ',') + '.' : '' ) );
            }
            if(messages.size()>0){
                //throw new MetadataServiceUtileException(String.join(messages, ' '));
            }
        }
    } 
    
    //Get sessionId
    private static MetadataService.MetadataPort createService(){ 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;     
    }
}