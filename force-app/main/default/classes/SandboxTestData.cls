/**
 * @File Name          : SandboxTestData.cls
 * @Description        : Generates test data for sandbox
 *                          https://www.salesforceben.com/auto-populate-salesforce-sandboxes-with-sample-records/
 * @Author             : T Jiles
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 09-21-2023
 * @Modification Log   : 
 * Ver       Date            Author              Modification
 * 1.0    1/21/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 * 2.0    05/07/2024  Kiran K (CFS)               STAR-6569 removed unused Sage Fields 
 * 2.1    05/07/2024  Kiran K (CFS)               STAR-6221 remove opportunity references
**/
global class SandboxTestData implements SandboxPostCopy {

    global void runApexClass(System.SandboxContext context) {
        System.debug('Org ID: ' + context.organizationId());
        System.debug('Sandbox ID: ' + context.sandboxId());
        System.debug('Sandbox Name: ' + context.sandboxName());        
        upsertSandboxData();
    }
    private static Id ownerId = [SELECT Id FROM User WHERE (Username LIKE 'efox@interstaterestoration.com%' OR Username LIKE 'elyssa.fox@firstonsite.com%' OR Username LIKE 'salesforce@firstonsite.com%') AND UserType='Standard' AND IsActive=true Limit 1].Id;
    
    public static void upsertSandboxData() {
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

        Bolt__c bolt = Bolt__c.getInstance(UserInfo.getUserId());
        bolt.Is_Bolt_Integration_User__c=true;
        if (bolt.Id == null || bolt.SetupOwnerId == null) {
            bolt.SetupOwnerId = UserInfo.getUserId();
            insert bolt;
        } else {
            update bolt;
        }
         

        //Id profileId = [Select Id From Profile Where Name='System Administrator' Limit 1].Id;

        //populateData();

        //worktype
        Map<String, WorkType> workTypeByNameMap =  new  Map<String, WorkType>();
        Map<String, OperatingHours> operatingHoursByNameMap = new  Map<String, OperatingHours>();
        Map<String, ServiceTerritory> serviceTerritoryByNameMap  = new Map<String, ServiceTerritory>();
        Map<String, Account> accByTempIdMap = new Map<String, Account>();
        Map<String, Contact> contactByNameMap = new Map<String, Contact>();
        Map<String, Contract> contractsByNameMap = new Map<String, Contract>();
        Map<String, WorkOrder> jobByJobNumberMap = new Map<String, WorkOrder>();
        Map<String, Area_Wide_Event__c> aweByNameMap = createAreaWideEvents();
        insert aweByNameMap.values();

        workTypeByNameMap = createWorkTypes();
        upsert workTypeByNameMap.values();

        //pricebook
        Map<String, Pricebook2> pricebookByNameMap = createPriceBook();
        List<Pricebook2> pricebookLst = new List<Pricebook2>([Select Id From Pricebook2 Where Name='Standard Price Book']);
        if (pricebookLst.isEmpty()) {
            upsert pricebookByNameMap.values() Name; 
        } else {
            pricebookByNameMap.put('Standard Price Book', pricebookLst[0]);
        }


        //operating hours
        operatingHoursByNameMap= new Map<String, OperatingHours>(); 
        if ([Select Id From OperatingHours Where Name='Standard Operating Hours'].isEmpty()) {
            operatingHoursByNameMap = createOperatingHours();
            upsert operatingHoursByNameMap.values() Name;
            Map<String, TimeSlot> timeSlotByNameMap = createTimeSlots(operatingHoursByNameMap);
            insert timeSlotByNameMap.values();
        } else {
            for (OperatingHours oh : [SELECT Id, Name FROM OperatingHours WHERE Name='Standard Operating Hours']) {
                operatingHoursByNameMap.put(oh.Name, oh);
            }
        }

        //service territories
        if ([Select Id FROM ServiceTerritory Limit 1].isEmpty()) {
            serviceTerritoryByNameMap = createServiceTerritories(operatingHoursByNameMap);
            upsert serviceTerritoryByNameMap.values();
        } else {
            for (ServiceTerritory st : [SELECT Id, Name FROM ServiceTerritory]) {
                serviceTerritoryByNameMap.put(st.Name, st);
            }
        }

        //Parent portal accounts
        List<Account> ppaLst = new List<Account>();
        Integer i = 0, x=0;
        String defaultAccName = '';
        for(Default_Portal_Account__mdt dpa : [SELECT DeveloperName, CountryCode__c, StateProvinceCode__c, Default_Account_Name__c FROM Default_Portal_Account__mdt]) {
            ppaLst.add(new Account(Name=dpa.Default_Account_Name__c, Partner_Type__c='Subcontractor', Temp_Unique_Id__c=dpa.Default_Account_Name__c, Data_Admin_Reason__c='Bypass Validation Errors' )); 
             
            if (dpa.DeveloperName == 'Default') {
                defaultAccName = dpa.DeveloperName;
                x=i;
            }
            i++;  
        }  
        upsert ppaLst Temp_Unique_Id__c;

        //accounts
        for (DataAdmin__c da : [SELECT TurnOffTrigger__c, TurnOffWorkflow__c, TurnOffProcessBuilder__c, TurnOffValidationRules__c FROM DataAdmin__c]) {
            System.debug('~~~~ SandboxTestData::populateData: da: ' + da);
        }
        //if ([Select Id FROM Account Limit 1].isEmpty()) {
            accByTempIdMap = createAccounts(ppaLst[x]);
            upsert accByTempIdMap.values() Temp_Unique_Id__c;
        //}
        accByTempIdMap.put(defaultAccName, ppaLst[x]);
        
        //contacts
        //if ([Select Id FROM Contact Limit 1].isEmpty()) {        
            contactByNameMap = createContacts(accByTempIdMap, defaultAccName);
            upsert contactByNameMap.values() External_Id__c;
        //}

        //contracts
        //if ([Select Id FROM Contract Limit 1].isEmpty()) {  
            contractsByNameMap = createContracts(accByTempIdMap, contactByNameMap);
         upsert contractsByNameMap.values() External_Id__c;
        //}
        
        //jobs
        //if ([Select Id FROM WorkOrder Limit 1].isEmpty()) {  
            jobByJobNumberMap = createJobs(accByTempIdMap, serviceTerritoryByNameMap, workTypeByNameMap);
            upsert jobByJobNumberMap.values() Job_Number_Claim__c;
        //}

        //if ([Select Id FROM Contract Limit 1].isEmpty()) {  
            List<Contract> contractLst = new List<Contract>();
            for (Contract c : contractsByNameMap.values()) {
                Id jobId=null;
                if (c.Name=='Cinemark USA_NAA_2020-05-10') {
                    jobId=jobByJobNumberMap.get('2004-19-9778').Id;
                } else if (c.Name=='Prologis-Master JOB_2020-01-26') {
                    jobId=jobByJobNumberMap.get('2004-19-8835').Id;            
                }
                contractLst.add(new Contract(Id=c.Id, Status='Fully Executed', Job__c=jobId));
            }
            upsert contractLst;

            //List<Invoice_Request_Form__c> invReqFormLst = createInvoiceRequestForms(jobByJobNumberMap, serviceTerritoryByNameMap, workTypeByNameMap);
            //insert invReqFormLst;
        
        BranchTestDataQueueable btdq = new BranchTestDataQueueable();
        if (!Test.isRunningTest()) {
            System.enqueueJob(btdq);
        }
        //}       
        //DataAdmin__c dataAdmin = DataAdmin__c.getInstance(UserInfo.getUserId()); 
        /*dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=false;
        dataAdmin.TurnOffProcessBuilder__c=false;
        dataAdmin.TurnOffValidationRules__c=false;
        update dataAdmin;  
        */

        
       // Profile portalProfile = [SELECT Id FROM Profile WHERE Name='Customer Community Plus User Custom' Limit 1];
        /*if (!contactByNameMap.containsKey('Joe Schomoe')) {
            contactByNameMap.put('Joe Schomoe', [SELECT ID FROM Contact WHERE Name = 'Joe Schomoe' Limit 1]);
        }*/
       // if ([SELECT Id FROM User WHERE ProfileId=:portalProfile.Id AND Username='test@test.com'].isEmpty()) {
         //   String randomNumber = String.valueof((Math.random() * 999999));
         //   System.debug('randomNumber  is'+randomNumber);
            //insert new User(ProfileId=portalProfile.Id, ContactId=contactByNameMap.get('Joe Schomoe').Id, Username='test@test.com.test.' + randomNumber, Alias='test', Email='test@test.com', Lastname='test', Firstname='test', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey='America/Chicago', Country='United States');
       // }        
        /*dataAdmin.TurnOffTrigger__c=false;
        dataAdmin.TurnOffWorkflow__c=false;
        dataAdmin.TurnOffProcessBuilder__c=false;
        dataAdmin.TurnOffValidationRules__c=false;
        update dataAdmin; */        

    }

    
    public static Map<String, WorkType> createWorkTypes() {
        Map<String, WorkType> workTypeByNameMap = new Map<String, WorkType>();
        workTypeByNameMap.put('Restoration (DR)', new WorkType(Name='Restoration (DR)', Description='', EstimatedDuration=2.00, DurationType='Hours', ShouldAutoCreateSvcAppt=true, Department_Code__c='20'));
        StaticResource jobTypeStaticResource = [SELECT Body from StaticResource WHERE Name = 'JobTypes'];
        String jobTypeCsv = jobTypeStaticResource.Body.toString();

        Integer rowNum = 0;
            
        for(String row : jobTypeCsv.split('\n')) {
            if (rowNum > 0 ) {
                row = FileParserService.preProcessCSVLine(row);
                String[] column = row.split(',');
                WorkType jobType = new WorkType(
                    Name = FileParserService.processCell(column[0]),
                    Department_Code__c = FileParserService.processCell(column[1]),
                    EstimatedDuration = FileParserService.processDecimal(column[2]),
                    DurationType = FileParserService.processCell(column[3]),
                    ShouldAutoCreateSvcAppt = FileParserService.processBoolean(column[4])
                ); 
                workTypeByNameMap.put(FileParserService.processCell(column[0]), jobType);   
            }
            rowNum++;                                                                                                                         
        }
        return workTypeByNameMap;
    }

    private static Map<String, Pricebook2> createPriceBook() {
        Map<String, Pricebook2> pricebookByNameMap = new Map<String, Pricebook2>();
        pricebookByNameMap.put('Standard Price Book', new Pricebook2(IsActive=true,Name='Standard Price Book'));
        return pricebookByNameMap;
    }

    public static Map<String, OperatingHours> createOperatingHours() {
        Map<String, OperatingHours> operatingHoursByNameMap = new Map<String, OperatingHours>();
        operatingHoursByNameMap.put('Standard Operating Hours', new OperatingHours(Name='Standard Operating Hours', TimeZone='America/Chicago'));
        return operatingHoursByNameMap;
    }

    public static Map<String, TimeSlot> createTimeSlots(Map<String, OperatingHours> operatingHoursByNameMap) {
        Map<String, TimeSlot> timeSlotByNameMap = new Map<String, TimeSlot>();
        timeSlotByNameMap.put('SOP-001', new TimeSlot(DayOfWeek='Monday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(8, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(0, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-002', new TimeSlot(DayOfWeek='Tuesday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(8, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(0, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-003', new TimeSlot(DayOfWeek='Wednesday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(8, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(0, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-004', new TimeSlot(DayOfWeek='Thursday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(8, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(0, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-005', new TimeSlot(DayOfWeek='Friday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(8, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(0, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-006', new TimeSlot(DayOfWeek='Saturday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(8, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(0, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-007', new TimeSlot(DayOfWeek='Sunday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(8, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(0, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-008', new TimeSlot(DayOfWeek='Monday', FSL__Designated_Work_Boolean_Fields__c='', EndTime=Time.newInstance(18, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(8, 0, 0, 0), Type='Normal'));
        timeSlotByNameMap.put('SOP-009', new TimeSlot(DayOfWeek='Tuesday', FSL__Designated_Work_Boolean_Fields__c='', EndTime=Time.newInstance(18, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(8, 0, 0, 0), Type='Normal'));
        timeSlotByNameMap.put('SOP-010', new TimeSlot(DayOfWeek='Wednesday', FSL__Designated_Work_Boolean_Fields__c='', EndTime=Time.newInstance(17,55, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(8, 0, 0, 0), Type='Normal'));
        timeSlotByNameMap.put('SOP-011', new TimeSlot(DayOfWeek='Thursday', FSL__Designated_Work_Boolean_Fields__c='', EndTime=Time.newInstance(17,55, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(8, 0, 0, 0), Type='Normal'));
        timeSlotByNameMap.put('SOP-012', new TimeSlot(DayOfWeek='Friday', FSL__Designated_Work_Boolean_Fields__c='', EndTime=Time.newInstance(17,55, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(8, 0, 0, 0), Type='Normal'));
        timeSlotByNameMap.put('SOP-013', new TimeSlot(DayOfWeek='Saturday', FSL__Designated_Work_Boolean_Fields__c='', EndTime=Time.newInstance(18, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(8, 0, 0, 0), Type='Normal'));
        timeSlotByNameMap.put('SOP-014', new TimeSlot(DayOfWeek='Sunday', FSL__Designated_Work_Boolean_Fields__c='', EndTime=Time.newInstance(17,55, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(8, 0, 0, 0), Type='Normal'));
        timeSlotByNameMap.put('SOP-015', new TimeSlot(DayOfWeek='Monday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(0, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(18, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-016', new TimeSlot(DayOfWeek='Tuesday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(0, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(18, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-017', new TimeSlot(DayOfWeek='Wednesday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(0, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(18, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-018', new TimeSlot(DayOfWeek='Thursday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(0, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(18, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-019', new TimeSlot(DayOfWeek='Friday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(0, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(18, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-020', new TimeSlot(DayOfWeek='Saturday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(0, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(18, 0, 0, 0), Type='Extended'));
        timeSlotByNameMap.put('SOP-021', new TimeSlot(DayOfWeek='Sunday', FSL__Designated_Work_Boolean_Fields__c='FSL__Emergency__c', EndTime=Time.newInstance(0, 0, 0, 0), OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id, StartTime=Time.newInstance(18, 0, 0, 0), Type='Extended'));        
        return timeSlotByNameMap;
    }
    
    public static Map<String, ServiceTerritory> createServiceTerritories(Map<String, OperatingHours> operatingHoursByNameMap) {
        Map<String, ServiceTerritory> serviceTerritoryByNameMap = new Map<String, ServiceTerritory>();

        StaticResource branchStaticResource = [SELECT Body from StaticResource WHERE Name = 'Branches'];
        String branchCsv = branchStaticResource.Body.toString();
        Integer rowNum = 0;
            
        for(String row : branchCsv.split('\n')) {
            if (rowNum > 0) {
                row = FileParserService.preProcessCSVLine(row);
                String[] column = row.split(',');
                ServiceTerritory branch = new ServiceTerritory(
                    Name = FileParserService.processCell(column[0]),
                    IsActive = FileParserService.processBoolean(column[1]),
                    City = FileParserService.processCell(column[2]),
                    CountryCode = FileParserService.processCell(column[3]),
                    CurrencyISOCode = FileParserService.processCell(column[4]),
                    General_Manager__c= FileParserService.processId(column[5]),
                    Description = FileParserService.processCell(column[6]),
                    Location_Number__c=FileParserService.processCell(column[7]),
                    StateCode=FileParserService.processCell(column[8]),
                    PostalCode=FileParserService.processCell(column[9]),
                    Region__c=FileParserService.processCell(column[10]),
                    Legal_Entity__c=FileParserService.processCell(column[11]),
                    Legacy_Location_Number__c=FileParserService.processCell(column[12]),
                    Integrate_with_Bolt__c=FileParserService.processBoolean(column[13]),
                    OperatingHoursId=operatingHoursByNameMap.get('Standard Operating Hours').Id
                ); 
                serviceTerritoryByNameMap.put(FileParserService.processCell(column[0]), branch);    
            }
            rowNum++;                                                                                                                        
        } 
        return serviceTerritoryByNameMap;  
    }  

    private static Map<String, Account> createAccounts(Account defaultAccName) {
        Map<String, Account> accByTempIdMap = new Map<String, Account>();

        accByTempIdMap.put('TEST Brookdale Senior Living, Inc. TEST TEST', new Account(Name='TEST Brookdale Senior Living, Inc.', Status__c='Active',  
            Phone='1-866=786-9025', Industry='Senior Living', Contract_Type__c='MSA Only', Number_of_Active_Contracts__c=1, Annual_Sales_Potential__c=13000000.00,
            Protocols_Work_Auth_PO__c='Work Authorizations should only be submitted to and signed by the RDPM or RMT (these individuals usually arent on site). On site personnel should not be asked to sign paperwork. Karla can help with this. Please dont let an unsigned work auth from moving',
            Protocols_Billing__c='Invoices -via email to your primary point of contact on the project. The community name and address along with a brief description of work should be on the invoice. Copy Karla at karlat@interstaterestoration.com',
            Protocols_ACM_Testing__c='N/A', Protocols_Adjusters__c='Patrick Washington with York /r/n Patrick.Washington@yorkrsg.com', Protocols_DFRs__c='N/A', Protocols_Broker__c='Willis (Brookdale’s broker)',
            Protocols_Pricing__c='2017 T&M Rate Schedule/. Our old overtime rates apply unless state requirements take precedence.', Protocols_Special_Concerns__c='See File attached', Protocols_Portal__c='N/A',
            BillingStreet='111 Westwood Pl', BillingCity='Brentwood', BillingStateCode='TN', BillingPostalCode='37027-5016', BillingCountryCode='US',Drive_Down_Plan_in_Place__c='No', Drive_Down__c='No',
            Referenceable__c=true, NumberOfEmployees=10000, Website='http://brookdale.com', CurrencyIsoCode='USD', Temp_Unique_Id__c='Brookdale Senior Living, Inc.', Parent_Portal_Account__c=defaultAccName.Id, Data_Admin_Reason__c='Mass Create'));
        accByTempIdMap.put('TEST Cinemark USA TEST TEST', new Account(Name='TEST Cinemark USA', Status__c='Active', Drive_Down__c='No', RFP_Won__c='Yes',  
            Phone='(530) 415-0954', Industry='Retail', Contract_Type__c='MSA Only', Number_of_Active_Contracts__c=1, Annual_Sales_Potential__c=50000.00,
            Protocols_Work_Auth_PO__c='We need signed Work Authorization-Short Form Client Solutions Client',Drive_Down_Plan_in_Place__c='No',
            Protocols_Billing__c='upload all invoices to Service Channel',
            Protocols_ACM_Testing__c='They call their own IH with a suggestion from Interstate', Protocols_Adjusters__c='Will Grace at FM Global 225-603-2987 william.grace@fmglobal.com The client will let us know when to involve FM Global.', 
            Protocols_DFRs__c='All estimates and DFR’s are uploaded to Service Channel at attachments@servicechannel.com Please include the WO# in the subject line and copy jdaniel@interstaterestoration.com', 
            Protocols_Broker__c='FM Global', Protocols_Pricing__c='2019 T&M', Protocols_Special_Concerns__c='Do not remove carpet until get ok from corporate.   No drilling or cutting of sheetrock until we receive approval.', Protocols_Portal__c='N/A',
            BillingStreet='3900 Dallas Pkwy #500', BillingCity='Plano', BillingStateCode='TX', BillingPostalCode='75093', BillingCountryCode='US',
            Referenceable__c=true, CurrencyIsoCode='USD', Temp_Unique_Id__c='Cinemark USA', OwnerId=ownerId, Parent_Portal_Account__c=defaultAccName.Id, Data_Admin_Reason__c='Mass Create'));
        accByTempIdMap.put('TEST Prologis, Inc. TEST TEST', new Account(Name='TEST Prologis, Inc.', Status__c='Active', Drive_Down__c='No', 
            Phone='303-567-5000', Industry='Commercial Property Mgmt', Contract_Type__c='MSA Only', Number_of_Active_Contracts__c=1, 
            Protocols_Work_Auth_PO__c='Do not need to have Work Auth Signed. Client Solutions Contract in place.',
            Protocols_Billing__c='Send Bill to Manager and Office WO came from.', Drive_Down_Plan_in_Place__c='No',
            Protocols_ACM_Testing__c='Proceed with Approval from Manager', Protocols_Adjusters__c='Get Direction from Manager', 
            Protocols_DFRs__c='Send out Daily. Copy all who requests it.', 
            Protocols_Broker__c='N/A', Protocols_Pricing__c='Our current client solutions T&M pricing.', Protocols_Special_Concerns__c='Case by Case', 
            Protocols_Portal__c='N/A', BillingStreet='1800 Wazee Street, Ste. 500', BillingCity='Denver', BillingStateCode='CO', BillingPostalCode='80202', BillingCountryCode='US',
            CurrencyIsoCode='USD', Temp_Unique_Id__c='Prologis, Inc.', OwnerId=ownerId, Parent_Portal_Account__c=defaultAccName.Id, Data_Admin_Reason__c='Mass Create'));
        accByTempIdMap.put('TEST Aimbridge Hospitality TEST TEST', new Account(Name='TEST Aimbridge Hospitality', Status__c='Active', Drive_Down__c='No', 
            Phone='(832) 229-5991', Vertical__c='Hospitality', Contract_Type__c='CWA Only', Number_of_Active_Contracts__c=0, 
            Protocols_Work_Auth_PO__c='Advanced work order required',
            Protocols_Billing__c='upload all invoices to Service Channel', Drive_Down_Plan_in_Place__c='No',
            Protocols_ACM_Testing__c='ACM testing required if no survey on file', 
            Protocols_DFRs__c='DFR\'s to be sent to General Manager', 
            Protocols_Broker__c='N/A', Protocols_Pricing__c='', Protocols_Special_Concerns__c='N/A', 
            Protocols_Portal__c='None', BillingStreet='5851 Legacy Circle Suite 400', BillingCity='Plano', BillingStateCode='TX', BillingPostalCode='75024', BillingCountryCode='US',
            CurrencyIsoCode='USD', Temp_Unique_Id__c='Aimbridge Hospitality', OwnerId=ownerId, Parent_Portal_Account__c=defaultAccName.Id, Data_Admin_Reason__c='Mass Create'));
        accByTempIdMap.put('TEST House Account TEST TEST', new Account(Name='TEST House Account', Status__c='Dormant', Drive_Down__c='No', Contract_Type__c='MSA Only',Number_of_Active_Contracts__c=1, 
            CurrencyIsoCode='USD', Drive_Down_Plan_in_Place__c='No', Temp_Unique_Id__c='House Account', Data_Admin_Reason__c='Mass Create'));
        /*
        accByTempIdMap.put('Interstate Restoration - Arizona', new Account(Name='Interstate Restoration - Arizona', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); 
        accByTempIdMap.put('Interstate Restoration - California', new Account(Name='Interstate Restoration - California', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); 
        accByTempIdMap.put('Interstate Restoration - Canada', new Account(Name='Interstate Restoration - Canada', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); 
        accByTempIdMap.put('Interstate Restoration - Colorado', new Account(Name='Interstate Restoration - Colorado', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); 
        accByTempIdMap.put('Interstate Restoration - Florida', new Account(Name='Interstate Restoration - Florida', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); 
        */
       
        //accByTempIdMap.put('Interstate Restoration - Hawaii', new Account(Name='Interstate Restoration - Hawaii', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); 
        /*accByTempIdMap.put('Interstate Restoration - Michigan', new Account(Name='Interstate Restoration - Michigan', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); 
        accByTempIdMap.put('Interstate Restoration - Missouri', new Account(Name='Interstate Restoration - Missouri', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); 
        accByTempIdMap.put('Interstate Restoration - North America', new Account(Name='Interstate Restoration - North America', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); 
        */
        //accByTempIdMap.put('Interstate Restoration - Texas', new Account(Name='Interstate Restoration - Texas', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); 
        /*accByTempIdMap.put('Interstate Restoration - Washington', new Account(Name='Interstate Restoration - Washington', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1));
        
        accByTempIdMap.put('Interstate Restoration', new Account(Name='Interstate Restoration', Partner_Type__c='Subcontractor', OwnerId=ownerId,Number_of_Active_Contracts__c=1)); */        
        
        for (Account acc : accByTempIdMap.values()) {
            System.debug('~~~~ SandboxTestData::createAccounts: acc.RecordTypeId - ' + acc.RecordTypeId + ', PO_Status__c - ' + acc.PO_Status__c);
        }
        return accByTempIdMap;
    }

    private static Map<String, Contact> createContacts(Map<String, Account> accByTempIdMap, String defaultAccName) {
        Map<String, Contact> contactByNameMap = new Map<String, Contact>();
        contactByNameMap.put('Mr. George Hicks', new Contact(OwnerId='0051U0000062vTaQAI', FirstName='George', LastName='Hicks', Salutation='Mr.', AccountId=accByTempIdMap.get('TEST Brookdale Senior Living, Inc. TEST TEST').Id,
            Title='FVP Finance', Active__c=true, External_Id__c='Mr. George Hicks'));
        contactByNameMap.put('Mr. Russell Riggs', new Contact(OwnerId='0051U0000062vTaQAI', FirstName='Russell', LastName='Riggs', Salutation='Mr.', AccountId=accByTempIdMap.get('TEST Brookdale Senior Living, Inc. TEST TEST').Id,
            Title='Director of Engineering', Email='rriggs@brookdaleliving.com', Phone='713-993-9999', MobilePhone='713-201-4774', Fax='713-830-5149', Active__c=true, External_Id__c='Mr. Russell Riggs', Audited__c=true, 
            MailingStreet='2929 Post Oak Blvd', MailingCity='Houston', MailingStateCode='TX', MailingPostalCode='77056', MailingCountryCode='US'));
        contactByNameMap.put('Marc Wolfe', new Contact(OwnerId='0051U0000062vTaQAI', FirstName='Marc', LastName='Wolf', AccountId=accByTempIdMap.get('TEST Cinemark USA TEST TEST').Id,
            Title='VP Facilities', Email='mwolfe@cinemark.com', Phone='(530)415-0954', Active__c=true, External_Id__c='Marc Wolfe'));
        contactByNameMap.put('Brandon Persell', new Contact(OwnerId='0051U0000062vTaQAI', FirstName='Brandon', LastName='Persell', AccountId=accByTempIdMap.get('TEST Cinemark USA TEST TEST').Id,
            Title='Facilities', Email='bpersell@cinemark.com', Phone='972-523-2443', Active__c=true, External_Id__c='Brandon Persell'));            
        contactByNameMap.put('Mr. Jeff Bray', new Contact(OwnerId='0051U0000062vTaQAI', FirstName='Jeff', LastName='Bray', AccountId=accByTempIdMap.get('TEST Prologis, Inc. TEST TEST').Id,
            Title='SVP Of Global Risk', Email='bray@prologis.com', Phone='303-567-5000', Active__c=true, External_Id__c='Mr. Jeff Bray'));
        contactByNameMap.put('Mr. Vince Zuppa', new Contact(OwnerId='0051U0000062vTaQAI', FirstName='Vince', LastName='Zuppa', AccountId=accByTempIdMap.get('TEST Prologis, Inc. TEST TEST').Id,
            Title='Vice President, Property Management', Email='vzuppa@prologis.com', Phone='303-567-5000', Active__c=true, External_Id__c='Mr. Vince Zuppa'));   
        contactByNameMap.put('Joe Schomoe', new Contact(OwnerId='0051U0000062vTaQAI', FirstName='Joe', LastName='Schomoe', AccountId=accByTempIdMap.get(defaultAccName).Id, External_Id__c='Joe Schomoe',
            Title='Test', Email='test@test.com', Phone='364-983-9834'));         
        return contactByNameMap;
    }

    private static Map<String, Contract> createContracts(Map<String, Account> accByTempIdMap, Map<String, Contact> contactByNameMap) {
        Map<String, Contract> contractsByNameMap = new Map<String, Contract>();
        contractsByNameMap.put('Brookdale Senior Living, Inc._MSA_2018-06-26', new Contract(Name='Brookdale Senior Living, Inc._MSA_2018-06-26', External_Id__c='C-0000001',
            AccountId=accByTempIdMap.get('TEST Brookdale Senior Living, Inc. TEST TEST').Id, Status='Draft', Client_Contract_Type__c='Master Service Agreement', Contract_Changes__c='Redlined', StartDate=Date.newInstance(2018, 06, 26),
            Auto_Renew__c=true, Assignment_Change_of_Control__c='no', Fixed_Sum_Not_to_Exceed_Change_Orders__c='no', Indemnification__c='no', Jurisdiction_Choice_of_Law__c='no', Limitations_on_Mechanic_s_Liens__c='no',
            Mediation_Arbitration_Requirements__c='no', Payment_Terms__c='no', Pay_when_paid_Pay_if_paid__c='no', Prevailing_Wage__c='no', Special_Provisions__c='no',
            SpecialTerms='Bill to many different locations.', CustomerSignedId=contactByNameMap.get('Mr. George Hicks').Id, CompanySignedId='0051U0000062vTaQAI', RecordTypeId='0121U000000b6SnQAI', OwnerId=ownerId, Rate_Type__c='T&M'));
        contractsByNameMap.put('Cinemark USA_NAA_2009-02-24', new Contract(Name='Cinemark USA_NAA_2009-02-24',  External_Id__c='C-0000002',
            AccountId=accByTempIdMap.get('TEST Cinemark USA TEST TEST').Id, Status='Draft', Client_Contract_Type__c='3rd Party Paper', StartDate=Date.newInstance(2009, 02, 24), Government_Contract__c='No',
            CustomerSignedId=contactByNameMap.get('Marc Wolfe').Id, CustomerSignedTitle='VP Facilities', CustomerSignedDate=Date.newInstance(2009, 02, 24), CompanySignedId='0051U0000062vTaQAI', 
            CompanySignedDate=Date.newInstance(2009,02,24), RecordTypeId='0121U000000b6SnQAI', CurrencyIsoCode='USD', OwnerId=ownerId, Contract_Changes__c='Redlined', Rate_Type__c='Fixed',
            Auto_Renew__c=true));            
        contractsByNameMap.put('Prologis-Master Parent_MSA_2019-08-30', new Contract(Name='Prologis-Master Parent_MSA_2019-08-30',  External_Id__c='C-0000003',
            AccountId=accByTempIdMap.get('TEST Prologis, Inc. TEST TEST').Id, Status='Draft', Client_Contract_Type__c='Master Service Agreement', Contract_Changes__c='Redlined', StartDate=Date.newInstance(2019, 08, 30), Government_Contract__c='No',
            Assignment_Change_of_Control__c='no', Fixed_Sum_Not_to_Exceed_Change_Orders__c='no', Indemnification__c='no', Jurisdiction_Choice_of_Law__c='no', Limitations_on_Mechanic_s_Liens__c='no',
            Mediation_Arbitration_Requirements__c='no', Payment_Terms__c='no', Pay_when_paid_Pay_if_paid__c='no', Prevailing_Wage__c='no', Special_Provisions__c='no',
            CustomerSignedId=contactByNameMap.get('Mr. Jeff Bray').Id, CustomerSignedTitle='Senior Vice President, Global Risk Mngt', CustomerSignedDate=Date.newInstance(2019, 08, 30), 
            CompanySignedId='0051U000006K1RNQA0', CompanySignedDate=Date.newInstance(2009, 02, 24), RecordTypeId='0121U000000b6SnQAI', CurrencyIsoCode='USD', OwnerId=ownerId, Rate_Type__c='T&M',
            Auto_Renew__c=true)); 
        contractsByNameMap.put('Cinemark USA_NAA_2020-05-10', new Contract(Name='Cinemark USA_NAA_2009-02-24',  External_Id__c='C-0000004',
            AccountId=accByTempIdMap.get('TEST Cinemark USA TEST TEST').Id, Status='Draft', Government_Contract__c='No',
            CustomerSignedId=contactByNameMap.get('Marc Wolfe').Id, CustomerSignedTitle='VP Facilities', CustomerSignedDate=Date.newInstance(2009, 02, 24),   
            RecordTypeId='0121U000000b6SsQAI', CurrencyIsoCode='USD', OwnerId=ownerId, 
            Client_Contract_Type__c='Client Work Agreement', Rate_Type__c='T&M', StartDate=Date.newInstance(2020, 05, 10), CompanySignedDate=Date.newInstance(2020, 05, 10), CompanySignedId='0051U0000062vTaQAI', Contract_Changes__c='Redlined',
            Auto_Renew__c=true));            
        contractsByNameMap.put('Prologis-Master JOB_2019-07-19', new Contract(Name='Prologis-Master JOB_2019-07-19',  External_Id__c='C-0000005',
            AccountId=accByTempIdMap.get('TEST Prologis, Inc. TEST TEST').Id, Status='Draft', Government_Contract__c='No',
            Assignment_Change_of_Control__c='no', Fixed_Sum_Not_to_Exceed_Change_Orders__c='no', Indemnification__c='no', Jurisdiction_Choice_of_Law__c='no', Limitations_on_Mechanic_s_Liens__c='no',
            Mediation_Arbitration_Requirements__c='no', Payment_Terms__c='no', Pay_when_paid_Pay_if_paid__c='no', Prevailing_Wage__c='no', Special_Provisions__c='no',
            CustomerSignedId=contactByNameMap.get('Mr. Jeff Bray').Id, CustomerSignedTitle='Senior Vice President, Global Risk Mngt', CustomerSignedDate=Date.newInstance(2019, 08, 30), 
            RecordTypeId='0121U000000b6SsQAI', CurrencyIsoCode='USD', OwnerId=ownerId,
            Client_Contract_Type__c='Client Work Agreement', Rate_Type__c='Fixed', StartDate=Date.newInstance(2019, 07, 19),  CompanySignedDate=Date.newInstance(2019, 07, 19), CompanySignedId='0051U0000062vTaQAI', Contract_Changes__c='Redlined',
            Auto_Renew__c=true)); 
            return contractsByNameMap;
    }

    private static Map<String, WorkOrder> createJobs(Map<String, Account> accByTempIdMap,  Map<String, ServiceTerritory> serviceTerritoryByNameMap, Map<String, WorkType> workTypeByNameMap) {
        Map<String, WorkOrder> jobByJobNumberMap = New Map<String, WorkOrder>();
        jobByJobNumberMap.put('1012-19-20XX', new WorkOrder(Job_Name__c='Brookdale-Tempe TEST TEST', Job_Number_Claim__c='1012-19-20XX', AccountId=accByTempIdMap.get('TEST Brookdale Senior Living, Inc. TEST TEST').Id,
            Status='In Progress', Lead_Source__c='Advertising', Callers_Name__c='Bob Jones', Property_Name__c='Brookdale Temple',
            Estimated_Completion_Date__c=Date.newInstance(2020,02,02), 
            Original_Contract_Amount__c=23760, 
            Date_of_Call__c=Date.newInstance(2020,01,13), Date_of_Loss__c=Date.newInstance(2020,01,130), Street='1610 E Guadalupe Rd.', City='Tempe', StateCode='AZ', PostalCode='85283', CountryCode='US',
            Status_Note__c='test', OwnerId=ownerId,
            Onsite_Contact_Phone__c='800-382-9473', Onsite_Contact_Email__c='test@test.com',Vertical__c = 'Hospitality' , Subvertical__c = 'Airlines',
            Site_Walk_Complete_Date__c=Date.today(), Estimate_Sent_Date__c=Date.today(), Data_Admin_Reason__c='Bypass Validation Errors' ));
        jobByJobNumberMap.put('2008-19-22XX', new WorkOrder(Job_Name__c='Brookdale Trillium Crossing TEST TEST', Job_Number_Claim__c='2008-19-22XX', AccountId=accByTempIdMap.get('TEST Brookdale Senior Living, Inc. TEST TEST').Id,
            Status='In Progress', Lead_Source__c='Advertising', Callers_Name__c='Crystal Smith', Property_Name__c='Brookdale Trillium Crossing',
            BD_Account_Manager__c='0051U0000062vTaQAI', Project_Director__c='0051U0000062vTaQAI',  
            Original_Contract_Amount__c=165750, Month_to_Date_Costs__c=49632.86, Last_Month_Cost__c=145496.64, 
            Date_of_Call__c=Date.newInstance(2019,12,13), Date_of_Loss__c=Date.newInstance(2019,12,13), Street='Unit 409 \r\n3500 Trillium Crossing Blvd', City='Columbus', StateCode='OH', PostalCode='43235', CountryCode='US',
            Description='Brookdale Trillium Crossing',
            Status_Note__c='test', OwnerId=ownerId,
            Onsite_Contact_Phone__c='800-382-9473', Onsite_Contact_Email__c='test@test.com',Vertical__c = 'Hospitality' , Subvertical__c = 'Airlines',
            Site_Walk_Complete_Date__c=Date.today(), Estimate_Sent_Date__c=Date.today(), Data_Admin_Reason__c='Bypass Validation Errors' ));
        jobByJobNumberMap.put('2026-19-21XX', new WorkOrder(Job_Name__c='Cinemark Corporate Office TEST TEST', Job_Number_Claim__c='2026-19-21XX', AccountId=accByTempIdMap.get('TEST Cinemark USA TEST TEST').Id, 
            Status='In Progress', Lead_Source__c='Advertising', Callers_Name__c='Aidan Parker', Property_Name__c='Cinemark Corporate Office',
            BD_Account_Manager__c='0051U0000062Df6QAE', Project_Director__c='0051U0000062Df6QAE',
            Estimated_Completion_Date__c=Date.newInstance(2019,12,15), 
            Original_Contract_Amount__c=1132.37,  Month_to_Date_Costs__c=-247.53, Last_Month_Cost__c=1132.37, Next_Month_Cost__c=0, 
            Date_of_Call__c=Date.newInstance(2019, 12, 11), Date_of_Loss__c=Date.newInstance(2019,12,11), Street='3900 Dallas Parkway, Suite 500', City='Plano', StateCode='TX', PostalCode='75093', CountryCode='US',
            Description='Cinemark Corporate Office',
            Status_Note__c='test', OwnerId=ownerId,
            Onsite_Contact_Phone__c='800-382-9473', Onsite_Contact_Email__c='test@test.com',Vertical__c = 'Hospitality' , Subvertical__c = 'Airlines',
            Site_Walk_Complete_Date__c=Date.today(), Estimate_Sent_Date__c=Date.today(), Data_Admin_Reason__c='Bypass Validation Errors' ));
        jobByJobNumberMap.put('2005-19-21XX', new WorkOrder(Job_Name__c='Cinemark-Downey TEST TEST', Job_Number_Claim__c='2005-19-21XX', AccountId=accByTempIdMap.get('TEST Cinemark USA TEST TEST').Id, 
            Status='In Progress', Lead_Source__c='Advertising', Callers_Name__c='Joseph Jiles', Property_Name__c='Cinemark Downey',
            BD_Account_Manager__c='0051U0000062Df6QAE', Project_Director__c='0051U0000062Df6QAE',
            Estimated_Completion_Date__c=Date.newInstance(2019,12,09), 
            Original_Contract_Amount__c=3099.19,  Month_to_Date_Costs__c=-49.35, Last_Month_Cost__c=1340.48, Next_Month_Cost__c=0, 
            Date_of_Call__c=Date.newInstance(2019,12,06), Date_of_Loss__c=Date.newInstance(2019, 12, 06), Street='8840 Apollo Way', City='Downey', StateCode='CA', PostalCode='90242', CountryCode='US',
            Description='Cinemark-Downey',
            Sage_Account_Name__c='CINE01', Status_Note__c='test', OwnerId=ownerId,
            Onsite_Contact_Phone__c='800-382-9473', Onsite_Contact_Email__c='test@test.com',Vertical__c = 'Hospitality' , Subvertical__c = 'Airlines',
            Site_Walk_Complete_Date__c=Date.today(), Estimate_Sent_Date__c=Date.today(), Data_Admin_Reason__c='Bypass Validation Errors' ));
        jobByJobNumberMap.put('2004-19-97XX', new WorkOrder(Job_Name__c='Prologis-Marketplace East TEST TEST', Job_Number_Claim__c='2004-19-97XX', AccountId=accByTempIdMap.get('TEST Prologis, Inc. TEST TEST').Id, 
            Status='Closed', Lead_Source__c='Advertising', Callers_Name__c='Alma McGee', Property_Name__c='Prologis Marketplace East', 
            BD_Account_Manager__c='0051U000005oMv1QAE', Project_Director__c='0051U000005oMv1QAE',
            Estimated_Completion_Date__c=Date.newInstance(2019,09,03),
            Original_Contract_Amount__c=1376.27, Month_to_Date_Costs__c=0, Last_Month_Cost__c=0, Next_Month_Cost__c=0, 
            Date_of_Call__c=Date.newInstance(2019,08,23), Date_of_Loss__c=Date.newInstance(2019,08,23),  Street='15965 E 32nd Ave.', City='Aurora', StateCode='CO', PostalCode='80011', CountryCode='US',
            Description='Prologis-Marketplace East',
            Sage_Account_Name__c='PROL10', Status_Note__c='test', OwnerId=ownerId,
            Onsite_Contact_Phone__c='800-382-9473', Onsite_Contact_Email__c='test@test.com',Vertical__c = 'Hospitality' , Subvertical__c = 'Airlines',
            Site_Walk_Complete_Date__c=Date.today(), Estimate_Sent_Date__c=Date.today(), Data_Admin_Reason__c='Bypass Validation Errors' ));
        jobByJobNumberMap.put('2004-19-88XX', new WorkOrder(Job_Name__c='Prologis-Custom Tool TEST TEST', Job_Number_Claim__c='2004-19-88XX', AccountId=accByTempIdMap.get('TEST Prologis, Inc. TEST TEST').Id,
            Status='Closed', Lead_Source__c='Advertising', Callers_Name__c='Arian Maxwell', Property_Name__c='Prologis Custom Tool',
            BD_Account_Manager__c='0051U000005oMv1QAE', Project_Director__c='0051U000005oMv1QAE',
            Estimated_Completion_Date__c=Date.newInstance(2019,07,24),  
            Original_Contract_Amount__c=2112.79,  Month_to_Date_Costs__c=0, Last_Month_Cost__c=0, Next_Month_Cost__c=0, 
            Date_of_Call__c=Date.newInstance(2019,07,19), Date_of_Loss__c=Date.newInstance(2019,07,19), Street='14309 E 35th Pl.', City='Aurora', StateCode='CO', PostalCode='80011', CountryCode='US',
            Description='Prologis-Custom Tool',
            Sage_Account_Name__c='PROL10', Status_Note__c='test', OwnerId=ownerId,
            Onsite_Contact_Phone__c='800-382-9473', Onsite_Contact_Email__c='test@test.com',Vertical__c = 'Hospitality' , Subvertical__c = 'Airlines',
            Site_Walk_Complete_Date__c=Date.today(), Estimate_Sent_Date__c=Date.today(), Data_Admin_Reason__c='Bypass Validation Errors' ));
        jobByJobNumberMap.put('1008-21-35XX', new WorkOrder(Job_Name__c='Aimbridge Hospitality-Wyndham San Antonio Riverwalk_2021-03-22 TEST TEST', Job_Number_Claim__c='1008-21-35XX', AccountId=accByTempIdMap.get('TEST Aimbridge Hospitality TEST TEST').Id,
            Status='Work Complete',  Lead_Source__c='Repeat Client', Callers_Name__c='Kevin R. Latone', Property_Name__c='Aimbridge Hospitality-Wyndham San Antonio Riverwalk',
            BD_Account_Manager__c='0051U0000069rLx', Project_Director__c='0051U000006ALj6',
            Estimated_Completion_Date__c=Date.newInstance(2022,05,27),  
            Original_Contract_Amount__c=694543.26, Month_to_Date_Costs__c=-3350.75, Last_Month_Cost__c=4009.64, Next_Month_Cost__c=0, 
            Date_of_Call__c=Date.newInstance(2022,03,22), Date_of_Loss__c=Date.newInstance(2021,02,18), Street='111 East Pecan Street', City='San Antonio', StateCode='TX', PostalCode='78205', CountryCode='US',
            Description='Pipe breaks from Polar Storm in Texas',
            Sage_Account_Name__c=null, Status_Note__c='test', OwnerId=ownerId,
            Onsite_Contact_Phone__c='2103626430', Onsite_Contact_Email__c=null,Vertical__c = 'Hospitality' , Subvertical__c = 'Hotel/Motel',
            Site_Walk_Complete_Date__c=Date.newInstance(2022, 03, 22), Estimate_Sent_Date__c=Date.newInstance(2022, 03, 22), Data_Admin_Reason__c='Bypass Validation Errors' ));
        jobByJobNumberMap.put('1021-21-27XX', new WorkOrder(Job_Name__c='Aimbridge Hospitality - Embassy Suites_2021-02-26 TEST TEST', Job_Number_Claim__c='1021-21-27XX', AccountId=accByTempIdMap.get('TEST Aimbridge Hospitality TEST TEST').Id, 
            Status='Work Complete', Lead_Source__c='Repeat Client', Callers_Name__c='Austin Bucholtz', Property_Name__c='Aimbridge Hospitality - Embassy Suites',
            BD_Account_Manager__c='0051U0000069rLx', Project_Director__c='0051U000006ALj6',
            Estimated_Completion_Date__c=Date.newInstance(2021,05,07),  
            Original_Contract_Amount__c=70028.82, Month_to_Date_Costs__c=0, Last_Month_Cost__c=0, Next_Month_Cost__c=0, 
            Date_of_Call__c=Date.newInstance(2021,02,26), Date_of_Loss__c=Date.newInstance(2021,02,15), Street='3225 158th Avenue Southeast', City='Bellevue,', StateCode='WA', PostalCode='98008', CountryCode='US',
            Description='Pipe breaks from Polar Storm in Texas',
            Sage_Account_Name__c=null, Status_Note__c='test', OwnerId=ownerId,
            Onsite_Contact_Phone__c='262-719-71XX', Onsite_Contact_Email__c='wendy.floyd@aimhosp.com',Vertical__c = 'Hospitality' , Subvertical__c = 'Hotel/Motel',
            Site_Walk_Complete_Date__c=Date.newInstance(2021, 02, 26), Estimate_Sent_Date__c=Date.newInstance(2021, 02, 25),
            WorkTypeId=workTypeByNameMap.get('Construction').Id, Data_Admin_Reason__c='Bypass Validation Errors' ));
            return jobByJobNumberMap;
    }

    private static List<Invoice_Request_Form__c> createInvoiceRequestForms(Map<String, WorkOrder> jobByJobNumberMap, Map<String, ServiceTerritory> serviceTerritoryByNameMap, Map<String, WorkType> workTypeByNameMap) {
        List<Invoice_Request_Form__c> invoiceReqFormLst = new List<Invoice_Request_Form__c>();

        invoiceReqFormLst.add(new Invoice_Request_Form__c(Job_Claim_Number__c='1008-21-3559',	Request_Type__c='Invoice', Date_of_Request__c=Date.newInstance(2021, 04, 22),	BD_Account_Manager__c='0051U0000069rLx', Project_Director__c='0051U000006ALj6',
            Person_Requesting_Invoice__c='Rich Veldman', Number_of_Files__c=2,	
            Company__c=jobByJobNumberMap.get('1008-21-35XX').AccountId, Amount_to_be_Invoiced__c=468015.57, Billing_Address__c='5851 Legacy Circle Suite 400\rPlano, TX, 75024\rUnited States', Phone_Number__c='unknown', Customer_Tax_Exempt__c='No', Billing_Contact__c='Kevin Latone',
            AIA_Payment_Application_Required__c='No', Customer_Email__c='kevin.latone@sawyn.com', Provide_conditional_lien_release__c='Yes', Mail_Original_Invoice__c='No', Is_there_a_WO_PO__c='No',
            Description__c='Final invoice is for the temporary scope of the freeze claim totaling 751,843.08 minus the previous invoiced amount of 283,231.25.', Status__c='Submitted to Customer',
            Job__c=jobByJobNumberMap.get('1008-21-35XX').Id));
        invoiceReqFormLst.add(new Invoice_Request_Form__c(Job_Claim_Number__c='1008-21-3559',	Request_Type__c='Invoice', Date_of_Request__c=Date.newInstance(2021, 04, 19),	BD_Account_Manager__c='0051U0000069rLx', Project_Director__c='0051U000006ALj6',
            Person_Requesting_Invoice__c='Rich Veldman', Number_of_Files__c=4,	
            Company__c=jobByJobNumberMap.get('1008-21-35XX').AccountId, Amount_to_be_Invoiced__c=461899.12, Billing_Address__c='5851 Legacy Circle Suite 400\rPlano, TX, 75024\rUnited States', Phone_Number__c='unknown', Customer_Tax_Exempt__c='No', Billing_Contact__c='Kevin Latone',
            AIA_Payment_Application_Required__c='No', Customer_Email__c='kevin.latone@sawyn.com', Provide_conditional_lien_release__c='Yes', Mail_Original_Invoice__c='No', Is_there_a_WO_PO__c='No',
            Description__c='Invoice is for the temporary scope of the freeze claim totaling 748,130.37 minus the previous invoiced amount of 286,231.25.', Status__c='Incomplete',
            Job__c=jobByJobNumberMap.get('1008-21-35XX').Id));
        invoiceReqFormLst.add(new Invoice_Request_Form__c(Job_Claim_Number__c='1021-21-2739',	Request_Type__c='Invoice', Date_of_Request__c=Date.newInstance(2021, 04, 21),	BD_Account_Manager__c='0051U0000069rLx', Project_Director__c='0051U000006JYrR',
            Person_Requesting_Invoice__c='Aaron Morales', Number_of_Files__c=2,	
            Company__c=jobByJobNumberMap.get('1021-21-27XX').AccountId, Amount_to_be_Invoiced__c=35014.41, Billing_Address__c='5851 Legacy Circle Suite 400\rPlano, TX, 75024\rUnited States', Phone_Number__c='262-719-7110', Customer_Tax_Exempt__c='No', Billing_Contact__c='Wendy Floyd',
            AIA_Payment_Application_Required__c='No', Customer_Email__c='Wendy.floyd@aimhosp.com', Provide_conditional_lien_release__c='Yes', Mail_Original_Invoice__c='No', Is_there_a_WO_PO__c='No',
            Description__c='50% progress billing for work completed', Status__c='Submitted to Customer',
            Job__c=jobByJobNumberMap.get('1021-21-27XX').Id));
        invoiceReqFormLst.add(new Invoice_Request_Form__c(Job_Claim_Number__c='1021-21-2739',	Request_Type__c='Invoice', Date_of_Request__c=Date.newInstance(2021, 05, 05),	BD_Account_Manager__c='0051U0000069rLx', Project_Director__c='0051U000006JYrR',
            Person_Requesting_Invoice__c='Aaron Morales', Number_of_Files__c=2,	
            Company__c=jobByJobNumberMap.get('1021-21-27XX').AccountId, Amount_to_be_Invoiced__c=35014.41, Billing_Address__c='5851 Legacy Circle Suite 400\rPlano, TX, 75024\rUnited States', Phone_Number__c='262-719-7110', Customer_Tax_Exempt__c='No', Billing_Contact__c='Wendy Floyd',
            AIA_Payment_Application_Required__c='No', Customer_Email__c='Wendy.floyd@aimhosp.com', Provide_conditional_lien_release__c='Yes', Mail_Original_Invoice__c='No', Is_there_a_WO_PO__c='No',
            Description__c='Final Billing for water damage repairs in units 527, 528 & 427', Status__c='Submitted to Customer',
            Job__c=jobByJobNumberMap.get('1021-21-27XX').Id));
        return invoiceReqFormLst;
    }

    public static Map<String, Area_Wide_Event__c> createAreaWideEvents() {
        Map<String, Area_Wide_Event__c> aweByNameMap = new Map<String, Area_Wide_Event__c>();

        StaticResource aweCsvStaticResource = [SELECT Body from StaticResource WHERE Name = 'AreaWideEvents'];
        String aweCsv = aweCsvStaticResource.Body.toString();
        Integer rowNum = 0;
            
        for(String row : aweCsv.split('\n')) {
            if (rowNum > 0) {
                row = FileParserService.preProcessCSVLine(row);
                String[] column = row.split(',');
                Area_Wide_Event__c awe = new Area_Wide_Event__c(
                    Name = FileParserService.processCell(column[0]),
                    Active__c = FileParserService.processBoolean(column[1]),
                    End_Date__c = FileParserService.processDate(column[2]),
                    Start_Date__c = FileParserService.processDate(column[3]),
                    Mobilization_Number__c = FileParserService.processCell(column[4]),
                    Location_of_AWE__c= FileParserService.processCell(column[5])
                );  
                aweByNameMap.put(FileParserService.processCell(column[0]), awe);    
            }
            rowNum++;                                                                                                                        
        } 
        //insert aweByNameMap.values();
        return aweByNameMap;  
    }
/*
    @TestVisible
    private Sandbox_Configuration__mdt getSandboxConfiguration(String url) {
        List<String> sandboxNameLst = url.split('--', 2);
        String sandboxName='';
        Sandbox_Configuration__mdt thisConfig;
        Sandbox_Configuration__mdt theDefaultConfig;
        
        //field sandbox environment name
        if (sandboxNameLst.size()==2) {
            sandboxName = sandboxNameLst[1];
            sandboxNameLst.clear();
            sandboxNameLst=sandboxName.split('\\.',2);
            if (sandboxNameLst.size()> 1){
                sandboxName= sandboxNameLst[0].toLowerCase();
            }
        }

        //get sandbox configration settings
        for (Sandbox_Configuration__mdt config : [SELECT DeveloperName, BoltConnectedAppCallBackURL__c, BoltEndpointEnvironmentLabel__c, 
            BoltNamedCredentialPassword__c, BoltNamedCredentialURL__c, BoltNamedCredentialUser__c, BoltOrgDefaultIsIntegrationUser__c,
            BoltRemoteSiteSettingURL__c, BoltSyncUserIsIntegrationUser__c, BoltTeamUsersToCreateOrUpdate__c, Description__c, Order__c, 
            SandboxNameKeyWord__c, SandboxType__c FROM Sandbox_Configuration__mdt ORDER BY Order__c]) {
                String keyword = config.SandboxNameKeyWord__c.toLowerCase();

                if (sandboxName.contains(keyword)) {
                    thisConfig = config;
                    break;
                }

                if (config.DeveloperName == 'Default') {
                    theDefaultConfig = config;
                }
        }

        if (thisConfig == null) {
            thisConfig = theDefaultConfig;
        }

        return thisConfig;
    }
*/
}