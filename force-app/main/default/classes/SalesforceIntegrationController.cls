public class SalesforceIntegrationController {
    
	@AuraEnabled
    public static List<SObject> getUserProfile() {
      return [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
  	}
    
    @AuraEnabled
    public static Map<String, List<SObject>> getUserInformation() {
        //get user information.
        Map<String, List<SObject>> userinformationMap = new Map<String, List<SObject>>();
        List<SObject> profileinfo = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        userinformationMap.put('profile',profileinfo);
     	List<SObject> userinfo = [SELECT CreatedDate,UserRole.Name,LastLoginDate,LocaleSidKey,Manager.Name,TimeZoneSidKey,Department,Id,Division FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        userinformationMap.put('user',userinfo);
        return userinformationMap;  
    }
}