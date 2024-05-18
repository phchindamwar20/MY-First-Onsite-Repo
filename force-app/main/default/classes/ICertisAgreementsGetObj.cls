/**
 * @description       : This is the Agreement object returned back from an GET Agreements iCertis callout
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-17-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class ICertisAgreementsGetObj {
    public List<Message> Messages;
    public List<DataItem> Data;
    public Boolean HasMoreData;
    public PagingDataItem PagingData;

    public ICertisAgreementsGetObj() {}

    public static ICertisAgreementsGetObj parse(String json) {
		return (ICertisAgreementsGetObj) System.JSON.deserialize(json, ICertisAgreementsGetObj.class);
	}

    public class Message {
        public String BaseErrorCode;
        public String Field;
        public String Message;
        public Integer MessageCode;
    }

    public class DataItem {
        public String contractTypeName;
        public String DisplayName;
        public Date effectiveDate;
        public Date executionDate;
        public Date expiryDate;
        public Boolean isAmendment;
        public String name;
        public String status;
        public Datetime eTag;
        public String ICMAgreementCode;
        public String id;
        public Boolean isActive;
        public Boolean isDeprecated;
        public Boolean isPrivate;
        public String orgPathId;
        public String sharedOrgPathId;
        public String version;
        public String workflowInstanceId; 
        public String SysId; 
        public String Url;
    }

    public class PagingDataItem {
        public Integer PageNumber;
        public Integer RowsPerPage;
        public Integer TotalNumberOfPages;
        public Integer TotalRowCount;
    }
}