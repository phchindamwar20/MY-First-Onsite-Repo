/**
 * @description       : This is a partial representation of the JSON in object form returned back from the iCertis service GET /v{version}/users
 *                      utilized by IcertisService class to find if an iCertis user exists using the email
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-08-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class ICertisUsersGetObj {
    public List<Message> Messages;
    public List<DataItem> Data;
    public Boolean HasMoreData;
    public PagingDataItem PagingData;

    public ICertisUsersGetObj() {}

    public static ICertisUsersGetObj parse(String json) {
		return (ICertisUsersGetObj) System.JSON.deserialize(json, ICertisUsersGetObj.class);
	}

    public class Message {
        public String BaseErrorCode;
        public String Field;
        public String Message;
        public Integer MessageCode;
    }

    public class DataItem {
        public String ClauseId;
        public Datetime CreatedDate;
        public String EmailID;
        public String EsignSignatoryAuthentication;
        public String ExtendedEntity;
        public String FirstName;
        public String ICMExternalUser;
        public String Identifier;
        public Boolean IsGroup;
        public String LastName;
        public Datetime ModifiedDate;
        public String PhoneNumber;
        public String RoleDisplayName;
        public String RoleName;
        public String RuleGroup;
        public String Status;
        public Integer StepNumber;
        public String SubRoleDisplayName;
        public String SysId;
        public String TypeOfUser;
        public String UserName;
    }

    public class PagingDataItem {
        public Integer PageNumber;
        public Integer RowsPerPage;
        public Integer TotalNumberOfPages;
        public Integer TotalRowCount;
    }
}