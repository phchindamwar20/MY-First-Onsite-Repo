/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Mock class for MetadataService callout
Test Class:     MockHttpResponseGenerator.cls

History:
When        	Who         		What
20-July-2022	Arpit				Mock class for MetadataService callout

*************************************************************************************/
global with sharing class CallOutMock implements WebServiceMock{
    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType) {
            MetadataService.updateMetadataResponse_element metadataResponse = new MetadataService.updateMetadataResponse_element();
            MetadataService.SaveResult saveresult = new MetadataService.SaveResult();
            saveresult.errors = new List<MetadataService.Error>();
            saveresult.errors.add(new MetadataService.Error());
            saveresult.fullName = 'TestApp';
            saveresult.success = true;
            metadataResponse.result = new List<MetadataService.SaveResult>();
            metadataResponse.result.add(saveresult);
            response.put('response_x', metadataResponse); 
        }
}