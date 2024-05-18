/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-03-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-02-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public with sharing class UATUserSetupService {
    public static void updateUatUsers() {
        List<User> userLst = new List<User>();

        String OrganizationName = [SELECT Name FROM Organization Limit 1].Name;
        OrganizationName = OrganizationName != null ? OrganizationName : '';

        for (User u : [SELECT Id, Email FROM User WHERE Is_UAT_User__c=true AND IsActive=true]) {
            userLst.add(new User(Id=u.Id, Email=u.Email.remove('.invalid')));
            String password = 'First0n$ite'+OrganizationName;
            System.debug('~~~~ UATUserSetupService::updateUatUser: password ' + password);
            System.setPassword(u.Id, password);
        }

        update userLst;
    }
}