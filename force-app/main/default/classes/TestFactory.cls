/**
 * @File Name          : TestFactory.cls
 * @Description        : This is a test data factory for creating test records for test classes
 * @Author             : Terri Jiles
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 04-08-2024
 * @Modification Log   : 
 * Ver       Date            Author                  Modification
 * 1.0    2/19/2020          dhoechst                   Initial Version - https://github.com/dhoechst/Salesforce-Test-Factory/blob/master/force-app/main/default/classes/TestFactory.cls
 * 2.0    30/03/2021       Praveenbabu M                 STAR-CR-2199
**/
@isTest
public class TestFactory {
    public static Map<String, Contract> mapContractByKey;

    public static void createJobTestData(Integer numRec) {
        List<Opportunity> oppUpdLst = new List<Opportunity>();
        DataAdmin__c dataAdmin = DataAdmin__c.getOrgDefaults();
        dataAdmin.TurnOffFlow__c=true;
        dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=true;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.SetupOwnerId=UserInfo.getOrganizationId();
        insert dataAdmin;

        Test.startTest();
        List<Account> accLst = new List<Account>();
        accLst.add((Account)TestFactory.createSObject(new Account(Name='Interstate Restoration - North America', Partner_Type__c='Subcontractor'), 'TestFactoryDefaults.AccountDefaults'));
        /*accLst.add(new Account(Name='Interstate Restoration - Hawaii', Partner_Type__c='Subcontractor', RecordTypeId=clientRecordTypeId2));
        accLst.add(new Account(Name='Interstate Restoration - Canada ', Partner_Type__c='Subcontractor', RecordTypeId=clientRecordTypeId2));*/
        insert accLst;
                
        Account acc = (Account)TestFactory.createSObject(new Account(Name='House Account Sandbox', OwnerId='0051U000004spcBQAQ', Status__c='Dormant', Drive_Down__c='Yes', National_Account__c='Yes', Contract_Type__c='MSA Only',Number_of_Active_Contracts__c=1,
            CurrencyIsoCode='USD', Drive_Down_Plan_in_Place__c='Yes',Vertical__c = 'Hospitality', Subvertical__c = 'Airlines', Protocols_ACM_Testing__c='Test', Protocols_Adjusters__c='Test', Protocols_Billing__c='Test', 
            Protocols_Broker__c='Test', Protocols_DFRs__c='Test', Protocols_Portal__c='Test', Protocols_Pricing__c='Test', Protocols_Special_Concerns__c='Test', Protocols_Work_Auth_PO__c='Test', Data_Admin_Reason__c='Bypass Validation Errors'), 'TestFactoryDefaults.AccountDefaults');
        insert acc;

        System.debug('~~~~ TestDataFactory::createJobTestData acc ' + acc);
        Contract contractRec = new Contract(Name='Brookdale Senior Living, Inc._MSA_2018-06-26', External_Id__c='C-0000001',
          AccountId=acc.Id, Status='Draft', Client_Contract_Type__c='Master Service Agreement', StartDate=Date.newInstance(2018, 06, 26),
          Auto_Renew__c=true, Assignment_Change_of_Control__c='no', Fixed_Sum_Not_to_Exceed_Change_Orders__c='no', Indemnification__c='no', Jurisdiction_Choice_of_Law__c='no', Limitations_on_Mechanic_s_Liens__c='no',
          Mediation_Arbitration_Requirements__c='no', Payment_Terms__c='no', Pay_when_paid_Pay_if_paid__c='no', Prevailing_Wage__c='no', Special_Provisions__c='no',
          SpecialTerms='Bill to many different locations.', CompanySignedId='0051U0000062vTaQAI', RecordTypeId='0121U000000b6SnQAI', Rate_Type__c='T&M');
          insert contractRec;
          contractRec.Status='Fully Executed';
          update contractRec;
        Account testAcc = [SELECT Id,Drive_Down__c, National_Account__c,  Number_of_Active_Contracts__c FROM Account WHERE Id=:acc.Id];
        System.debug(logginglevel.INFO, '~~~~ TestDataFactory::createJobTestData acc ' + testAcc);

        Opportunity opp = new Opportunity(Name='House Account - Household Sandbox', AccountId=acc.Id, StageName='Closed Won', National_Account__c='Yes', Date_of_Call__c=Date.newInstance(2019, 10, 21),
        Date_of_Loss__c=Date.today(), Type_of_Facility__c='Bank/Financial', Property_Name__c='Household', Onsite_Contact_Phone__c='(650) 975-9876',
        Onsite_Contact_Email__c='tjiles@interstaterestoration.com', Loss_Street__c='N/A', Loss_City__c='Austin',  Loss_Zip_Postal_Code__c='78753', 
        Cause_of_Damage__c='Asbestos', Problem_Stopped__c='No', CloseDate=Date.today(), OwnerId='0051U000004spcBQAQ', CurrencyIsoCode='USD', RecordTypeId='0121U000000WuhjQAC');    
        insert opp;

        TestFactory.createUsers();
        Test.stopTest();        


        System.debug(logginglevel.INFO, '~~~~~ After DataAdmin update');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());  

