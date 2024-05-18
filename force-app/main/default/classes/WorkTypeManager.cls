/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-07-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/WorkTypes/*')
global with sharing class WorkTypeManager {
    
    @HttpGet
     global static List<WorkType> getWorkTypes(){
        List<WorkType> workTypes = [SELECT Id, Name FROM WorkType];
        if(workTypes.isEmpty())
            return null;
        return workTypes;
    }
}