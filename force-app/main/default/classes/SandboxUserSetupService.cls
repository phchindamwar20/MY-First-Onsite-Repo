/**
 * @description       : This class creates/updates sandbox users specified in the Sandbox Users custom metadata
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-06-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SandboxUserSetupService {
    private Integer numToInactivate = 0;
    private static final Integer DEFAULT_NUM=50;

    public SandboxUserSetupService() {
        this(DEFAULT_NUM);
    }

    public SandboxUserSetupService(Integer numOfUsersToInactivate) {
        this.numToInactivate = numOfUsersToInactivate;
    }


    public void setupSandboxUsers() {
        Id profileId = [SELECT Id FROM Profile WHERE Name='Sales' LIMIT 1].Id;
        Id roleId = [SELECT Id FROM UserRole WHERE Name='Executive' LIMIT 1].Id;
        String sandboxName = getSandboxName();
        String result = '';
        
        inactivateUsers(numToInactivate);
        result += insertOrUpdateUsers(sandboxName, profileId, roleId);
        result += resetEmailPasswordForSysAdmins();

        if (!String.isBlank(result)) {
            sendErrorEmail(result, sandboxName); 
        }
    }

    private void inactivateUsers(Integer numToInactivate) {
        //free up salesforce licenses by deactivating the oldest Operations users

        if (numToINactivate != null && numToINactivate > 0) {
            List<User> freeUserLst = new List<User>();
            for (User u : [SELECT Id, Name, Profile.Name, IsActive FROM User WHERE Profile.Name = 'Operations' AND Profile.UserType='Standard' AND IsActive=true ORDER BY CreatedDate ASC Limit :numToINactivate]) {
                freeUserLst.add(new User(Id=u.Id, IsActive=false, ManagerId=null));
            }

            if (!freeUserLst.isEmpty()) {
                Database.SaveResult[] resultLst = Database.update(freeUserLst, false);
            }
        }
    }


    private String getSandboxName() {
        System.Domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
        return d.getSandboxName();
    }

    private String insertOrUpdateUsers(String sandboxName, Id profileId, Id roleId) {
        String result = '';
        Map<String, User> newUserByUserName = new Map<String, User>();
        Map<String, User> existingUserByUserName = new Map<String, User>();
        String testSuffix = Test.isRunningTest() ? '.test' : '';
        String suffix = !String.isBlank(sandboxName) ? '.' + sandboxName : '';
        suffix += testSuffix;

        for (Sandbox_User__mdt su : [SELECT First_Name__c, Last_Name__c, Email__c FROM Sandbox_User__mdt WHERE Skip_User__c=false]) {
            String userName = su.Email__c + suffix;
            newUserByUserName.put(userName, 
                setUser(su, userName, profileId, roleId));
        }

        for (User u : [SELECT Id, Username, LastLoginDate, Profile.UserType FROM User WHERE Profile.UserType IN ('CsnOnly', 'Standard') AND Username IN: newUserByUserName.keySet()]) {
            User existingUser = newUserByUserName.get(u.Username);
            existingUser.Id = u.Id;
            newUserByUserName.remove(u.Username);
            if (u.LastLoginDate == null) {
                if (u.Profile.UserType == 'CsnOnly') {
                    existingUser.UserRoleId = null;
                }
                existingUserByUserName.put(u.Username, existingUser);
            }
        }

        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerUserEmail = true;
        dlo.OptAllOrNone=false;
        if (!newUserByUserName.isEmpty()) {
            Database.SaveResult[] newUserLst = database.insert(newUserByUserName.values(), dlo);
            String errorMsg = getResultsResetEmail(newUserLst, newUserByUserName);
            if (!String.isBlank(errorMsg)) {
                result += 'There was an error creating new sandbox users: \n' + errorMsg;
            }
        }

        if (!existingUserByUserName.isEmpty()) {
            Database.SaveResult[] updUserLst = database.update(existingUserByUserName.values(), dlo);
            String errorMsg = getResultsResetEmail(updUserLst, existingUserByUserName);
            if (!String.isBlank(errorMsg)) {
                result += 'There was an error updating sandbox users: \n' + errorMsg;
            }
            //update user role
            for (User u : existingUserByUserName.values()) {
                u.UserRoleId=roleId;
            }
            database.update(existingUserByUserName.values(), dlo);
        }

        assignBoltPs(newUserByUserName, existingUserByUserName);
        return result;
    }

    private void assignBoltPs(Map<String, User> newUserByUserName, Map<String, User> oldUserByUserName) {
        Map<Id, User> userById = new Map<Id, User>();
        List<PermissionSetAssignment> psaLst = new List<PermissionSetAssignment>();
        PermissionSet boltPs = [SELECT Id FROM PermissionSet WHERE Name='BoltIntegrationManagement' LIMIT 1];

        for (User u : newUserByUserName.values()) {
            if (u.Id != null) {
                userById.put(u.Id, u);
            }
        }

        for (User u : oldUserByUserName.values()) {
            if (u.Id != null) {
                userById.put(u.Id, u);
            }
        }

        for (PermissionSetAssignment psa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId =: boltPs.Id AND AssigneeId IN : userById.keySet()]) {
            userById.remove(psa.AssigneeId);
        }

        for (Id userId : userById.keySet()) {
            psaLst.add(new PermissionSetAssignment(AssigneeId=userId, PermissionSetId=boltPs.Id));
        }

        if (!psaLst.isEmpty()) {
            Database.DMLOptions dlo = new Database.DMLOptions();
            Database.insert(psaLst, dlo);
        }
    }

    private String resetEmailPasswordForSysAdmins() {
        String result = '';
        Map<String, User> sysAdminUserByUserName = new Map<String, User>();

        for (User u : [SELECT Id, Email, Username FROM User WHERE Profile.Name='System Administrator' AND IsActive=true AND LastLoginDate = null]) {
            sysAdminUserByUserName.put(u.Username, new User(Id=u.Id, Username=u.Username, Email=u.Email.removeEnd('.invalid'), Is_Sandbox_User__c=true));
        }

        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerUserEmail = true;
        dlo.OptAllOrNone = false;
        Database.SaveResult[] userResultLst = database.update(sysAdminUserByUserName.values(), dlo);
        result = getResultsResetEmail(userResultLSt, sysAdminUserByUserName);
        if (!String.isBlank(result)) {
            result = 'There was an error resetting the following system admin users: \n' + result;
        }

        return result;
    }

    private String getResultsResetEmail(Database.SaveResult[] resultLst, Map<String, User> userByUserName) {
        String result = '';
        List<User> userLst = userByUserName.values();
        
        for (Integer i = 0 ; i<resultLst.size() ; i++) {
            if (resultLst[i].isSuccess()) {
                System.resetPassword(resultLst[i].getId(), true);
            } else {
                //there was an error
                for (Database.Error err : resultLst[i].getErrors()) {
                    result += 'There was an error creating/updating user ' + userLst[i].Username + ':  status code = ' + err.getStatusCode() + ', error message = ' + err.getMessage() + ', impacted fields = ' + err.getFields() + '\n';
                }
            }
        }    
        return result;
    }

    @future
    private static void sendErrorEmail(String result, String sandboxName) {
        System.debug('~~~~ SandboxUserSetupService::sendErrorEmail: result = ' + result);
        List<String> emailLst = new List<String>();
        emailLst.add(UserInfo.getUserId());

        Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
        sem.setSubject('Error Configuring Sandbox Users in ' + sandboxName + ' Sandbox');
        sem.setPlainTextBody(result);
        sem.setToAddresses(emailLst);

        Messaging.SingleEmailMessage[] messageLst = new List<Messaging.SingleEmailMessage> {sem};
        Messaging.SendEmailResult[] resultLst = Messaging.sendEmail(messageLst);

        if (resultLst[0].success) {
            System.debug('~~~~ SandboxUserSetupService::sendErrorEmail: The email was sent sucessfully.');
        } else {
            System.debug('~~~~ SandboxUserSetupService::sendErrorEmail: The email failed to send: ' + resultLst[0].errors[0].message);
        }
    }

    private User setUser(Sandbox_User__mdt sandboxUserSetting, String userName, Id profileId, Id roleId) {
        User thisUser = new User(LastName=sandboxUserSetting.Last_Name__c, 
            FirstName=sandboxUserSetting.First_Name__c, 
            Email=sandboxUserSetting.Email__c, 
            Username=userName,
            Alias=sandboxUserSetting.First_Name__c.left(1) + sandboxUserSetting.Last_Name__c.left(4),
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Denver',
            EmailEncodingKey='UTF-8',
            ProfileId=profileId,
            UserRoleId=roleId,
            Location__c='US - CO - Executive',
            CountryCode='US',
            IsActive=true,
            Is_Sandbox_User__c=true);

        return thisUser;
    }
}