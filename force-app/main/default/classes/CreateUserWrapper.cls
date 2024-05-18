/**
 * @File Name          : CreateUserWrapper.cls
 * @Description        : This is the request used to post/put to the iCertis Users web service
 * @Author             : Arpit Vashishtha
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 01-13-2024
 * @Modification Log   :  
 * Ver       Date            Author      		    Modification
 * 1.0      10/09/2020        AVashishtha           INITIAL DEVELOPMENT STAR-5366
**/
public class CreateUserWrapper {
    
    public Data Data;
    
    public class Data {
        public Boolean Administrator;
        public String OrganizationUnitPath;
        public String LastName;
        public String FirstName;
        public String TypeOfUser;
        public String ExternalUPN;
        public String EmailID;
        public String Status;
        public String Id;
    }//End of Data class
    
    public static CreateUserWrapper parse(String json) {
		return (CreateUserWrapper) System.JSON.deserialize(json, CreateUserWrapper.class);
	}

    //Method to prepare the Create User Body for the ICI
    public static String prepareCreateUserBody(WorkOrder workOrderObj, String sysId) {
        CreateUserWrapper createUserWrapperObj = new CreateUserWrapper();
        CreateUserWrapper.Data createUserDataWrapperObj = new CreateUserWrapper.Data();
        createUserDataWrapperObj.Administrator = false;
        createUserDataWrapperObj.OrganizationUnitPath = '/firstonsite';
        createUserDataWrapperObj.LastName = workOrderObj.IC_External_Last_Name__c;
        createUserDataWrapperObj.FirstName = workOrderObj.IC_External_First_Name__c;
        createUserDataWrapperObj.TypeOfUser = 'External';
        createUserDataWrapperObj.ExternalUPN = workOrderObj.IC_Signatory_Email__c;
        createUserDataWrapperObj.EmailID = workOrderObj.IC_Signatory_Email__c;
        createUserDataWrapperObj.Status = 'Provisioned';
        createUserWrapperObj.Data = createUserDataWrapperObj;
        createUserDataWrapperObj.Id = sysId;
        
        return JSON.serialize(createUserWrapperObj);
    }//End of prepareCreateUserBody method

}//End of CreateUserWrapper class