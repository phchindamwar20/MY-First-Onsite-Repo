/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-29-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/Branches/*')
global without sharing class BranchManager {
    
    @HttpGet
   	global static List<ServiceTerritory> getBranches(){
        List<ServiceTerritory> branches = [SELECT Id, Name, IsActive FROM ServiceTerritory];
        if(branches.isEmpty())
            return null;
        return branches;
    }
}