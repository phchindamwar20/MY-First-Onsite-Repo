/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Address Validation Class, which is used to validate address using Experian API.
Class:          AddressValidationController.cls
Test Class:     AddressValidationControllerTest.cls

History:
When            Who                 What
13-June-2022    Arpit               Refactored the class, introduced the namespace credentials.

*************************************************************************************/
global with sharing class AddressValidationController {
    @AuraEnabled
    global static String getSuggestions(String input, String countryISO, String dataset, String maxSuggestion) {
        if(countryISO == null) countryISO = 'USA';
        if(dataset == null) dataset = 'us-address';
        if(maxSuggestion == null) maxSuggestion = '5';
        String url = 'callout:ExperianAPI'+Label.EXPERIAN_SEARCH_ENDPOINT;
        //String body = '{"country_iso": "'+countryISO+'","datasets": ["'+dataset+'"],"max_suggestions": '+maxSuggestion+',"components": {"unspecified": ["'+input+'"]},"options": [{"name": "search_type","value": "intuitive"},{"name": "prompt_set","value": "default"},{"name": "flatten","value": "true"},{"name": "intensity","value": "close"}]}';
        String body = '{"country_iso": "'+countryISO+'","datasets": ["'+dataset+'"],"max_suggestions": '+maxSuggestion+',"components": {"unspecified": ["'+input+'"]}}';
        String response = getResponse(url,body);
        return response;
    }
    
    @AuraEnabled
    global static String getPlaceDetails(String placeId) {
        //Old value of label: /suggestions/stepin/v1/
        String url = 'callout:ExperianAPI'+Label.EXPERIAN_APERTURE_PLACE+placeId;
        String response = getResponse(url,null);
        return response;
    }
    
    global static String getResponse(String strURL,String body){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        if(body!=null) {
            req.setBody(body);
            req.setMethod('POST');
        } else {
            req.setMethod('GET');
        }
        req.setEndpoint(strURL);
        req.setTimeout(120000);
        req.setHeader('Auth-Token', '{!$Credential.Password}');//'$callout:experianAPI.password'
        req.setHeader('Content-Type', 'application/json');
        SYstem.debug('req:::'+req);
        res = h.send(req); 
        SYstem.debug('res:::'+res);
        String responseBody = res.getBody();
        return responseBody;   
    }
}