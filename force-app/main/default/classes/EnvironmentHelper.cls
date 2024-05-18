/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Class to get the Sandbox/Production details via URL.
Class:     		EnvironmentHelper.cls

History:
When        	Who         		What
29-June-2022	Arpit				Added code to get the Sandbox/Production details via URL.

*************************************************************************************/
public with sharing class EnvironmentHelper {
    public static final String PROD_ENVIRONMENT = 'Production';
    public static final String SANDBOX_NAME_PREFIX = '--';
    public static final String SANDBOX_NAME_END = '.';
    
    
   //return The sandbox prefix when available

    public static String getSandboxName(){
        String hostName = System.Url.getSalesforceBaseUrl().getHost();
        
        if(Test.isRunningTest() || isSandbox(hostName)){
            Integer startIndexOfSandboxName = getStartIndexOfSandboxName(hostName);
            Integer endIndex = hostName.indexOf(SANDBOX_NAME_END);
            return hostName.mid(startIndexOfSandboxName,endIndex-startIndexOfSandboxName);
        }
        
        //When no sandbox is found then just return a string that signifies this is production
        return PROD_ENVIRONMENT;
    }
    

	//return the index that the sanbox name start. -1 if prod
    private static Integer getStartIndexOfSandboxName(String hostName){
        return hostName.indexOf(SANDBOX_NAME_PREFIX) + SANDBOX_NAME_PREFIX.length();
    }
    
        
	//return true if the hostname contains the SANDBOX_NAME_PREFIX i.e. '--'
    public static Boolean isSandbox(String hostName){
        return hostName.indexOf(SANDBOX_NAME_PREFIX) != -1;
    }
}