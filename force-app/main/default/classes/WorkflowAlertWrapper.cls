/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Wrapper class for Workflow Alert response from Tooling API
Class:     		WorkflowAlertWrapper.cls

History:
When        	Who         		What
24-June-2022	Arpit				Added code for Workflow Alert response from Tooling API

*************************************************************************************/
public class WorkflowAlertWrapper {

    public Attributes attributes;
    public String Id;	//01W2x0000008Tj9EAE
    public String TemplateId;	//00X2x000000xdaoEAA
    public String CcEmails;	//a.v@gmail.com
    public String Description;	//TestTest
    public String DeveloperName;	//Test
    public String SenderType;	//CurrentUser
    public String NamespacePrefix;	//
    public String CreatedDate;	//2022-06-20T17:52:58.000+0000
    public String CreatedById;	//0052x000000zoe6AAA
    public String LastModifiedDate;	//2022-06-21T16:19:42.000+0000
    public String LastModifiedById;	//0052x000000zoe6AAA
    public String EntityDefinitionId;	//Account
    public cls_Metadata Metadata;
    public String FullName;	//Account.c__Test
    public Integer size;
	public Integer totalSize;
	public Boolean done;
	public Object queryLocator;
	public String entityTypeName;
	public List<Records> records;
    
	public class Attributes {
		public String type;
		public String url;
	}

	

	public class Records {
		public Attributes attributes;
		public String Id;
        public String FullName;
		public String CcEmails;
        public String SenderType;
        public String description;
        public String template;
	}
    
    public class SingleEmailRecord{
        
    }
        
	public class cls_Metadata {
		public List<String> ccEmails;
		public String description;	//TestTest
		public Boolean protected_x;
		public List<Recipient> recipients;
		public String senderAddress;
		public String senderType;	//CurrentUser
		public String template;	//unfiled$public/SalesNewCustomerEmail
		public String urls;
	}    
    
    public class Recipient {
		public String field;
		public String recipient;
        public String type;
	}
    

	
	public static WorkflowAlertWrapper parse(String json) {
		return (WorkflowAlertWrapper) System.JSON.deserialize(json, WorkflowAlertWrapper.class);
	}
}