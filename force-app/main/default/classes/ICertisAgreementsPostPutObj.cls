/**
 * @description       : This is the response class for the iCertis Post/Put Agreements service
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 01-12-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class ICertisAgreementsPostPutObj {
    public List<Message> Messages;
    public DataItem Data;
    public Boolean HasMoreData;
    public PagingDataItem PagingData;

    public ICertisAgreementsPostPutObj() {}

    public static ICertisAgreementsPostPutObj parse(String json) {
		return (ICertisAgreementsPostPutObj) System.JSON.deserialize(json, ICertisAgreementsPostPutObj.class);
	}

    public class Message {
        public String BaseErrorCode;
        public String Field;
        public String Message;
        public Integer MessageCode;
    }

    public class DataItem {
        public String Id;
        public List<Link> Links; 
        public Boolean RequestCompleted;
        public String SysId; 
    }

    public class PagingDataItem {
        public Integer PageNumber;
        public Integer RowsPerPage;
        public Integer TotalNumberOfPages;
        public Integer TotalRowCount;
    }

    public class Link {
        public String Action;
        public String Endpoint;
        public STring HttpMethod;
    }
}