/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Test class for AddressValidationController.cls
Test Class:     AddressValidationControllerTest.cls

History:
When        	Who         		What
13-June-2022	Arpit				Refactored the test class.

*************************************************************************************/
@isTest
public class AddressValidationControllerTest {    
    @isTest
    static void validateGetSuggestions() {
        Test.startTest();
        //Setting Mock class to return the response as per the API response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String searchString = '201 Sussex St', latitude = '0.00', longitude = '0.00', sToken = 'abc123', filters = 'US,AU';
        String searchResults = AddressValidationController.getSuggestions('12345','USA','us-dataset','5');
        System.assertNotEquals(null, searchResults);
        //System.assertEquals('{"name":"postcode"}', searchResults);
        System.assertEquals('{"foo":"bar"}', searchResults);
        Test.stopTest();
    }
    @isTest
    static void validateGetPlaceDetails() {
        Test.startTest();
        //Setting Mock class to return the response as per the API response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String placeId = 'ChIJ9Rr6fhsUyYcRtMLEzbOtijM';
        String searchResults = AddressValidationController.getPlaceDetails(placeId);
        System.assertNotEquals(null, searchResults);
        //System.assertEquals('{"value":"12345-6000"}', searchResults);
        System.assertEquals('{"foo":"bar"}', searchResults);
        Test.stopTest();
    }
}