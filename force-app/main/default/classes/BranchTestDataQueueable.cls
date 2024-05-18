/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-12-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class BranchTestDataQueueable implements Queueable {
    private Map<String, WorkType> workTypeByNameMap;
    private Map<String, ServiceTerritory> serviceTerritoryByNameMap;
    private Map<String, Area_Wide_Event__c> aweByNameMap;

    public BranchTestDataQueueable() {
        this.workTypeByNameMap = new Map<String, WorkType>();
        for (WorkType jobType : [SELECT Id, Name FROM WorkType]) {
            this.workTypeByNameMap.put(jobType.Name, jobType);            
        }
        this.serviceTerritoryByNameMap = new Map<String, ServiceTerritory>();
        for (ServiceTerritory st : [SELECT Id, Name FROM ServiceTerritory]) {
            this.serviceTerritoryByNameMap.put(st.Name, st);
        }
        this.aweByNameMap = new Map<String, Area_Wide_Event__c>();
        for (Area_Wide_Event__c awe : [SELECT Id, Name FROM Area_Wide_Event__c]){
            this.aweByNameMap.put(awe.Name, awe);
        }

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

    public void execute(QueueableContext context) {
        Map<String, Account> parentAccountByNameMap = createParentAccounts();
        Map<String, Account> accountByNameMap = createAccounts(parentAccountByNameMap);
        Map<String, Account> propertyByNameMap = createProperties(accountByNameMap);
        Map<String, WorkOrder> jobByNameMap = createJobs(parentAccountByNameMap, accountByNameMap, propertyByNameMap);
 //Map<String, Contract> contractByNameMap =  createContracts(accountByNameMap, accountByNameMap, jobByNameMap);
        /*for (WorkOrder job : jobByNameMap.values()){
            System.debug('~~~~ job ' + job);
        }*/

    }

    private Map<String, Account> createParentAccounts() {
        Map<String, Account> parentAccountByNameMap = new Map<String, Account>();

        StaticResource parentAccountCsvStaticResource = [SELECT Body from StaticResource WHERE Name = 'ParentAccounts'];
        String parentAccountCsv = parentAccountCsvStaticResource.Body.toString();
        Set<Id> activeUsers = new Set<Id>();
        Set<Id> fileUsers = new Set<Id>();
        Integer rowNum = 0;
            
        for(String row : parentAccountCsv.split('\n')) {
            if (rowNum > 0) {
                row = FileParserService.preProcessCSVLine(row);
                String[] column = row.split(',');
                Account parentAcc = new Account(
                    Name = FileParserService.processCell(column[0]),
                    RecordTypeId = FileParserService.processCell(column[1]),
                    Status__c = FileParserService.processCell(column[2]),
                    Phone = FileParserService.processCell(column[3]),
                    Vertical__c = FileParserService.processCell(column[4]),
                    Subvertical__c= FileParserService.processCell(column[5]),
                    AccountSource = FileParserService.processCell(column[6]),
                    Email__c=FileParserService.processCell(column[7]),
                    Tier__c=FileParserService.processCell(column[8]),
                    //Child_of_National__c=FileParserService.processCell(column[10]),
                    Drive_Down__c=FileParserService.processCell(column[9]),
                    Contract_Type__c=FileParserService.processCell(column[10]), 
                    Number_of_Active_Contracts__c=FileParserService.processInteger(column[11]),                     
                    BillingStreet=FileParserService.processCell(column[12]),
                    BillingCity=FileParserService.processCell(column[13]),
                    National_Account__c=FileParserService.processCell(column[14]),  
                    BillingStateCode=FileParserService.processCell(column[15]),                  
                    Drive_Down_Plan_in_Place__c=FileParserService.processCell(column[16]),
                    //Child_of_National__c=FileParserService.processCell(column[17]),
                    BillingPostalCode=FileParserService.processCell(column[18]),
                    BillingCountryCode=FileParserService.processCell(column[19]),
                    OwnerId=FileParserService.processBoolean(column[22])==true ? FileParserService.processCell(column[20]) : UserInfo.getUserId(),
                    Data_Admin_Reason__c='Bypass Validation Errors' 
                );  
                parentAccountByNameMap.put(column[0], parentAcc);  
                fileUsers.add(parentAcc.OwnerId);  
            }
            rowNum++;                                                                                                                        
        } 

        for (User activeUser : [SELECT Id FROM User WHERE Id IN: fileUsers AND isActive=true]) {
            activeUsers.add(activeUser.Id);
        }

        for (Account parentAccount : parentAccountByNameMap.values()) {
            if (!activeUsers.contains(parentAccount.OwnerId)) {
                parentAccount.OwnerId = UserInfo.getUserId();
            }
        }

        insert parentAccountByNameMap.values();
        return parentAccountByNameMap;  
    }

    private Map<String, Account> createAccounts(Map<String, Account> parentAccountByNameMap) {
        Map<String, Account> accountByNameMap = new Map<String, Account>();
        Set<Id> activeUsers = new Set<Id>();
        Set<Id> fileUsers = new Set<Id>();

        StaticResource accountCsvStaticResource = [SELECT Body from StaticResource WHERE Name = 'Accounts'];
        String accountCsv = accountCsvStaticResource.Body.toString();
        Integer rowNum = 0;
            
        for(String row : accountCsv.split('\n')) {
            if (rowNum > 0) {
                row = FileParserService.preProcessCSVLine(row);
                String[] column = row.split(',');
                String parentAccountName = FileParserService.processCell(column[21]);
                Account acc = new Account(
                    Name = FileParserService.processCell(column[0]),
                    RecordTypeId = FileParserService.processCell(column[1]),
                    Status__c = FileParserService.processCell(column[2]),
                    Phone = FileParserService.processCell(column[3]),
                    Vertical__c = FileParserService.processCell(column[4]),
                    Subvertical__c= FileParserService.processCell(column[5]),
                    AccountSource = FileParserService.processCell(column[6]),
                    Email__c=FileParserService.processCell(column[7]),
                    Tier__c=FileParserService.processCell(column[8]),
                    National_Account__c=FileParserService.processCell(column[9]),
                    Drive_Down__c=FileParserService.processCell(column[11]), 
                    Drive_Down_Plan_in_Place__c=FileParserService.processCell(column[12]),
                    Contract_Type__c=FileParserService.processCell(column[13]),  
                    Number_of_Active_Contracts__c=FileParserService.processInteger(column[14]),
                    BillingStreet=FileParserService.processCell(column[15]),
                    BillingCity=FileParserService.processCell(column[16]),
                    BillingStateCode=FileParserService.processCell(column[17]),
                    BillingPostalCode=FileParserService.processCell(column[18]),
                    BillingCountryCode=FileParserService.processCell(column[19]),
                    ParentId=parentAccountByNameMap.containsKey(parentAccountName) ? parentAccountByNameMap.get(parentAccountName).Id : null,
                    Bill_To__c=FileParserService.processCell(column[22]),
                    Protocols_ACM_Testing__c=FileParserService.processCell(column[23]),
                    Protocols_Billing__c=FileParserService.processCell(column[24]),
                    Protocols_Adjusters__c=FileParserService.processCell(column[25]),
                    Protocols_Broker__c=FileParserService.processCell(column[26]),
                    Protocols_DFRs__c=FileParserService.processCell(column[27]),
                    Protocols_Portal__c=FileParserService.processCell(column[28]),
                    Protocols_Pricing__c=FileParserService.processCell(column[29]),
                    Protocols_Special_Concerns__c=FileParserService.processCell(column[30]),
                    Protocols_Work_Auth_PO__c=FileParserService.processCell(column[31]),
                    //Overwrite_Child_Protocols__c=FileParserService.processCell(column[32]),
                    Tax_Exempt__c=FileParserService.processBoolean(column[33]),
                    Billing_Contact__c=FileParserService.processCell(column[34]),
                    Billing_Phone__c=FileParserService.processCell(column[35]),
                    Billing_Email__c=FileParserService.processCell(column[36]),
                    CurrencyIsoCode=FileParserService.processCell(column[37]),
                    OwnerId=FileParserService.processBoolean(column[38])==true ? FileParserService.processCell(column[20]) : UserInfo.getUserId(),
                    Data_Admin_Reason__c='Bypass Validation Errors' 
                );  
                fileUsers.add(acc.OwnerId);
                accountByNameMap.put(column[0], acc);    
            }
            rowNum++;                                                                                                                        
        } 

        for (User activeUser : [SELECT Id FROM User WHERE Id IN: fileUsers AND isActive=true]) {
            activeUsers.add(activeUser.Id);
        }

        for (Account acc : accountByNameMap.values()) {
            if (!activeUsers.contains(acc.OwnerId)) {
                acc.OwnerId = UserInfo.getUserId();
            }
        }
         
        insert accountByNameMap.values();
        return accountByNameMap;  
    }   

    private Map<String, Account> createProperties(Map<String, Account> accountByNameMap) {
        Map<String, Account> propertyByNameMap = new Map<String, Account>();
        Set<Id> activeUsers = new Set<Id>();
        Set<Id> fileUsers = new Set<Id>();

        StaticResource propertiesCsvStaticResource = [SELECT Body from StaticResource WHERE Name = 'Properties'];
        String propertyCsv = propertiesCsvStaticResource.Body.toString();
        Integer rowNum = 0;
            
        for(String row : propertyCsv.split('\n')) {
            if (rowNum > 0) {
                row = FileParserService.preProcessCSVLine(row);
                String[] column = row.split(',');
                String accountName = FileParserService.processCell(column[21]);
                String accId = accountByNameMap.containsKey(accountName) ? accountByNameMap.get(accountName).Id : null;
                if (!String.isBlank(accId)) {
                    System.debug('~~~~ Parent Account: ' + accountByNameMap.get(accountName));
                    Account property = new Account();
                    property.Name = FileParserService.processCell(column[0]);
                    property.RecordTypeId = FileParserService.processCell(column[1]);
                    property.Phone = FileParserService.processCell(column[3]);
                    property.BillingStreet=FileParserService.processCell(column[15]);
                    property.BillingCity=FileParserService.processCell(column[16]);
                    property.BillingStateCode=FileParserService.processCell(column[17]);
                    property.BillingPostalCode=FileParserService.processCell(column[18]);
                    property.BillingCountryCode=FileParserService.processCell(column[19]);
                    property.ParentId=accId;
                    property.Protocols_ACM_Testing__c=FileParserService.processCell(column[23]);
                    property.Protocols_Billing__c=FileParserService.processCell(column[24]);
                    property.Protocols_Adjusters__c=FileParserService.processCell(column[25]);
                    property.Protocols_Broker__c=FileParserService.processCell(column[26]);
                    property.Protocols_DFRs__c=FileParserService.processCell(column[27]);
                    property.Protocols_Portal__c=FileParserService.processCell(column[28]);
                    property.Protocols_Pricing__c=FileParserService.processCell(column[29]);
                    property.Protocols_Special_Concerns__c=FileParserService.processCell(column[30]);
                    property.Protocols_Work_Auth_PO__c=FileParserService.processCell(column[31]);
                    property.Tax_Exempt__c=FileParserService.processBoolean(column[33]);
                    property.Billing_Contact__c=FileParserService.processCell(column[34]);
                    property.Billing_Phone__c=FileParserService.processCell(column[35]);
                    property.Billing_Email__c=FileParserService.processCell(column[36]);
                    property.CurrencyIsoCode=FileParserService.processCell(column[37]);
                    property.ShippingStreet=FileParserService.processCell(column[38]);
                    property.ShippingCity=FileParserService.processCell(column[39]);
                    property.ShippingStateCode=FileParserService.processCell(column[40]);
                    property.ShippingCountryCode=FileParserService.processCell(column[41]);
                    property.ShippingPostalCode=FileParserService.processCell(column[42]);
                    property.Active__c=FileParserService.processBoolean(column[43]);
                    property.OwnerId=FileParserService.processBoolean(column[45]) ? FileParserService.processCell(column[20]) : UserInfo.getUserId();
                    property.Data_Admin_Reason__c='Bypass Validation Errors';
                    fileUsers.add(property.OwnerId);
                    propertyByNameMap.put(column[0], property);  
                    System.debug('~~~~ property: rowNum - ' + rowNum + '\n~~~~  Name - ' + property.Name + '\n~~~~ property: RecordTypeId - ' + property.RecordTypeId + '\n~~~~ property: ParentId - ' + property.ParentId + '\n~~~~ property: OwnerId - ' + property.OwnerId + '\n~~~~ property - ' + property); 
                } 
            }
            rowNum++;                                                                                                                        
        } 

        for (User activeUser : [SELECT Id FROM User WHERE Id IN: fileUsers AND isActive=true]) {
            activeUsers.add(activeUser.Id);
        }

        for (Account property : propertyByNameMap.values()) {
            if (!activeUsers.contains(property.OwnerId)) {
                property.OwnerId = UserInfo.getUserId();
            }
        }
        insert propertyByNameMap.values();
        System.debug('~~~~ BranchTestDataQueueable::createProperties: propertyByNameMap size - ' + propertyByNameMap.size());
        return propertyByNameMap;  
    }     

    private Map<String, WorkOrder> createJobs(Map<String, Account> accountByNameMap, Map<String, Account> parentAccountByNameMap, Map<String, Account> propertyByNameMap) {
        Map<String, WorkOrder> jobByNameMap = new Map<String, WorkOrder>();
        Set<Id> activeUsers = new Set<Id>();
        Set<Id> fileUsers = new Set<Id>();

        StaticResource jobCsvStaticResource = [SELECT Body from StaticResource WHERE Name = 'Jobs'];
        String jobCsv = jobCsvStaticResource.Body.toString();

        Integer rowNum = 0;
            
        for(String row : jobCsv.split('\n')) {
            if (rowNum > 0) {
                row = FileParserService.preProcessCSVLine(row);
                String[] column = row.split(',');

                String accountName = FileParserService.processCell(column[2]);
                String jobTypeName = FileParserService.processCell(column[15]);
                String branchName = FileParserService.processCell(column[17]);
                String aweName = FileParserService.processCell(column[18]);
                String propertyName = FileParserService.processCell(column[43]);
                Id pm = String.isNotBlank(FileParserService.processCell(column[6])) ? FileParserService.processCell(column[6]) : null;
                Id pd = String.isNotBlank(FileParserService.processCell(column[7])) ? FileParserService.processCell(column[7]) : null;
                Id bdam = String.isNotBlank(FileParserService.processCell(column[8])) ? FileParserService.processCell(column[8]) : null;
                Id bdam2 = String.isNotBlank(FileParserService.processCell(column[9])) ? FileParserService.processCell(column[9]) : null;
                Id bdam3 = String.isNotBlank(FileParserService.processCell(column[10])) ? FileParserService.processCell(column[10]) : null;
                Id rmcmom = String.isNotBlank(FileParserService.processCell(column[11])) ? FileParserService.processCell(column[11]) : null;
                WorkOrder jobRec = new WorkOrder(
                    AccountId = accountByNameMap.containsKey(accountName) ? accountByNameMap.get(accountName).Id : (parentAccountByNameMap.containsKey(accountName) ? parentAccountByNameMap.get(accountName).Id : null),
                    Job_Number_Claim__c = FileParserService.processCell(column[3]),
                    Project_Manager__c= pm,
                    Project_Director__c = pd,
                    BD_Account_Manager__c=bdam,
                    BD_Account_Manager_2__c=bdam2,
                    BD_Account_Manager_3__c=bdam3,
                    RM_CM_OM__c=rmcmom,
                    ROM_Contracted_Sales__c=FileParserService.processDecimal(column[13]),
                    Status=FileParserService.processCell(column[4]),
                    Job_Name__c=FileParserService.processCell(column[0]),
                    WorkTypeId=workTypeByNameMap.containsKey(jobTypeName) ? workTypeByNameMap.get(jobTypeName).Id : null,
                    Work_Type__c=FileParserService.processCell(column[16]),
                    ServiceTerritoryId=serviceTerritoryByNameMap.containsKey(branchName) ? serviceTerritoryByNameMap.get(branchName).Id : null,
                    Area_Wide_Event__c=aweByNameMap.containsKey(aweName) ? aweByNameMap.get(aweName).Id : null,
                    Vertical__c=FileParserService.processCell(column[19]),
                    Subvertical__c=FileParserService.processCell(column[20]),
                    //Start_Date__c=FileParserService.processDate(column[21]),
                    Substantial_Work_Completion_Date__c=FileParserService.processDate(column[22]),
                    //Work_Complete_Date__c=FileParserService.processDate(column[23]),
                    Billing_Contact_Phone__c=FileParserService.processCell(column[24]),
                    Billing_Contact_Email__c=FileParserService.processCell(column[25]),
                    Bill_To__c=FileParserService.processCell(column[26]),
                    Property__c=!String.isBlank(propertyName) && propertyByNameMap.containsKey(propertyName) ? propertyByNameMap.get(propertyName).Id : null,
                    Billing_City__c=FileParserService.processCell(column[30]),
                    Billing_State__c=FileParserService.processCell(column[31]),
                    Billing_Zip_Postal_Code__c=FileParserService.processCell(column[32]),
                    Billing_Street__c=FileParserService.processCell(column[33]),
                    Billing_Country__c=FileParserService.processCell(column[34]),
                    //Close_Date__c=FileParserService.processDate(column[44]),
                    Insurance_Policy_Number__c=FileParserService.processCell(column[45]),
                    OwnerId=FileParserService.processBoolean(column[42])==true ? FileParserService.processCell(column[46]) : UserInfo.getUserId(),
                    Data_Admin_Reason__c='Bypass Validation Errors' 
                );

                fileUsers.add(jobRec.OwnerId);
                jobByNameMap.put(jobRec.Job_Name__c, jobRec);    
                System.debug('~~~~ job: rowNum: ' + rowNum + '\n~~~~ jobRec - ' + jobRec + '\n~~~~ jobRec.Job_Name__c - ' + jobRec.Job_Name__c);                                                                                                                      
            }
            rowNum++;  
        } 
        System.debug('~~~~ BranchTestDAtaQueueable::createJobs: jobByNameMap.size()-'+jobByNameMap.size());

        for (User activeUser : [SELECT Id FROM User WHERE Id IN: fileUsers AND isActive=true]) {
            activeUsers.add(activeUser.Id);
        }

        for (WorkOrder job : jobByNameMap.values()) {
            if (!activeUsers.contains(job.OwnerId)) {
                job.OwnerId = UserInfo.getUserId();
            }
        }
        insert jobByNameMap.values();
        return jobByNameMap;  
    }
      
/*
    private Map<String, Contract> createContracts(Map<String, Account> accountByNameMap, Map<String, Account> parentAccountByNameMap, Map<String, WorkOrder> jobByNameMap) {
        Map<String, Contract> contractByNameMap = new Map<String, Contract>();

        StaticResource contractCsvStaticResource = [SELECT Body from StaticResource WHERE Name = 'Contracts'];
        String contractCsv = contractCsvStaticResource.Body.toString();
        Integer rowNum = 0;
            
        for(String row : contractCsv.split('\n')) {
            if (rowNum > 0) {
                row = FileParserService.preProcessCSVLine(row);
                String[] column = row.split(',');
                
                String accountName = FileParserService.processCell(column[14]);
                
                Contract contractRec = new Contract(
                    Name = FileParserService.processCell(column[1]),
                    Status = FileParserService.processCell(column[2]),
                    Job__c = jobByNameMap.get(FileParserService.processCell(column[4])).Id,
                    Canceled__c= FileParserService.processBoolean(column[5]),
                    Client_Contract_Type__c = FileParserService.processCell(column[6]),
                    CurrencyISOCode=FileParserService.processCell(column[7]),
                    Contract_Changes__c=FileParserService.processCell(column[8]),
                    Date_of_Walk_Thru__c=FileParserService.processDate(column[9]),
                    Reviewed_Work__c=FileParserService.processBoolean(column[10]),
                    All_Completed_to_Satisfaction__c=FileParserService.processBoolean(column[11]),
                    Items_That_Require_Correction__c=FileParserService.processCell(column[12]),
                    RecordTypeId=FileParserService.processCell(column[13]),
                    AccountId=accountByNameMap.containsKey(accountName) ? accountByNameMap.get(accountName).Id : parentAccountByNameMap.get(accountName).Id
                );  
                contractByNameMap.put(column[0], contractRec);    
            }
            rowNum++;                                                                                                                        
        } 
        insert contractByNameMap.values();
        return contractByNameMap;  
    }  
*/  
}