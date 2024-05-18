/**
 * @description       : This test the BoltCalloutEngineQueueable class
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 02-02-2024
 * @last modified by  : Terri Jiles
**/
@isTest
public without sharing class BoltCalloutEngineQueueableTest {
    private static Integer numTestRecs = 200;
    private static final String BOLT_ACC_SELECTION = 'SelectionBoltCalloutAccount';
    private static final String BOLT_PROP_SELECTION = 'SelectionBoltCalloutProperty';
    private static final String BOLT_JOB_SELECTION = 'SelectionBoltCalloutJob';
    private static final String BOLT_ACC_RT_CHNG_SELECTION =  'SelectionBoltCalloutChangeFromAccountRT';
    private static final String BOLT_PROP_RT_CHNG_SELECTION = 'SelectionBoltCalloutChangeFromPropertyRT';
    private static final String BOLT_ACC_DEL_SELECTION = 'SelectionBoltCalloutDeleteAccounts';
    private static final String BOLT_PROP_DEL_SELECTION = 'SelectionBoltCalloutDeleteProperties';
    private static final String ULTI_PAR_ACC_SELECTION = 'SelectionUltimateParent';
    private static final String BOLT_AWE_SELECTION = 'SelectionBoltCalloutAreaWideEvent';
    private static final String BOLT_USER_SELECTION = 'SelectionBoltCalloutUser';

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
        Account grandParentAcc = (Account)TestFactory.createSObject(new Account(RecordTypeId=GeneralConstants.RT_ID_ACC_PARENT, Name='GrandParent'), 'TestFactoryDefaults.AccountDefaults', true);
        Account parentAcc = (Account)TestFactory.createSObject(new Account(ParentId=grandParentAcc.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_PARENT, Name='Parent'), 'TestFactoryDefaults.AccountDefaults', true);     
    }

    @isTest
    static void testAccountBoltAccountCalloutQueueable() {
        List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=null, RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT), numTestRecs, 'TestFactoryDefaults.AccountDefaults', true);
        Map<Id, Account> newAccById = new Map<Id, Account>(accLst);

        Test.startTest();
        ExecutionService chainQueueableJobService = new ExecutionService();
        chainQueueableJobService.buildAndKickoffQueueableJobs(GeneralConstants.OBJ_ACCOUNT, GeneralConstants.AFTER_INSERT, newAccById, null);
        Test.stopTest();

        System.debug('~~~~ BoltCalloutEngineQueueableTest::testAccountBoltAccountCalloutQueueable:: BoltCalloutEngineQueueable.isBoltCalloutMade - ' + BoltCalloutEngineQueueable.isBoltCalloutMade);
        System.assertEquals(true, BoltCalloutEngineQueueable.isBoltCalloutMade, 'Fail:  Didn\'t try to handle the next chained job for account');
    }

    @isTest
    static void testAccountSelectionForInsert() {
        List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=null, RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT), numTestRecs, 'TestFactoryDefaults.AccountDefaults', true);
        Map<Id, Account> newAccById = new Map<Id, Account>(accLst);

        Test.startTest();
        ExecutionService chainQueueableJobService = new ExecutionService();
        List<ExecutionItem> executionItemLst = chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_ACCOUNT, GeneralConstants.AFTER_INSERT, newAccById, null);
        Test.stopTest();

        Boolean hasAccRtChng = false, hasAccSel = false;
        for (ExecutionItem ei : executionItemLst) {
            if (ei.getSelection().getSelectionName() == BOLT_ACC_SELECTION) {
                System.assert(ei.getSelection().getRecIds().size() == accLst.size(), 'Failed:  Count of account selected doesn\'t match size of account list');
                hasAccSel = true;
            }
        }
        System.assertEquals(true, hasAccSel, 'Failed: Selection name for bolt property not selected');


        //unit testing selection method
        Account oldAcc = accLst[0].clone(true, true, true, true);
        oldAcc.Phone = '888-888-8888';

        SelectionBoltCalloutAccount sbca = new SelectionBoltCalloutAccount();
        System.assertEquals(true, sbca.isIntegrateWithBoltAccount(accLst[0], oldAcc), 'Failed: expected record to be selected as a bolt account as true');
        oldAcc.Phone=accLst[0].Phone;
        System.assertEquals(false, sbca.isIntegrateWithBoltAccount(accLst[0], oldAcc), 'Failed: expected record to NOT be selected as a bolt account as false');
        oldAcc.RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY;
        System.assertEquals(false, sbca.isIntegrateWithBoltAccount(accLst[0], oldAcc), 'Failed: expected record to NOT be selected as a bolt account as false because old record type is property');
    }

    @isTest
    static void testBoltPropertySelectionForInsert() {
        List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=null, RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY), numTestRecs, 'TestFactoryDefaults.PropertyDefaults', true);
        Map<Id, Account> newAccById = new Map<Id, Account>(accLst);

        Test.startTest();
        ExecutionService chainQueueableJobService = new ExecutionService();
        List<ExecutionItem> executionItemLst = chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_ACCOUNT, GeneralConstants.AFTER_INSERT, newAccById, null);
        Test.stopTest();

        Boolean hasPropSel = false;
        for (ExecutionItem ei : executionItemLst) {
            if (ei.getSelection().getSelectionName() == BOLT_PROP_SELECTION) {
                System.assert(ei.getSelection().getRecIds().size() == accLst.size(), 'Failed:  Count of account selected doesn\'t match size of account list');
                hasPropSel = true;
            }
        }
        System.assertEquals(true, hasPropSel, 'Failed: Selection name for bolt property not selected');

        //unit testing selection method
        Account oldAcc = accLst[0].clone(true, true, true, true);
        SelectionBoltCalloutProperty sbca = new SelectionBoltCalloutProperty();
        System.assertEquals(true, sbca.isBoltPropertyRec(accLst[0], null), 'Failed: expected record to be selected as a new bolt property as true');
        oldAcc.ShippingCity = 'New Orleans';
        System.assertEquals(true, sbca.isBoltPropertyRec(accLst[0], oldAcc), 'Failed: expected record to be selected as an existing bolt property as true');
        oldAcc.ShippingCity=accLst[0].ShippingCity;
        System.assertEquals(false, sbca.isBoltPropertyRec(accLst[0], oldAcc), 'Failed: expected record to NOT be selected as a bolt property as false');        
    }

    @isTest
    static void testBoltChngFromAccountRtDeleteCalloutForInsert() {
        Account parAcc = new Account(Name='parentAccount');
        insert parAcc;

        List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=parAcc.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY), numTestRecs, 'TestFactoryDefaults.PropertyDefaults', true);
        Map<Id, Account> newAccById = new Map<Id, Account>(accLst);
        Map<Id, Account> oldAccById = new Map<Id, Account>();

        for (Account acc : newAccById.values()) {
            Account cloneAcc = acc.clone(true, true, true, true);
            cloneAcc.RecordTypeId = GeneralConstants.RT_ID_ACC_ACCOUNT;
            oldAccById.put(cloneAcc.Id, cloneAcc);
        }

        Test.startTest();
        ExecutionService chainQueueableJobService = new ExecutionService();
        List<ExecutionItem> executionItemLst = chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_ACCOUNT, GeneralConstants.AFTER_UPDATE, newAccById, oldAccById);
        Test.stopTest();

        Boolean hasAccRtChng = false, hasPropSel = false;
        for (ExecutionItem ei : executionItemLst) {
            if (ei.getSelection().getSelectionName() == BOLT_ACC_RT_CHNG_SELECTION) {
                System.assert(ei.getSelection().getRecIds().size() == accLst.size(), 'Failed: Count of account selected doesn\'t match size of account list');
                hasAccRtChng = true;
            } else if (ei.getSelection().getSelectionName() == BOLT_PROP_SELECTION) {
                System.assert(ei.getSelection().getRecIds().size() == accLst.size(), 'Failed:  Count of account selected doesn\'t match size of account list');
                hasPropSel = true;
            }
        }
        System.assertEquals(true, hasAccRtChng, 'Failed: Selection name for bolt account to delete not selected');
        System.assertEquals(true, hasPropSel, 'Failed: Selection name for bolt property not selected');

        //selection unit testing
    
    }

    @isTest
    static void testBoltChngFromPropertyRtDeleteCalloutForInsert() {
        Account parAcc = new Account(Name='Parent Account Test');
        insert parAcc;

        List<Account> accLst = (List<Account>)TestFactory.createSObjectList(new Account(ParentId=parAcc.Id, RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT), numTestRecs, 'TestFactoryDefaults.PropertyDefaults', true);
        Map<Id, Account> newAccById = new Map<Id, Account>(accLst);
        Map<Id, Account> oldAccById = new Map<Id, Account>();

        for (Account acc : newAccById.values()) {
            Account cloneAcc = acc.clone(true, true, true, true);
            cloneAcc.RecordTypeId = GeneralConstants.RT_ID_ACC_PROPERTY;
            oldAccById.put(cloneAcc.Id, cloneAcc);
        }
        Test.startTest();
        ExecutionService chainQueueableJobService = new ExecutionService();
        List<ExecutionItem> executionItemLst = chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_ACCOUNT, GeneralConstants.AFTER_UPDATE, newAccById, oldAccById);
        Test.stopTest();

        Boolean hasUltParentSel=false, hasBoltPrpRtChgSel=false;
        for(ExecutionItem ei : executionItemLst) {
            if (ei.getSelection().getSelectionName() == ULTI_PAR_ACC_SELECTION) {
                hasUltParentSel = true;
                System.assertEquals(numTestRecs, ei.getSelection().getRecIds().size(), ' Failed:  Expected there to be ' + numTestRecs + ' records to be processed for the ultimate parent ');
            } else if ( ei.getSelection().getSelectionName() == BOLT_PROP_RT_CHNG_SELECTION) {
                hasBoltPrpRtChgSel = true;
                System.assertEquals(numTestRecs, ei.getSelection().getRecIds().size(), ' Failed:  Expected there to be ' + numTestRecs + ' records to be processed for the ultimate parent ');
            }
        }
        System.assertEquals(true, hasUltParentSel, 'Failed:  Expected the Ultimate Parent Selection in the execution list due to change in record type');
        System.assertEquals(true, hasBoltPrpRtChgSel, 'Failed:  Expected the Bolt Change from Property Record Type selection in the execution list due to change in record type from property');

        //unit testing selection method
        Account oldProp = accLst[0].clone(true, true, true, true);
        oldProp.RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY;

        SelectionBoltCalloutChangeFromPropertyRT sbcp = new SelectionBoltCalloutChangeFromPropertyRT();
        System.assertEquals(true, sbcp.isChngFromPropAccToDeleteFromBolt(accLst[0], oldProp), 'Failed: expected record to be selected as a deleted bolt property as true');
        System.assertEquals(false, sbcp.isChngFromPropAccToDeleteFromBolt(accLst[0], null), 'Failed: expected record to NOT be selected because it is a new record with the account record type');
        oldProp.RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT;
        System.assertEquals(false, sbcp.isChngFromPropAccToDeleteFromBolt(accLst[0], oldProp), 'Failed: expected record to NOT be selected as a deleted bolt property as false because Record Type the same'); 
    }


    
    @isTest
    static void testBoltAccountDeleteCalloutSelection(){
        Test.startTest();
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='TestAccount'), 'TestFactoryDefaults.MyAccountDefaults', true);
        Map<Id, Account> recById = new Map<Id, Account>([SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId=:GeneralConstants.RT_ID_ACC_ACCOUNT]);
        //delete recById.values();
        try {
            ExecutionService chainQueueableJobService = new ExecutionService();
            List<ExecutionItem> executionItemLst = chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_ACCOUNT, GeneralConstants.AFTER_DELETE, null, recById);
            
            Boolean isAccDelSel = false;
            for (ExecutionItem ei : executionItemLst) {
                if (ei.getSelection().getSelectionName() == BOLT_ACC_DEL_SELECTION) {
                    isAccDelSel = true;
                    System.assert(ei.getSelection().getRecIds().size() == recById.values().size(), 'Fail: Did\'t get selections for callout to Bolt');
                }
            }
            System.assertEquals(true, isAccDelSel, 'Fail: Selection name for bolt account to delete not selected');
        } catch(Exception e) {
            System.assert(false, 'Fail: error thrown');
        }
        Test.stopTest();

        //unit testing selection method
        Account oldAcc = recById.values()[0].clone(true, true, true, true);
        SelectionBoltCalloutDeleteAccounts sbca = new SelectionBoltCalloutDeleteAccounts();
        System.assertEquals(true, sbca.isDeleteAccFromBolt(oldAcc), 'Failed: expected record to be selected as a deleted bolt account as true');
        oldAcc.RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY;
        System.assertEquals(false, sbca.isDeleteAccFromBolt(oldAcc), 'Failed: expected record to NOT be selected as a deleted bolt account as false because Record Type is wrong'); 
    }

    @isTest
    private static void testBoltPropertyDeleteCalloutSelection(){
        List<Account> accLst = new List<Account>();
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='Property', RecordTypeId=GeneralConstants.RT_ID_ACC_PROPERTY ), 'TestFactoryDefaults.MyAccountDefaults', true);
        Map<Id, Account> recById = new Map<Id, Account>([SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId=:GeneralConstants.RT_ID_ACC_PROPERTY]);

        Test.startTest();
        try {
            //delete recById.values();
            ExecutionService chainQueueableJobService = new ExecutionService();
            List<ExecutionItem> executionItemLst = chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_ACCOUNT, GeneralConstants.AFTER_DELETE, null, recById);
            
            Boolean isPropDelSel = false;

            for (ExecutionItem ei : executionItemLst) {
                if (ei.getSelection().getSelectionName() == BOLT_PROP_DEL_SELECTION) {
                    isPropDelSel = true;
                    System.assert(ei.getSelection().getRecIds().size() == recById.values().size(), 'Failed: Did\'t get selections for callout to Bolt');
                }
            }
            System.assertEquals(true, isPropDelSel,  'Failed: Selection name for bolt properties to delete not selected');
        } catch(Exception e) {
            System.assert(false, 'error thrown');
        }
        Test.stopTest();

        //unit testing selection method
        Account oldAcc = recById.values()[0].clone(true, true, true, true);
        SelectionBoltCalloutDeleteProperties sbca = new SelectionBoltCalloutDeleteProperties();
        System.assertEquals(true, sbca.isCriteriaMet(oldAcc), 'Failed: expected record to be selected as a deleted bolt property as true');
        oldAcc.RecordTypeId=GeneralConstants.RT_ID_ACC_ACCOUNT;
        System.assertEquals(false, sbca.isCriteriaMet(oldAcc), 'Failed: expected record to NOT be selected as a deleted bolt property as false because Record Type is wrong');         
    }   

    @isTest
    private static void testBoltJobCalloutSelection() {
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='TestAccount'), 'TestFactoryDefaults.MyAccountDefaults', true);
        List<WorkOrder> jobLst = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=parentA.Id, Integrate_with_Bolt__c=true), numTestRecs, 'TestFactoryDefaults.JobDefaults', true);

        Test.startTest();
        ExecutionService chainQueueableJobService = new ExecutionService();
        List<ExecutionItem> executionItemLst = chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_JOB, GeneralConstants.AFTER_INSERT, new Map<Id, WorkOrder>(jobLst), null);
        Test.stopTest();

        //System.assertEquals(1, executionItemLst.size(), 'No execution items for insert of job');

        Boolean isBoltJobSelection = false;
        for (ExecutionItem ei : ExecutionItemLst) {

            if (ei.getSelection().getSelectionName() == BOLT_JOB_SELECTION) {
                isBoltJobSelection=true;
                System.assert(ei.getSelection().getRecIds().size() == jobLst.size(), 'Count of job selected doesn\'t match size of job list');
            }
        }
        System.assertEquals(true,  isBoltJobSelection, 'Selection name for bolt job not selected');       
        
        //unit testing selection method
        WorkOrder oldJob = jobLst[0].clone(true, true, true, true);
        SelectionBoltCalloutJob sbcj = new SelectionBoltCalloutJob();
        //inserts
        System.assertEquals(true, sbcj.isBoltJob(false, jobLst[0], null), 'Failed: expected record to be selected as a new bolt job as true although Bolt Sync User created Job');
        System.assertEquals(true, sbcj.isBoltJob(true, jobLst[0], null), 'Failed: expected record to be selected as a new bolt job as true although Non-Bolt Sync User created Job');
        jobLst[0].Integrate_with_Bolt__c = false;
        System.assertEquals(false, sbcj.isBoltJob(true, jobLst[0], null), 'Failed: expected record to NOT be selected as a new job because it isn\'t a bolt job');
        //updates
        jobLst[0].Integrate_with_Bolt__c = true;
        oldJob.Job_Name__c= 'Change Job Name';
        System.assertEquals(true, sbcj.isBoltJob(true, jobLst[0], oldJob), 'Failed: expected record to be selected as an existing bolt job because a change in job name and job was updated by non-bolt sync user');
        System.assertEquals(false, sbcj.isBoltJob(false, jobLst[0], oldJob), 'Failed: expected record to NOT be selected as an existing bolt job because a change in the job name was changed by the Bolt-Sync User');
        jobLst[0].Integrate_with_Bolt__c = false;
        System.assertEquals(false, sbcj.isBoltJob(true, jobLst[0], oldJob), 'Failed: expected record to NOT be selected as an existing  job because a change in the job name was on a non-bolt job'); 
    }

    @isTest
    private static void testJobCalloutQueueable() {
        Account parentA = (Account)TestFactory.createSObject(new Account(Name='TestAccount'), 'TestFactoryDefaults.MyAccountDefaults', true);
        List<WorkOrder> jobLst = (List<WorkOrder>)TestFactory.createSObjectList(new WorkOrder(AccountId=parentA.Id, Integrate_with_Bolt__c=true), numTestRecs, 'TestFactoryDefaults.JobDefaults', true);

        ExecutionService chainQueueableJobService = new ExecutionService();
        List<ExecutionItem> executionItemLst = chainQueueableJobService.buildExecutionItemsList(GeneralConstants.OBJ_JOB, GeneralConstants.AFTER_INSERT, new Map<Id, WorkOrder>(jobLst), null);
        Integer i=0;
        Set<Integer> numRemoves = new Set<Integer>();
        for (ExecutionItem ei : executionItemLst) {
            if (ei.getSelection().getSelectionName() != BOLT_JOB_SELECTION) {
                numRemoves.add(i);
            }
            i++;
        }
        for (Integer x : numRemoves) {
            executionItemLst.remove(x);
        }

        Test.startTest();
        ExecutionService es = new ExecutionService();
        es.executeInitialHandler(executionItemLst);
        Test.stopTest();

        System.debug('~~~~ BoltCalloutEngineQueueableTest::testJobCalloutQueueable:: BoltCalloutEngineQueueable.isBoltCalloutMade - ' + BoltCalloutEngineQueueable.isBoltCalloutMade);
        System.assertEquals(true, BoltCalloutEngineQueueable.isBoltCalloutMade, 'Fail:  Didn\'t try to handle the next chained job for job');
    }    

    @isTest
    private static void testAreaWideEventCalloutQueueable() {
        List<Area_Wide_Event__c> aweLst = new List<Area_Wide_Event__c>(); 
        for (Integer i=0 ; i<numTestRecs ; i++) {
            aweLst.add(new Area_Wide_Event__c(Name='Test ' + String.valueOf(i), Active__c=true, Event_Type__c='Area Wide Event'));
        }
        insert aweLst;

        Test.startTest();
        ExecutionService chainQueueableAweService = new ExecutionService();
        chainQueueableAweService.buildAndKickoffQueueableJobs(GeneralConstants.OBJ_AREA_WIDE_EVENT, GeneralConstants.AFTER_INSERT, new Map<Id, Area_Wide_Event__c>(aweLst), null);
        Test.stopTest();
        
        System.assertEquals(true, BoltCalloutEngineQueueable.isBoltCalloutMade, 'Fail:  Didn\'t try to handle the next chained job for awes');
    }

    @isTest
    private static void testAreaWideEventSelection() {
        List<Area_Wide_Event__c> aweLst = new List<Area_Wide_Event__c>(); 
        for (Integer i=0 ; i<numTestRecs ; i++) {
            aweLst.add(new Area_Wide_Event__c(Name='Test ' + String.valueOf(i), Active__c=true, Event_Type__c='Area Wide Event'));
        }
        insert aweLst;

        Test.startTest();
        ExecutionService chainQueueableService = new ExecutionService();
        List<ExecutionItem> executionItemLst = chainQueueableService.buildExecutionItemsList(GeneralConstants.OBJ_AREA_WIDE_EVENT, GeneralConstants.AFTER_INSERT, new Map<Id, Area_Wide_Event__c>(aweLst), null);
        Test.stopTest();

        System.assertEquals(1, executionItemLst.size(), 'No execution items for insert of job');
        System.assert(executionItemLst[0].getSelection().getRecIds().size() == aweLst.size(), 'Count of job selected doesn\'t match size of awe list');
        System.assert(executionItemLst[0].getSelection().getSelectionName() == BOLT_AWE_SELECTION, 'Selection name for bolt job not selected');  

        //unit testing selection method
        Area_Wide_Event__c oldAwe = aweLst[0].clone(true, true, true, true);
        SelectionBoltCalloutAreaWideEvent sbca = new SelectionBoltCalloutAreaWideEvent();
        System.assertEquals(true, sbca.isBoltAWE(aweLst[0], null), 'Failed: expected record to be selected as a new bolt awe as true');
        oldAwe.Active__c = false;
        System.assertEquals(true, sbca.isBoltAWE(aweLst[0], oldAwe), 'Failed: expected record to be selected as an existing bolt awe as true');
        oldAwe.Active__c=aweLst[0].Active__c;
        System.assertEquals(false, sbca.isBoltAWE(aweLst[0], oldAwe), 'Failed: expected record to NOT be selected as a bolt awe as false');   

    }

    @isTest
    private static void testUserSelection() {
        //Test.startTest();
        //System.runAs(new User(Id=UserInfo.getUserId())) {
        //    TestFactory.createUsers();
        //Test.stopTest();
        //}

        //List<User> userLst = [SELECT Id, ADP_Associate_OID__c, BOLT_Key__c, Email, Username, FederationIdentifier, IC_User__c FROM User WHERE IsActive=true AND ADP_Associate_OID__c LIKE 'ABDC%'];
        List<User> userLst = [SELECT Id, ADP_Associate_OID__c, BOLT_Key__c, Email, Username, FederationIdentifier, IsActive, IC_User__c, BOLTUpdateTrigger__c FROM User WHERE Id =: UserInfo.getUserId()];
        System.debug('~~~~ BoltCalloutEngineQueueableTest::testUserSelection: userLst ' + userLst);
        userLst[0].BOLT_Key__c = '1';
        userLst[0].ADP_Associate_OID__c = '1';
        Map<Id, User> userById = new Map<Id, User>(userLst);
        
        System.debug('~~~~ BoltCalloutEngineQueueableTest::testUserSelection: userById.size() ' + userById.size());
        ExecutionService chainQueueableService = new ExecutionService();
        List<ExecutionItem> executionItemLst = chainQueueableService.buildExecutionItemsList(GeneralConstants.OBJ_USER, GeneralConstants.AFTER_INSERT, userById, null);

        Boolean hasUserSelection = false;
        for (ExecutionItem item : executionItemLst) {
            if (item.getSelection().getSelectionName() == BOLT_USER_SELECTION) {
                hasUserSelection = true;
            }
        }
        System.assertEquals(true, hasUserSelection, 'No execution items for insert of user');
        System.assert(executionItemLst[0].getSelection().getRecIds().size() == userById.size(), 'Count of user selected doesn\'t match size of user list');
        System.assert(executionItemLst[0].getSelection().getSelectionName() == BOLT_USER_SELECTION, 'Selection name for bolt user not selected');  

        //unit testing selection method
        //User newUser = [SELECT Id, ADP_Associate_OID__c, BOLT_Key__c, Email, Username, FederationIdentifier FROM User WHERE IsActive=true AND ADP_Associate_OID__c LIKE 'ABDC%' LIMIT 1];
        User newUser = userLst[0];
        User oldUser = null;
        SelectionBoltCalloutUser sbcu = new SelectionBoltCalloutUser();
        
        System.assertEquals(true, sbcu.selectBoltUser(newUser, oldUser), 'Failed: expected record to NOT be selected');
        
        newUser.BOLT_Key__c='lkjlkjadsfa';
        System.assertEquals(true, sbcu.selectBoltUser(newUser, oldUser), 'Failed: expected record to be selected as a new bolt user as true');
        
        oldUser = newUser.clone(true, true, false, true);
        oldUser.ADP_Associate_OID__c = 'ABD8hhdd72kd';
        System.assertEquals(true, sbcu.selectBoltUser(newUser, oldUser), 'Failed: expected record to be selected as an existing bolt user ADP Associate OID changed');
        
        oldUser = newUser.clone(true, true, false, true);
        oldUser.BOLT_Key__c = '899oiihhq34oi';
        System.assertEquals(true, sbcu.selectBoltUser(newUser, oldUser), 'Failed: expected record to be selected as an existing bolt user Bolt Key changed');   

        oldUser = newUser.clone(true, true, false, true);
        newUser.BOLT_Key__c = null;
        newUser.ADP_Associate_OID__c = null;
        System.assertEquals(false, sbcu.selectBoltUser(newUser, oldUser), 'Failed: expected record to be selected as an existing bolt user Bolt Key changed');   

        oldUser = newUser.clone(true, true, false, true);
        oldUser.BOLT_Key__c = null;
        oldUser.ADP_Associate_OID__c = null;
        System.assertEquals(false, sbcu.selectBoltUser(newUser, oldUser), 'Failed: expected record to NOT be selected');   
    }    
}