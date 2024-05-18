/**
 * @description       : 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 03-18-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public with sharing class MapsCampaignMemberQueueableTest {
    @TestSetup
    static void makeData(){
        DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
        System.debug('~~~~~~ ' + dataAdmin.Id );
        dataAdmin.TurnOffTrigger__c=true;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
            dataAdmin.SetupOwnerId = UserInfo.getUserId();
            insert dataAdmin;  
        }
        else {
            update dataAdmin;
        }    

        Campaign testCamp = new Campaign(Name='Test');
        insert testCamp;

        List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=null, RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT), 200, 'TestFactoryDefaults.AccountDefaults', true);
    }

    @isTest
    static void testMapCampaignMemberQueueable() {
        Map<Id, Account> oldAccById = new Map<Id, Account>([SELECT Id, Maps_Campaign_Trigger__c FROM Account]);
        Map<Id, Account> accById = new Map<Id, Account>();

        for (Account acc : [SELECT Id FROM Account]) {
            accById.put(acc.Id, new Account(Id=acc.Id, Maps_Campaign_Trigger__c='Test'));
        }
        update accById.values();

        Test.startTest();
        ExecutionService chainQueueableJobService = new ExecutionService();
        ExecutionItem ei = new ExecutionItem([SELECT Id, Object__c, Order__c, Queueable_Class_Name__c, Selection_Name__c, Trigger_Operation__c, Is_Delay__c, Delay_In_Minutes__c  
                                                FROM Execute_Item_Configuration__mdt
                                                WHERE Selection_Name__c='SelectionMapCampaignMember' LIMIT 1], accById, oldAccById);
        List<ExecutionItem> justMapCampaignMemberItmLst = new List<ExecutionItem>();
        justMapCampaignMemberItmLst.add(ei);

        chainQueueableJobService.executeInitialHandler(justMapCampaignMemberItmLst);
        Test.stopTest();

        //System.assert(justMapCampaignMemberItmLst.size() > 0 );
        System.debug('~~~~ ei ' + ei);
        System.assertEquals(true, !ei.getSelection().getRecIds().isEmpty(),  'Fail:  It didn\'t select the expected 200 records with changed maps campaign name values');
        System.debug('~~~~ MapsCampaignMemberQueueableTest::testMapCampaignMemberQueueable: ' + [SELECT Id FROM CampaignMember]);
        System.assertEquals(200, [SELECT Id FROM CampaignMember].size(), 'Fail:  It did not create any campiagn Members');
        //full testing fo the MapsCampaignMember class is covered in MapCampaignMemberServiceTest
    }
}