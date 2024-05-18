@IsTest
public class CreateUserWrapperTest {
	
	static testMethod void testParse() {
		String json = '{ '+
		''+
		'    \"Data\": { '+
		''+
		'        \"Administrator\": false, '+
		''+
		'        \"OrganizationUnitPath\": \"/firstonsite\", '+
		''+
		'        \"LastName\": \"User1\", '+
		''+
		'        \"FirstName\": \"New External\", '+
		''+
		'        \"FullName\": \"New External User1\", '+
		''+
		'        \"TypeOfUser\": \"External\", '+
		''+
		'        \"IsUserPhoneConsentAcknowledged\": null, '+
		''+
		'        \"ExternalUPN\": \"testuser1@test.com\", '+
		''+
		'        \"EmailID\": \"testuser1@test.com\", '+
		''+
		'        \"Status\": \"Provisioned\" '+
		''+
		'    } '+
		''+
		'}';
		CreateUserWrapper obj = CreateUserWrapper.parse(json);
		System.assert(obj != null);
	}
}