        Integer i=0;
        List<WorkOrder> jobInstLst = new List<WorkOrder>();
        List<Job_Sharing__C> jobSharInsLst = new List<Job_Sharing__c>();
        List<User> userLst = new List<User>([SELECT Id FROM User WHERE Username LIKE 'Test_%' AND isActive=true AND Profile.Name='Operations' ORDER BY LastName]);

        Map<String, ServiceTerritory> serviceTerritoryByNameMap = createServiceTerritories();
        ServiceTerritory boltBranch = new ServiceTerritory(Id=serviceTerritoryByNameMap.get('Chicago').Id, Integrate_with_Bolt__c=true);
        update boltBranch;
        
        //create many  jobs
        opp = [Select Id, AccountId From Opportunity Limit 1];
        for (Integer x=0 ; x < numRec ; x++) {
            System.debug(logginglevel.INFO, '~~~~~ ********** x ' + x + ' **************');
            System.debug(logginglevel.INFO, '~~~~~ Inside Beginning Job Looping jobs ');
            System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
            System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
            System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());             
            //List<String> args = new String[]{'0','number','0000-00-0000'};

            Id servTerrId;
            //Id servTerrId = serviceTerritoryByNameMap.get('Denver').Id;
            switch on x {
              when 0 {
                //Bolt
                servTerrId = serviceTerritoryByNameMap.get('Denver').Id;
              }
              when 1 {
                //No General Manager Use Case
                servTerrId = serviceTerritoryByNameMap.get('Chicago').Id;
              }
              when else {
                //Active General Manager Use Case
                servTerrId = serviceTerritoryByNameMap.get('Austin').Id;
              }
            }
            
