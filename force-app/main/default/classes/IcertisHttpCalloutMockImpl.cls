@isTest
global class IcertisHttpCalloutMockImpl implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if(req.getEndpoint().contains('https://www.loginmicrosoft.com/')) {
            res.setBody('{"example":"test", "access_token":"0987654321" }');
        } else if(req.getEndpoint().contains('/actions/Recall')) {
            res.setBody('{"Messages":null,"Data":{"Id":"70976f9e-ea65-43a3-9e94-a5fb2ed3d66f","RequestCompleted":true},"HasMoreData":false,"PagingData":null}');
        } else if(req.getEndpoint().contains('/actions/Cancel')) {
            res.setBody('{"Messages":null,"Data":[{"Id":"70976f9e-ea65-43a3-9e94-a5fb2ed3d66f","RequestCompleted":true}],"HasMoreData":false,"PagingData":null}');
        } else if(req.getEndpoint().contains('https://canceldummycontract.com')) {
            res.setBody('{"Messages":null,"Data":{"Id":"70976f9e-ea65-43a3-9e94-a5fb2ed3d66f","RequestCompleted":true},"HasMoreData":false,"PagingData":null}');
        } else {
            res.setBody('{"example":"test", "Data": [{"SysId":"xxxx-xxxx", "ICMAgreementCode":"ICMCWA_001","DisplayName":"Cancel","Url":"https://canceldummycontract.com"}] }');
        }
        
        res.setStatusCode(200);
        return res;
    }
}