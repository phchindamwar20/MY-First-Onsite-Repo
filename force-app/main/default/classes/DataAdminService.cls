/**
 * @description       : The purpose of this class is to allow a developer to turn on and off data admin in code
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 04-02-2024
 * @last modified by  : Terri Jiles
**/
public without sharing class DataAdminService {
    private Boolean turnOffTrigger=false;
    private Boolean turnOffWorkflow=false;
    private Boolean turnOffProcessBuilder=false;
    private Boolean turnOffValidationRules=false;
    private Boolean turnOffFlow=false;

    @TestVisible
    private Boolean isRevertDataAdmin=false;

    public DataAdminService() {
        //get initial settings
        DataAdmin__c[] dataAdminLst = [SELECT TurnOffTrigger__c, TurnOffWorkflow__c, TurnOffProcessBuilder__c, TurnOffValidationRules__c, TurnOffFlow__c FROM DataAdmin__c WHERE SetupOwnerId=:UserInfo.getUserId() LIMIT 1];
        if (!dataAdminLst.isEmpty()) {
            turnOffTrigger=dataAdminLst[0].TurnOffTrigger__c;
            turnOffWorkflow=dataAdminLst[0].TurnOffWorkflow__c;
            turnOffProcessBuilder=dataAdminLst[0].TurnOffProcessBuilder__c;
            turnOffValidationRules=dataAdminLst[0].TurnOffValidationRules__c;
            turnOffFlow=dataAdminLst[0].TurnOffFlow__c;
            isRevertDataAdmin=true;
        }
    }

    public void modifyDataAdmin(Boolean turnOffTrigger, Boolean turnOffWorkFlow, Boolean turnOffProcessBuilder, Boolean turnOffValidationRules, Boolean turnOffFlow) {
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=turnOffTrigger;
        dataAdmin.TurnOffWorkflow__c=turnOffWorkFlow;
        dataAdmin.TurnOffProcessBuilder__c=turnOffProcessBuilder;
        dataAdmin.TurnOffValidationRules__c=turnOffValidationRules;
        dataAdmin.TurnOffFlow__c=turnOffFlow;
        if (dataAdmin.Id != null && dataAdmin.SetupOwnerId == UserInfo.getUserId()) {
            update dataAdmin;
        }
        else {
            dataAdmin.SetupOwnerId = UserInfo.getUserId();
            insert dataAdmin; 
            
        }  
    }

    public void reverDataAdmin() {
        if (isRevertDataAdmin == true) {
            modifyDataAdmin(turnOffTrigger, turnOffWorkFlow, turnOffProcessBuilder, turnOffValidationRules, turnOffFlow);
        } else {
            DataAdmin__c setting = DataAdmin__c.getInstance(UserInfo.getUserId());
            if (setting.SetupOwnerId == UserInfo.getUserId()) {
                delete setting;
            }
        }
    }
}