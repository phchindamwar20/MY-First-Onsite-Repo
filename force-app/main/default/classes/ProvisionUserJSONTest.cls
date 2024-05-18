@IsTest
public class ProvisionUserJSONTest {
	
	static testMethod void testParse() {
		String json = '{'+
		'  \"EventType\": \"UserInformation\",'+
		'  \"EntityId\": null,'+
		'  \"InstanceId\": null,'+
		'  \"FromState\": null,'+
		'  \"ToState\": null,'+
		'  \"Action\": null,'+
		'  \"User\": null,'+
		'  \"TimeStamp\": \"2022-06-09T11:33:12\",'+
		'  \"Data\": {'+
		'    \"DistributionGroup\": ['+
		'      {'+
		'        \"Name\": \"ExternalUPN Group3\"'+
		'      }'+
		'    ],'+
		'    \"OrgGroup\": ['+
		'      {'+
		'        \"Name\": \"\"'+
		'      }'+
		'    ],'+
		'    \"SecurityGroup\": ['+
		'      {'+
		'        \"Name\": \"View Access\"'+
		'      }'+
		'    ],'+
		'    \"Team\": ['+
		'      {'+
		'        \"PrimaryOwner\": \"9B2409CA-C718-4D24-8D02-8C9DD199CEA2\"'+
		'      },'+
		'      {'+
		'        \"SecondaryOwner\" : \"5811f6d3-123e-4996-ad42-409d0f0835a8\"'+
		'      }'+
		'    ],'+
		'    \"OrganizationUnit\": ['+
		'      {'+
		'        \"Name\": \"FIRSTONSITE\"'+
		'      }'+
		'    ],'+
		''+
		'    \"EmailID\": \"test1@test.com\",'+
		'    \"ExternalUPN\": \"test1@test.com\",'+
		'    \"FirstName\": \"Test1\",'+
		'    \"LastName\": \"Test1\",'+
		'    \"Administrator\": \"false\",'+
		'    \"TypeOfUser\": \"Internal\",'+
		'    \"Action\": \"Provision\",'+
		'    \"SalesforceUserId\" : \"0051U000005pCiS\",'+
		'    \"Title\" : \"Manager\"'+
		'  }'+
		'}';
		ProvisionUserJSON obj = ProvisionUserJSON.parse(json);
		System.assert(obj != null);
	}
}