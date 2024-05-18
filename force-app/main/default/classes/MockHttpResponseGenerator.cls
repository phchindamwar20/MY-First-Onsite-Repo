/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Mock class for Http callout
Test Class:     MockHttpResponseGenerator.cls

History:
When        	Who         		What
20-July-2022	Arpit				Mock class for Http callout

*************************************************************************************/
@isTest
public class MockHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        String SFdomainUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String query='Select+id,CcEmails+from+WorkflowAlert'; 
        HttpResponse res = new HttpResponse();
        if(req.getEndpoint() == SFdomainUrl+'/services/data/v53.0/tooling/query/?q='+query) {
            res.setHeader('Content-Type', 'application/json');
            String json = '{\"size\":95,\"totalSize\":95,\"done\":true,\"queryLocator\":null,\"entityTypeName\":\"WorkflowAlert\",\"records\":[{\"attributes\":{\"type\":\"WorkflowAlert\",\"url\":\"/services/data/v33.0/tooling/sobjects/WorkflowAlert/01W1U000000GxVGUA0\"},\"Id\":\"01W1U000000GxVGUA0\",\"CcEmails\":\"arpit.vashishtha@firstonsite.com\"},{\"attributes\":{\"type\":\"WorkflowAlert\",\"url\":\"/services/data/v33.0/tooling/sobjects/WorkflowAlert/01W1U000000GxVGUA0\"},\"Id\":\"01W1U000000GxVGUA0\",\"CcEmails\":\"arpit.vashishtha@firstonsite.com\"}]}';
            res.setBody(json);
            res.setStatusCode(200);
        } else if(req.getEndpoint().startsWith(SFdomainUrl+'/services/data/v33.0/tooling/sobjects/WorkflowAlert/')) {
            res.setHeader('Content-Type', 'application/json');
            String json=		'{'+
                '  "attributes" : {'+
                '    "type" : "WorkflowAlert",'+
                '    "url" : "/services/data/v53.0/tooling/sobjects/WorkflowAlert/01W1U000000TaxQUAS"'+
                '  },'+
                '  "Id" : "01W1U000000TaxQUAS",'+
                '  "TemplateId" : "00X1U000000qhQtUAI",'+
                '  "CcEmails" : "legal@firstonsite.com.example",'+
                '  "Description" : "Contract Expiration 0 days",'+
                '  "DeveloperName" : "Contract_Expiration_0_days",'+
                '  "SenderType" : "CurrentUser",'+
                '  "ManageableState" : "unmanaged",'+
                '  "NamespacePrefix" : null,'+
                '  "CreatedDate" : "2021-04-09T03:49:39.000+0000",'+
                '  "CreatedById" : "0051U000004spcBQAQ",'+
                '  "LastModifiedDate" : "2021-04-09T03:49:39.000+0000",'+
                '  "LastModifiedById" : "0051U000004spcBQAQ",'+
                '  "EntityDefinitionId" : "Contract",'+
                '  "Metadata" : {'+
                '    "ccEmails" : [ "legal@firstonsite.com.example" ],'+
                '    "description" : "Contract Expiration 0 days",'+
                '    "protected" : false,'+
                '    "recipients" : [ {'+
                '      "field" : null,'+
                '      "recipient" : null,'+
                '      "type" : "accountOwner"'+
                '    }, {'+
                '      "field" : null,'+
                '      "recipient" : null,'+
                '      "type" : "owner"'+
                '    } ],'+
                '    "senderAddress" : null,'+
                '    "senderType" : "CurrentUser",'+
                '    "template" : "Contract_Templates/Contract_Expiration",'+
                '    "urls" : null'+
                '  },'+
                '  "FullName" : "Contract.Contract_Expiration_0_days"'+
                '}';
            res.setBody(json);
            res.setStatusCode(200);
        } else if(req.getEndpoint() == Label.IC_Endpoint + Label.IC_Topic+'/messages') {
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"foo":"bar"}');
            res.setStatusCode(201);
        } else {
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"foo":"bar"}');
            res.setStatusCode(200);
        }
        return res;
    }
}