/**
 * @description       : Code taken from https://developer.salesforce.com/blogs/developer-relations/2013/03/testing-apex-callouts-using-httpcalloutmock
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-08-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class MultiRequestMock implements HttpCalloutMock {
    
    Map<String, HttpCalloutMock> requests;

    public MultiRequestMock(Map<String, HttpCalloutMock> requests) {
        this.requests = requests;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpCalloutMock mock = requests.get(req.getEndpoint());
        if (mock != null) {
            return mock.respond(req);
        } else {
            throw new MultiRequestMockException('HTTP callout not supported for test methods');
        }
    }

    public void addRequestMock(String url, HttpCalloutMock mock) {
        requests.put(url, mock);
    }

    public class MultiRequestMockException extends Exception {}
}