            //String jobNumber = String.format(x.format(), args);
            //System.debug(logginglevel.INFO, '~~~~~ Inside Middle Job Looping jobs ' + jobNumber);
            System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
            System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
            System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());                        
            jobInstLst.add((WorkOrder)TestFactory.createSObject(new WorkOrder(Job_Name__c='Brookdale-Tempe', Job_Number_Claim__c=x.format(), AccountId=opp.AccountId,  Opportunity__c=opp.Id, Status='Not Started', 
              BD_Account_Manager__c=userLst[1].Id, Project_Director__c=userLst[2].Id, Project_Manager__c=userLst[3].Id,
              AP_Approver__c=userLst[0].Id, BD_Account_Manager_2__c=userLst[4].Id,
              //CR-2199 changed construction manager field to RM_CM_OM__c
              RM_CM_OM__c=userLst[5].Id,  Regional_Coordinator__c=userLst[6].Id, 
              BD_Account_Manager_3__c=userLst[7].Id, OwnerId=userLst[8].Id,
              //STAR-4435
              Senior_Project_Manager__c=userLst[9].Id,
              Date_of_Call__c=Date.newInstance(2020,01,13), Date_of_Loss__c=Date.newInstance(2020,01,130), Street='1610 E Guadalupe Rd.', City='Tempe', StateCode='AZ', PostalCode='85283', CountryCode='US',
              Status_Note__c='test', Send_to_Accounting__c=false,
              Vertical__c = 'Hospitality' , Subvertical__c = 'Airlines',
              ServiceTerritoryId=servTerrId, Data_Admin_Reason__c='Bypass Validation Errors',
              BD_Account_Manager_Split__c=50, BD_Account_Manager_2_Split__c=30, BD_Account_Manager_3_Split__c=20), 'TestFactoryDefaults.JobDefaults'));  
            System.debug(logginglevel.INFO, '~~~~~ End Beginning Job Looping jobs ');
            System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
            System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
            System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());                               
        }

        System.debug(logginglevel.INFO, '~~~~~ Before Job Insert');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());          
        insert jobInstLst;

        System.debug(logginglevel.INFO, '~~~~~ After jobs insert');
        System.debug(logginglevel.INFO, '~~~~~ CPU ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
        System.debug(logginglevel.INFO, '~~~~~ DML Rows ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());
        System.debug(logginglevel.INFO, '~~~~~ DML Statements ' + Limits.getLimitDmlStatements() + ' out of ' + Limits.getLimitDmlStatements());
        dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=false;
        dataAdmin.TurnOffProcessBuilder__c=true;
        dataAdmin.TurnOffValidationRules__c=true;
        dataAdmin.TurnOffFlow__c=true;
        dataAdmin.SetupOwnerId=UserInfo.getOrganizationId();
        update dataAdmin;       
  }

  public static void turnOffDataAdminAllExceptTrigger() {
    DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
    System.debug('~~~~~~ ' + dataAdmin.Id );
    dataAdmin.TurnOffTrigger__c=false;
    dataAdmin.TurnOffWorkflow__c=true;
    dataAdmin.TurnOffProcessBuilder__c=true;
    dataAdmin.TurnOffValidationRules__c=true;
    dataAdmin.TurnOffFlow__c=true;
    if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
        dataAdmin.SetupOwnerId = UserInfo.getUserId();
        insert dataAdmin;  
    }
    else {
        update dataAdmin;
    } 
  }

  public static void turnOffDataAdminAll() {
    DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId());
    System.debug('~~~~~~ ' + dataAdmin.Id );
    dataAdmin.TurnOffTrigger__c=true;
    dataAdmin.TurnOffWorkflow__c=true;
    dataAdmin.TurnOffProcessBuilder__c=true;
    dataAdmin.TurnOffValidationRules__c=true;
    dataAdmin.TurnOffFlow__c=true;
    if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
        dataAdmin.SetupOwnerId = UserInfo.getUserId();
        insert dataAdmin;  
    }
    else {
        update dataAdmin;
    } 
  }  


  public static void turnOffDataAdminAll(User runningUser) {
    DataAdmin__c dataAdmin = DataAdmin__c.getInstance(runningUser.Id);
    System.debug('~~~~~~ ' + dataAdmin.Id );
    dataAdmin.TurnOffTrigger__c=true;
    dataAdmin.TurnOffWorkflow__c=true;
    dataAdmin.TurnOffProcessBuilder__c=true;
    dataAdmin.TurnOffValidationRules__c=true;
    dataAdmin.TurnOffFlow__c=true;
    if (dataAdmin.Id == null || dataAdmin.SetupOwnerId == null) {
        dataAdmin.SetupOwnerId = UserInfo.getUserId();
        insert dataAdmin;  
    }
    else {
        update dataAdmin;
    } 
  } 

  public static void turnOffDataAdmin(Boolean turnOffTrigger, Boolean turnOffWorkFlow, Boolean turnOffProcessBuilder, Boolean turnOffValidationRules, Boolean turnOffFlow, User runningUser) {
      DataAdmin__c dataAdmin = DataAdmin__c.getInstance(runningUser.Id);
      System.debug('~~~~~~ ' + dataAdmin.Id );
      dataAdmin.TurnOffTrigger__c=turnOffTrigger;
      dataAdmin.TurnOffWorkflow__c=turnOffWorkFlow;
      dataAdmin.TurnOffProcessBuilder__c=turnOffProcessBuilder;
      dataAdmin.TurnOffValidationRules__c=turnOffValidationRules;
      dataAdmin.TurnOffFlow__c=turnOffFlow;
      if (dataAdmin.Id == null || dataAdmin.SetupOwnerId != runningUser.Id) {
          dataAdmin.SetupOwnerId = UserInfo.getUserId();
          insert dataAdmin;  
      }
      else {
          update dataAdmin;
      }  
  }

  @future
  public static void createUsers() {
    createUsersNonFuture();
  }

  public static void createUsersNonFuture() {
    Map<String, Id> profileIdByName = new Map<String, Id>();
    for (Profile p : [SELECT Id, Name FROM Profile]) {
      profileIdByName.put(p.Name, p.Id);
    }
    List<User> userLst = new List<User>();
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345678', Associate_Id__c='ABCD12345678', Bolt_Key__c='1', LastName='Approver', FirstName='AP', Alias='APA', Email='apa@interstate.com.invalid', Username='Test_apa@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false));    
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345679', Associate_Id__c='ABCD12345679', Bolt_Key__c='2', LastName='BDAccountManager', FirstName='BD', Alias='BDA', Email='bda@interstate.com.invalid', Username='Test_bda@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States', Sales_Commissionable_User__c=true), 'TestFactoryDefaults.UserDefaults', false));
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345680', Associate_Id__c='ABCD12345680', Bolt_Key__c='3', LastName='BDAccountManager2', FirstName='BD', Alias='BDA2', Email='bda2@interstate.com.invalid', Username='Test_bda2@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States', Sales_Commissionable_User__c=true), 'TestFactoryDefaults.UserDefaults', false));
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345681', Associate_Id__c='ABCD12345681', Bolt_Key__c='4', LastName='Manager', FirstName='Construction', Alias='CM', Email='cm@interstate.com.invalid', Username='Test_cm@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false));    
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345682', Associate_Id__c='ABCD12345682', Bolt_Key__c='5', LastName='Manager', FirstName='Project', Alias='PM', Email='PM@interstate.com.invalid', Username='Test_PM@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false));
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345683', Associate_Id__c='ABCD12345683', Bolt_Key__c='6', LastName='Coordinator', FirstName='Regional', Alias='RC', Email='rc@interstate.com.invalid', Username='Test_rc@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false));    
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345684', Associate_Id__c='ABCD12345684', Bolt_Key__c='7', LastName='Director', FirstName='Project', Alias='PD', Email='PD@interstate.com.invalid', Username='Test_PD@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false));
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345685', Associate_Id__c='ABCD12345685', Bolt_Key__c='8', LastName='BDAccountManager3', FirstName='BDt', Alias='BDA3', Email='BD3@interstate.com.invalid', Username='Test_BD3@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States', Sales_Commissionable_User__c=true), 'TestFactoryDefaults.UserDefaults', false));
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345686', Associate_Id__c='ABCD12345686', Bolt_Key__c='9', LastName='Owner', FirstName='This', Alias='Owner', Email='Owner@interstate.com.invalid', Username='Test_Owner@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false));
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345687', Associate_Id__c='ABCD12345687', Bolt_Key__c='10', LastName='zAdd1', FirstName='User', Alias='User1', Email='Add1@interstate.com.invalid', Username='Test_add1@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false));
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345688', Associate_Id__c='ABCD12345688', Bolt_Key__c='11', LastName='zAdd2', FirstName='User', Alias='User2', Email='Add2@interstate.com.invalid', Username='Test_add2@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false));      
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345689', Associate_Id__c='ABCD12345689', Bolt_Key__c='12', LastName='zAdd3', FirstName='User', Alias='User3', Email='Add3@interstate.com.invalid', Username='Test_add3@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=false, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false));
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345690', Associate_Id__c='ABCD12345690', Bolt_Key__c='13', LastName='zAdd4', FirstName='User', Alias='User4', Email='Add4@interstate.com.invalid', Username='Test_add4@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=false, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false));   
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345691', Associate_Id__c='ABCD12345691', Bolt_Key__c='14', LastName='zAdd5', FirstName='User', Alias='User5', Email='Add5@interstate.com.invalid', Username='Test_add5@interstate.com.STAR22', profileId=profileIdByName.get('Chatter Free User'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false)); 
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345692', Associate_Id__c='ABCD12345692', Bolt_Key__c='15', LastName='zATM1', FirstName='User', Alias='ATM1', Email='ATM1@interstate.com.invalid', Username='ATM1@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false)); 
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345693', Associate_Id__c='ABCD12345693', Bolt_Key__c='16', LastName='zATM2', FirstName='User', Alias='ATM2', Email='ATM2@interstate.com.invalid', Username='ATM2@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false)); 
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345694', Associate_Id__c='ABCD12345694', Bolt_Key__c='17', LastName='zATM3', FirstName='User', Alias='ATM3', Email='ATM3@interstate.com.invalid', Username='ATM3@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false)); 
    //STAR-4435
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD12345695', Bolt_Key__c='18', LastName='SeniorProjectManager', FirstName='User', Alias='SPM', Email='SPM@interstate.com.invalid', Username='SPM@interstate.com.STAR22', profileId=profileIdByName.get('Operations'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false)); 
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD11111111', Bolt_Key__c='19', LastName='Sync', FirstName='Bolt', Alias='Boltx', Email='Bolt@interstate.com.invalid', Username='Bolt@interstate.com.STAR22', profileId=profileIdByName.get('Integration'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false)); 
    userLst.add((user)TestFactory.createSObject(new User(ADP_Associate_OID__c='ABCD22222222', Bolt_Key__c='20', LastName='Admin', FirstName='Admin', Alias='Admin', Email='Admin@interstate.com.invalid', Username='admin@interstate.com.STAR22', profileId=profileIdByName.get('System Administrator'), isActive=true, Is_UAT_User__c=true, Country='United States'), 'TestFactoryDefaults.UserDefaults', false)); 
    insert userLst;
    for (User u : userLst) {
      System.debug('~~~~ TestFactory::createUsers: u - ' + u);
    }
  }
  public static Map<String, ServiceTerritory> createServiceTerritories() {
    Map<String, OperatingHours> operatingHoursByNameMap = SandboxTestData.createOperatingHours();
    insert  operatingHoursByNameMap.values();

    Map<String, TimeSlot> timeSlotByNameMap = SandboxTestData.createTimeSlots(operatingHoursByNameMap);
    insert timeSlotByNameMap.values();

    Map<String, ServiceTerritory> serviceTerritoryByKey = SandboxTestData.createServiceTerritories(operatingHoursByNameMap);
    insert serviceTerritoryByKey.values();

    return serviceTerritoryByKey;
  }

  public static SObject createSObject(SObject sObj) {
      // Check what type of object we are creating and add any defaults that are needed.
      String objectName = String.valueOf(sObj.getSObjectType());
      // Construct the default values class. Salesforce doesn't allow '__' in class names
      String defaultClassName = objectName.replaceAll('__(c|C)$|__', '') + 'Defaults';
      System.debug('~~~~ TestFactory::createSObject(SObject sobj): defaultClassName ' + defaultClassName);
      // If there is a class that exists for the default values, then use them
      if (Type.forName('TestFactoryDefaults.' + defaultClassName) != null) {
        sObj = createSObject(sObj, 'TestFactoryDefaults.' + defaultClassName);
      }
      return sObj;
  }

  public static SObject createSObject(SObject sObj, Boolean doInsert) {
    SObject retObject = createSObject(sObj);
    if (doInsert) {
      insert retObject;
    }
    return retObject;
  }

  public static SObject createSObject(SObject sObj, String defaultClassName) {
    // Create an instance of the defaults class so we can get the Map of field defaults
    Type t = Type.forName(defaultClassName);
    if (t == null) {
      Throw new TestFactoryException('Invalid defaults class.');
    }
    FieldDefaults defaults = (FieldDefaults)t.newInstance();
    addFieldDefaults(sObj, defaults.getFieldDefaults());
    return sObj;
  }

  public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
    SObject retObject = createSObject(sObj, defaultClassName);
    if (doInsert) {
      insert retObject;
    }
    return retObject;
  }

  public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects) {
    return createSObjectList(sObj, numberOfObjects, (String)null);
  }

  public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, Boolean doInsert) {
    SObject[] retList = createSObjectList(sObj, numberOfObjects, (String)null);
    if (doInsert) {
      insert retList;
    }
    return retList;
  }

  public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean doInsert) {
    SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName);
    if (doInsert) {
      insert retList;
    }
    return retList;
  }

  public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, String defaultClassName) {
    SObject[] sObjs = new SObject[] {};
    SObject newObj;

    // Get one copy of the object
    if (defaultClassName == null) {
      newObj = createSObject(sObj);
    } else {
      newObj = createSObject(sObj, defaultClassName);
    }

    // Get the name field for the object
    System.debug('~~~~ TestFactory::createSObjectLst: isAccount? - ' + String.valueOf(sObj.getSObjectType() == Account.sObjectType));
    String nameField = String.valueOf(nameFieldMap.get(sObj.getSObjectType()));
    Boolean nameIsAutoNumber = false;
    if (nameField == null) {
      nameField = 'Name';
      nameIsAutoNumber = true;
    } else {
      nameIsAutoNumber = sObj.getSobjectType().getDescribe().fields.getMap().get(nameField).getDescribe().isAutoNumber();
    }
    // Clone the object the number of times requested. Increment the name field so each record is unique
    for (Integer i = 0; i < numberOfObjects; i++) {
      SObject clonedSObj = newObj.clone(false, true);
      if (!nameIsAutoNumber || clonedSObj.getSObjectType()==Account.sObjectType) {
        clonedSObj.put(nameField, (String)clonedSObj.get(nameField) + ' ' + i);
      }
      sObjs.add(clonedSObj);
    }
    return sObjs;
  }

  private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
    // Loop through the map of fields and if they weren't specifically assigned, fill them.
    Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();
    for (Schema.SObjectField field : defaults.keySet()) {
      if (!populatedFields.containsKey(String.valueOf(field))) {
        sObj.put(field, defaults.get(field));
      }
    }
  }

  // When we create a list of SObjects, we need to have a unique field for the insert if there isn't an autonumber field.
  // Usually we use the Name field, but some objects don't have a name field.
  private static Map<Schema.SObjectType, Schema.SObjectField> nameFieldMap = new Map<Schema.SObjectType, Schema.SObjectField> {
    Contact.sObjectType => Contact.LastName,
        Case.sObjectType => Case.CaseNumber //this is the autonumber field
  };

    public class TestFactoryException extends Exception {}

  // Use the FieldDefaults interface to set up values you want to default in for all objects.
  public interface FieldDefaults {
    Map<Schema.SObjectField, Object> getFieldDefaults();
    }
    
}