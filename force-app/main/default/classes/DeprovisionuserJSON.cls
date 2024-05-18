/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Wrapper class for De-provision user response from ICI
Class:     		DeprovisionuserJSON.cls

History:
When        	Who         		What
24-June-2022	Arpit				Added code for Wrapper class for De-provision user response from ICI

*************************************************************************************/
public class DeprovisionuserJSON {

	public String EventType;
	public Object EntityId;
	public Object InstanceId;
	public Object FromState;
	public Object ToState;
	public Object Action;
	public Object User;
	public String TimeStamp;
	public Data Data;

	public class Data {
    	public String TypeOfUser;
		public String EmailID;
		public String Action;
	}

	
	public static DeprovisionuserJSON parse(String json) {
		return (DeprovisionuserJSON) System.JSON.deserialize(json, DeprovisionuserJSON.class);
	}
}