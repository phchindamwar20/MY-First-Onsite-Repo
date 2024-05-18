/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    This class is used to make future callouts for Provisioning 
				and deprovisioning and reprovisioning the user in ICertis.
Class:     		ProvisionUserClass.cls
Test Class:     ProvisionUserClassTest.cls

History:
When        	Who         		What
24-June-2022	Arpit				Added the code to send the API callout to ICI for provisioning, deprovisioning 
									and reprovisioning the user.

*************************************************************************************/
global class ProvisionUserClass {

    global static void provisionUserCallout(Set<Id> userId) {
        List<User> userList = new List<User>([SELECT Id, IC_Security_Group__c, IC_Organization_Unit__c, IsActive, IC_User__c, FirstName, LastName, Email, Title, IC_Status__c FROM User where Id IN: userId]);
        
        
        List<User> updatedUserList = new List<User>();
        
        String sasToken = GetSASToken.getSASTokenMethod(Label.IC_Endpoint + Label.IC_Topic+'/messages' , Label.IC_SasKeyName, Label.IC_SasKey);
        SYstem.debug('sasToken::::'+sasToken);
        for(User userObj : userList) {
            String jsonBody = prepareProvisionBody(userObj);
            HTTPResponse res = sendHttpRequest('POST', jsonBody, sasToken, Label.IC_Endpoint + Label.IC_Topic+'/messages');
            System.debug('res:::'+res);
            if(res.getStatusCode() == 201) {
                User updatedUserObj = new User(Id = userObj.Id);
                updatedUserObj.IC_Status__c = 'Provisioned';
                
                updatedUserList.add(updatedUserObj);
            }//End of if(res.getStatus() == '201')
        }
        
        
        if(!updatedUserList.isEmpty()) update updatedUserList;
	}
    
    global static void deProvisionOrReProvisionUser(Set<Id> userId) {
        List<User> userList = new List<User>([SELECT Id, IC_Security_Group__c, IC_Organization_Unit__c, IsActive, IC_User__c, FirstName, LastName, Email, Title, IC_Status__c FROM User where Id IN: userId]);
        
        List<User> updatedUserList = new List<User>();
        String sasToken = GetSASToken.getSASTokenMethod(Label.IC_Endpoint + Label.IC_Topic+'/messages' , Label.IC_SasKeyName, Label.IC_SasKey);
        for(User userObj : userList) {
            
            if(!userObj.IC_User__c) {
                String jsonBody = prepareDeProvisionBody(userObj, 'Deprovision');
                System.debug('jsonBody::::'+jsonBody);
                HTTPResponse res = sendHttpRequest('POST', jsonBody, sasToken, Label.IC_Endpoint + Label.IC_Topic+'/messages');
                
                if(res.getStatusCode() == 201) {
                    User updatedUserObj = new User(Id = userObj.Id);
                    updatedUserObj.IC_Status__c = 'De-Provisioned';
                    updatedUserObj.IC_User__c = FALSE;
                    
                    updatedUserList.add(updatedUserObj);
                }//End of if(res.getStatus() == '201')
            } else if(userObj.IC_User__c && userObj.IC_Status__c == 'De-Provisioned') {
                String jsonBody = prepareDeProvisionBody(userObj, 'Reprovision');
                HTTPResponse res = sendHttpRequest('POST', jsonBody, sasToken, Label.IC_Endpoint + Label.IC_Topic+'/messages');
                
                if(res.getStatusCode() == 201) {
                    User updatedUserObj = new User(Id = userObj.Id);
                    updatedUserObj.IC_Status__c = 'Re-Provisioned';
                    
                    updatedUserList.add(updatedUserObj);
                }//End of if(res.getStatus() == '201')
            } else if(userObj.IC_User__c && String.isBlank(userObj.IC_Status__c)) {
                
                String jsonBody = prepareProvisionBody(userObj);
                HTTPResponse res = sendHttpRequest('POST', jsonBody, sasToken, Label.IC_Endpoint + Label.IC_Topic+'/messages');
                
                if(res.getStatusCode() == 201) {
                    User updatedUserObj = new User(Id = userObj.Id);
                    updatedUserObj.IC_Status__c = 'Provisioned';
                    
                    updatedUserList.add(updatedUserObj);
                }//End of if(res.getStatus() == '201')
            }//End of else if
        }//End of for
        System.debug('updatedUserList:::'+updatedUserList);
        if(!updatedUserList.isEmpty()) update updatedUserList;
    }
    
    //Method to prepare the Provision Body for the ICI
    public static String prepareProvisionBody(User userObj) {
        ProvisionUserJSON provisionUserObj = new ProvisionUserJSON();
        provisionUserObj.EventType = Label.IC_EventType;
        provisionUserObj.TimeStamp = String.valueOf(System.now());
        
        ProvisionUserJSON.Data provisionData = new ProvisionUserJSON.Data();
        provisionData.SecurityGroup = new List<ProvisionUserJSON.SecurityGroup>();
        provisionData.OrganizationUnit = new List<ProvisionUserJSON.OrganizationUnit>();
        
        if(!String.isBlank(userObj.IC_Security_Group__c)) {
            for(String str : userObj.IC_Security_Group__c.split(';')) {
                ProvisionUserJSON.SecurityGroup securityGroupObj = new ProvisionUserJSON.SecurityGroup();
                securityGroupObj.Name = str;
                provisionData.SecurityGroup.add(securityGroupObj);
            }
        }
        
        ProvisionUserJSON.OrganizationUnit orgUnitObj = new ProvisionUserJSON.OrganizationUnit();
        orgUnitObj.Name = userObj.IC_Organization_Unit__c;
        provisionData.OrganizationUnit.add(orgUnitObj);
        
        provisionData.ExtendedUserEntity = new List<ProvisionUserJSON.ExtendedUserEntity>();
        ProvisionUserJSON.ExtendedUserEntity extendedUserEntityObj = new ProvisionUserJSON.ExtendedUserEntity();
        extendedUserEntityObj.SalesforceUserId = userObj.Id;
        extendedUserEntityObj.Title = userObj.Title;
        provisionData.ExtendedUserEntity.add(extendedUserEntityObj);
        
        provisionData.EmailID = userObj.EMail;
        provisionData.ExternalUPN = userObj.EMail;
        provisionData.FirstName = userObj.FirstName;
        provisionData.LastName = userObj.LastName;
        provisionData.Administrator = 'false';
        provisionData.TypeOfUser = 'Internal';
        provisionData.Action = 'Provision';
        provisionData.Title = userObj.Title;
        
        provisionUserObj.Data = provisionData;
        
        SYstem.debug('Body::');
        SYstem.debug(JSON.serialize(provisionUserObj));
        return JSON.serialize(provisionUserObj);
    }
    
    //Method to prepare the De-Provision or Re-Provision Body
    public static String prepareDeProvisionBody(User userObj, String action) {
        DeprovisionuserJSON deprovisionUserObj = new DeprovisionuserJSON();
        deprovisionUserObj.EventType = 'FTP_JSON_UserInformation';
        deprovisionUserObj.TimeStamp = String.valueOf(System.now());
        deprovisionUserObj.Action = action;
        
        DeprovisionuserJSON.Data deprovisionData = new DeprovisionuserJSON.Data();
        deprovisionData.EmailID = userObj.Email;
        deprovisionData.Action = action;
        deprovisionData.TypeOfUser = 'Internal';
        
        deprovisionUserObj.Data = deprovisionData;
        
        return JSON.serialize(deprovisionUserObj);
        
    }//End of prepareDeProvisionBody method
    
    //Method to send the HTTP request to ICI
    public static HTTPResponse sendHttpRequest(String methodType, String jsonBody, String sasToken, String url) {
        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Content-Length', String.valueOf(jsonBody.length()));
        req.setHeader('Authorization', sasToken);
        req.setBody(jsonBody);
        Http http = new Http();
        System.debug('req::::'+req);
        HTTPResponse res = http.send(req);
        return res;
    }
}