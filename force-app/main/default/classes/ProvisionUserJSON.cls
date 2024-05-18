/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Wrapper class for Provision user response from ICI
Class:     		ProvisionUserJSON.cls

History:
When        	Who         		What
24-June-2022	Arpit				Added code for Wrapper class for De-provision user response from ICI

*************************************************************************************/
public class ProvisionUserJSON {

	public class DistributionGroup {
		public String Name;
	}
    public class SecurityGroup {
		public String Name;
	}
    public class OrganizationUnit {
		public String Name;
	}

	public class ExtendedUserEntity {
		public String SalesforceUserId;
		public String Title;
	}

	public class Data {
		public List<DistributionGroup> DistributionGroup;
		public List<SecurityGroup> SecurityGroup;
		public List<OrganizationUnit> OrganizationUnit;
		public List<ExtendedUserEntity> ExtendedUserEntity;
		public String EmailID;
		public String ExternalUPN;
		public String FirstName;
		public String LastName;
		public String Administrator;
		public String TypeOfUser;
		public String Action;
		public String Title;
	}

	public String EventType;
	public Object EntityId;
	public Object InstanceId;
	public Object FromState;
	public Object ToState;
	//public Object Action;
	public Object User;
	public String TimeStamp;
	public Data Data;

	
	public static ProvisionUserJSON parse(String json) {
		return (ProvisionUserJSON) System.JSON.deserialize(json, ProvisionUserJSON.class);
	}
}