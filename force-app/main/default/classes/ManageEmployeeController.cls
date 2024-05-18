public with sharing class ManageEmployeeController {
    /*
    * Description: This method get the filtered record and get the field API names from the custom metadata record.
    * @param: String jobCommissionId
    * ReturnType: DataTableResponse wrapper class
    */
    @AuraEnabled(cacheable=true)
    public static DataTableResponse getEmployeeCommission(String jobCommissionId){
        DataTableResponse finalWrapper = new DataTableResponse();
        try {
            List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
            List<SObject> lstDataTableData = new List<SObject>();
            List<String> columnList = new List<String>();
            List<String> fieldAPINameList = new List<String>();

            Dynamic_Table_DataTable__mdt tableComponentMetadata = [SELECT Id, DeveloperName, Field_Value__c, Header_Value__c, Query__c, Where_Condition__c FROM Dynamic_Table_DataTable__mdt WHERE DeveloperName = 'EmployeeCommission_List'];

            if(tableComponentMetadata.Header_Value__c != null) {
                columnList = tableComponentMetadata.Header_Value__c.split(',');
            }

            if(tableComponentMetadata.Field_Value__c != null) {
                fieldAPINameList = tableComponentMetadata.Field_Value__c.split(',');
            }

            for(integer i = 0; i < columnList.size(); i++) {
                DataTableColumns datacolumns = new DataTableColumns( columnList[i].trim() , 
                                                                    fieldAPINameList[i].substringBefore(':').trim(), 
                                                                    fieldAPINameList[i].substringBetween(':',':').trim(),
                                                                    Boolean.valueOf(fieldAPINameList[i].substringAfterLast(':').trim()));
                lstDataColumns.add(datacolumns);
            }
            
            String query = tableComponentMetadata.Query__c;
            String whereCondition = 'Job_Commission__c = \'' + jobCommissionId + '\'';
            if(String.isNotBlank(tableComponentMetadata.Where_Condition__c)) {
                if(String.isNotBlank(whereCondition)) {
                    whereCondition += ' AND ' + tableComponentMetadata.Where_Condition__c;
                } else {
                    whereCondition = tableComponentMetadata.Where_Condition__c;
                }
            }
            if(String.isNotBlank(whereCondition)) {
                query += ' WHERE ' + whereCondition;
            }
            
            for(SObject SObjectItem : Database.query(query)) {
                lstDataTableData.add(SObjectItem);
            }
            
            finalWrapper.lstDataTableColumns = lstDataColumns;
            finalWrapper.lstDataTableData = lstDataTableData;
            
        } catch(Exception ex) {
            //TODO: Handle exception here via the framework
            System.debug('Exception ::' + ex.getMessage() + '=====' + ex.getStackTraceString());
        }
        return finalWrapper;
    }
    
    /*
    * Description: This method get the filtered record and get the field API names from the custom metadata record.
    * @param: String jobCommissionId
    * ReturnType: DataTableResponse wrapper class
    */
    @AuraEnabled(cacheable=true)
    public static DataTableResponse getConfirmationScreenRecords(String jobCommissionId, String dataTableResponseWrapStr, String finalSObjectDataStr){
        DataTableResponse finalWrapper = new DataTableResponse();
        Map<String, Object> dataTableResponseWrapMap = (Map<String, Object>) JSON.deserializeUntyped(dataTableResponseWrapStr);
        System.debug('finalSObjectDataStr:::'+finalSObjectDataStr);
        List<Object> finalSObjectDataStrList = (List<Object>) JSON.deserializeUntyped(finalSObjectDataStr);
        Decimal actualCommissionAmount = 0.0000;
        Decimal splitMultiplier = 0.0000;
        Double actualCommissionableSwitch = 0.00;
        try {
            List<Job_Commission__c> jobCommissionList = [SELECT Id, Split_Multiplier__c, 
                                                         Actual_Total_Commission_Payment_Amount__c, 
                                                         Actual_Commissionable__c, Job_Amount__c, 
                                                         Actual_Quick_Collection_Incentive__c, 
                                                         Actual_Slow_Collection_Incentive__c, 
                                                         Actual_Deposit_1st_Payment_Incentive__c, 
                                                         Margin_Tier__c, Max_Split_Percentage__c, 
                                                         Max_Number_of_Employee_Commissions__c, 
                                                         Min_Number_of_Employee_Commissions__c, 
                                                         Added_Employee_Commissions__c, Removed_Employee_Commissions__c, 
                                                         Custom_Splits__c, Number_of_Commissionable_Employees__c,
                                                         Actual_Commissionable_Switch__c  
                                                         FROM Job_Commission__c WHERE Id =: jobCommissionId];
            if(!jobCommissionList.isEmpty()) {
                Job_Commission__c jobCommissionRec = jobCommissionList[0];
                if(jobCommissionRec.Actual_Commissionable__c == 'Yes') {
                    actualCommissionAmount = (jobCommissionRec.Job_Amount__c * (jobCommissionRec.Actual_Quick_Collection_Incentive__c + jobCommissionRec.Actual_Slow_Collection_Incentive__c + jobCommissionRec.Actual_Deposit_1st_Payment_Incentive__c)) / 100;
                } else {
                    actualCommissionAmount = 0.00;
                }
                jobCommissionList[0].Number_of_Commissionable_Employees__c = finalSObjectDataStrList.size();
                List<Job_Commission__c> jobCommissionSplitMulList = CommissionMultiplierConfigurationService.setMultiplierInfo(jobCommissionList);
                splitMultiplier = jobCommissionSplitMulList[0].Split_Multiplier__c;
                actualCommissionableSwitch = jobCommissionRec.Actual_Commissionable_Switch__c;
            }//End of if(!jobCommissionList.isEmpty())
            List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
            List<SObject> lstDataTableData = new List<SObject>();
            
            for ( Object obj : ( List< Object > )dataTableResponseWrapMap.get('lstDataTableColumns')) {
                DataTableColumns dataTableColumnObj = (DataTableColumns) JSON.deserialize(JSON.serialize(obj), DataTableColumns.class);
                dataTableColumnObj.editable = false;
                lstDataColumns.add(dataTableColumnObj);
            }
            
            DataTableColumns commissiondatacolumn = new DataTableColumns( 'ACTUAL COMMISSION AMOUNT' , 
                                                                    'Actual_Commission_Amount__c', 
                                                                    'currency',
                                                                    false);
            lstDataColumns.add(commissiondatacolumn);
            finalWrapper.lstDataTableColumns = lstDataColumns;
            for ( Object obj : finalSObjectDataStrList) {
                Map<String, Object> sObjectMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                
                Employee_Commission__c employeeCommObj = new Employee_Commission__c();
                employeeCommObj.Employee_Name__c = (String)sObjectMap.get('Employee_Name__c');
                employeeCommObj.Employee__c = (Id)sObjectMap.get('Employee__c');
                employeeCommObj.Status__c = (String)sObjectMap.get('Status__c');
                if(sObjectMap.containsKey('Commission_Payment_Date__c') && sObjectMap.get('Commission_Payment_Date__c') != '') employeeCommObj.Commission_Payment_Date__c = Date.valueOf((String)sObjectMap.get('Commission_Payment_Date__c'));
                else employeeCommObj.Commission_Payment_Date__c = null;
                String recId = (String)sObjectMap.get('Id');
                if(!recId.startsWith('005')) {
                    employeeCommObj.Id = (Id)sObjectMap.get('Id');
                }
                employeeCommObj.Name = (String)sObjectMap.get('Name');
                if(sObjectMap.get('Individual_Split_Percentage__c') instanceof String) {
                    String individualPer = (String)sObjectMap.get('Individual_Split_Percentage__c');
                    if(individualPer.contains('%')) individualPer = individualper.remove('%');
                    employeeCommObj.Individual_Split_Percentage__c = Decimal.valueOf(individualPer);
                } else if(sObjectMap.get('Individual_Split_Percentage__c') instanceof Integer) {
                	employeeCommObj.Individual_Split_Percentage__c = Decimal.valueOf((Integer)sObjectMap.get('Individual_Split_Percentage__c'));    
                } else if(sObjectMap.get('Individual_Split_Percentage__c') instanceof Decimal) {
                	employeeCommObj.Individual_Split_Percentage__c = (Decimal)sObjectMap.get('Individual_Split_Percentage__c');    
                }
                employeeCommObj.Actual_Commission_Amount__c = (employeeCommObj.Individual_Split_Percentage__c/100) * splitMultiplier * actualCommissionAmount;
				employeeCommObj.Exception_Reason__c = (String)sObjectMap.get('Exception_Reason__c');
                
                if(sObjectMap.get('Exception_Commission_Amount__c') instanceof String) {
                    employeeCommObj.Exception_Commission_Amount__c = Decimal.valueOf((String)sObjectMap.get('Exception_Commission_Amount__c'));
                } else if(sObjectMap.get('Exception_Commission_Amount__c') instanceof Integer) {
                	employeeCommObj.Exception_Commission_Amount__c = Decimal.valueOf((Integer)sObjectMap.get('Exception_Commission_Amount__c'));    
                } else if(sObjectMap.get('Exception_Commission_Amount__c') instanceof Decimal) {
                	employeeCommObj.Exception_Commission_Amount__c = (Decimal)sObjectMap.get('Exception_Commission_Amount__c');    
                }
                lstDataTableData.add(employeeCommObj);
            }
            finalWrapper.lstDataTableData = lstDataTableData;
            
        } catch(Exception ex) {
            //TODO: Handle exception here via the framework
            System.debug('Exception ::' + ex.getMessage() + '=====' + ex.getStackTraceString());
        }
        return finalWrapper;
    }
	
    /*
    * Description: This method will save the employee commission record.
    * @param: String jobCommissionId
    * @param: String exceptionReasonValue
    * @param: String finalSObjectDataStr
    * ReturnType: Boolean which states true if record is saved else false
    */
    @AuraEnabled
    public static String saveEmployeeCommissionRecord(String jobCommissionId, String exceptionReasonValue, String finalSObjectDataStr, String selectedUserIds, String deletedUserIds, Boolean customSplits, Boolean splitPercentageOverride) {
        Savepoint sp = Database.setsavepoint();
        String result = '';
        try {
            List<Object> finalSObjectDataStrList = (List<Object>) JSON.deserializeUntyped(finalSObjectDataStr);
            List<Object> selectedUserIdsList = (List<Object>) JSON.deserializeUntyped(selectedUserIds);
            List<Object> deletedUserIdsList = (List<Object>) JSON.deserializeUntyped(deletedUserIds);
            List<Employee_Commission__c> employeeCommissionList = new List<Employee_Commission__c>();
            List<String> deletedEmpCommissionIds = new List<String>();
            Set<String> userIdSet = new Set<String>();
            Map<String, User> userMap = new Map<String, User>();
            
            if(!deletedUserIdsList.isEmpty()) {
                for(Object obj : deletedUserIdsList) {
                    deletedEmpCommissionIds.add((String) obj);
                }
                System.debug('deletedEmpCommissionIds:::'+deletedEmpCommissionIds);
                delete [SELECT Id FROM Employee_Commission__c WHERE Id IN: deletedEmpCommissionIds];
            }
            
            List<Job_Commission__c> jobCommissionList = [SELECT Id, Job__c, Name, Split_Multiplier__c, 
                                                         Actual_Total_Commission_Payment_Amount__c, 
                                                         Actual_Commissionable__c, Job_Amount__c, 
                                                         Actual_Quick_Collection_Incentive__c, 
                                                         Actual_Slow_Collection_Incentive__c, 
                                                         Actual_Deposit_1st_Payment_Incentive__c, 
                                                         Margin_Tier__c, Max_Split_Percentage__c, 
                                                         Max_Number_of_Employee_Commissions__c, 
                                                         Min_Number_of_Employee_Commissions__c, 
                                                         Added_Employee_Commissions__c, Removed_Employee_Commissions__c, 
                                                         Custom_Splits__c, Number_of_Commissionable_Employees__c,
                                                         Actual_Commissionable_Switch__c   
                                                         FROM Job_Commission__c WHERE Id =: jobCommissionId];
            if(!jobCommissionList.isEmpty()) {
                Job_Commission__c jobCommissionRec = jobCommissionList[0];
                jobCommissionList[0].Number_of_Commissionable_Employees__c = finalSObjectDataStrList.size();
                Decimal actualCommissionAmount = 0.0000;
                if(jobCommissionRec.Actual_Commissionable__c == 'Yes') {
                    actualCommissionAmount = (jobCommissionRec.Job_Amount__c * (jobCommissionRec.Actual_Quick_Collection_Incentive__c + jobCommissionRec.Actual_Slow_Collection_Incentive__c + jobCommissionRec.Actual_Deposit_1st_Payment_Incentive__c)) / 100;
                } else {
                    actualCommissionAmount = 0.0000;
                }
                List<Job_Commission__c> jobCommissionSplitMulList = CommissionMultiplierConfigurationService.setMultiplierInfo(jobCommissionList);
                Decimal splitMultiplier = jobCommissionSplitMulList[0].Split_Multiplier__c;
                System.debug('Save splitMultiplier:::'+splitMultiplier);
                Double actualCommissionableSwitch = jobCommissionRec.Actual_Commissionable_Switch__c;
                jobCommissionSplitMulList[0].Exception_Reason__c = exceptionReasonValue;
                if(!selectedUserIdsList.isEmpty()) jobCommissionSplitMulList[0].Added_Employee_Commissions__c = 'Yes';
                else jobCommissionSplitMulList[0].Added_Employee_Commissions__c = 'No';
                if(!deletedUserIdsList.isEmpty()) jobCommissionSplitMulList[0].Removed_Employee_Commissions__c = 'Yes';
                else jobCommissionSplitMulList[0].Removed_Employee_Commissions__c = 'No';
                if(customSplits) jobCommissionSplitMulList[0].Custom_Splits__c = 'Yes';
                else jobCommissionSplitMulList[0].Custom_Splits__c = 'No';
                
                for ( Object obj : finalSObjectDataStrList) {
                    Map<String, Object> sObjectMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                    String recId = (String)sObjectMap.get('Id');
                    String empId = (String)sObjectMap.get('Employee__c');
                    if(recId.startsWith('005')) {
                        userIdSet.add(recId);
                    } else {
                        userIdSet.add(empId);
                    }
                }
                
                if(userIdSet.size() > 0) {
                    userMap = new Map<String, User>([SELECT Id, ADP_Associate_OID__c FROM User WHERE Id IN: userIdSet]);
                }
                
                for ( Object obj : finalSObjectDataStrList) {
                    Map<String, Object> sObjectMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                    Employee_Commission__c employeeCommObj = new Employee_Commission__c();
                    employeeCommObj.Job_Commission__c = jobCommissionId;
                    if(splitPercentageOverride) employeeCommObj.Split_Percentage_Override__c = 'Yes';
                    else employeeCommObj.Split_Percentage_Override__c = 'No';
                    employeeCommObj.Job__c = jobCommissionRec.Job__c;
                    employeeCommObj.Employee_Name__c = (String)sObjectMap.get('Employee_Name__c');
                    employeeCommObj.Employee__c = (Id)sObjectMap.get('Employee__c');
                    if(sObjectMap.get('Individual_Split_Percentage__c') instanceof String) {
                        String individualPer = (String)sObjectMap.get('Individual_Split_Percentage__c');
                        if(individualPer.contains('%')) individualPer = individualper.remove('%');
                        employeeCommObj.Individual_Split_Percentage__c = Decimal.valueOf(individualPer);
                    } else if(sObjectMap.get('Individual_Split_Percentage__c') instanceof Integer) {
                        employeeCommObj.Individual_Split_Percentage__c = Decimal.valueOf((Integer)sObjectMap.get('Individual_Split_Percentage__c'));    
                    } else if(sObjectMap.get('Individual_Split_Percentage__c') instanceof Decimal) {
                        employeeCommObj.Individual_Split_Percentage__c = (Decimal)sObjectMap.get('Individual_Split_Percentage__c');    
                    }
                    
                    if(sObjectMap.get('Exception_Commission_Amount__c') instanceof String) {
                        employeeCommObj.Exception_Commission_Amount__c = Decimal.valueOf((String)sObjectMap.get('Exception_Commission_Amount__c'));
                    } else if(sObjectMap.get('Exception_Commission_Amount__c') instanceof Integer) {
                        employeeCommObj.Exception_Commission_Amount__c = Decimal.valueOf((Integer)sObjectMap.get('Exception_Commission_Amount__c'));    
                    } else if(sObjectMap.get('Exception_Commission_Amount__c') instanceof Decimal) {
                        employeeCommObj.Exception_Commission_Amount__c = (Decimal)sObjectMap.get('Exception_Commission_Amount__c');    
                    }
                    System.debug('(String)sObjectMap.get(\'Exception_Reason__c\')::'+(String)sObjectMap.get('Exception_Reason__c'));
                    employeeCommObj.Exception_Reason__c = (String)sObjectMap.get('Exception_Reason__c');
                    System.debug('employeeCommObj.Exception_Reason__c::::'+employeeCommObj.Exception_Reason__c);
                    employeeCommObj.Actual_Commission_Amount__c = (employeeCommObj.Individual_Split_Percentage__c/100) * splitMultiplier * actualCommissionAmount;
					                    
                    String recId = (String)sObjectMap.get('Id');
                    if(!recId.startsWith('005')) {
                        employeeCommObj.Id = (Id)sObjectMap.get('Id');
                        employeeCommObj.Employee_Commission_ID__c = jobCommissionRec.Name + '-' + userMap.get(employeeCommObj.Employee__c).ADP_Associate_OID__c;
                    } else {
                        employeeCommObj.Employee_Commission_ID__c = jobCommissionRec.Name + '-' + userMap.get(recId).ADP_Associate_OID__c;
                    }
                    
                    employeeCommissionList.add(employeeCommObj);
                }
                update jobCommissionSplitMulList;
                if(!employeeCommissionList.isEmpty()) upsert employeeCommissionList;
                result = 'success';
            }//End of if(!jobCommissionList.isEmpty())
            return result;
        } catch(Exception ex) {
            System.debug('Exception :::'+ex.getMessage() + '====' + ex.getStackTraceString());
            Database.rollback(sp);
            return ex.getMessage();
        }
    }
    /*
    * Description: This is wrapper class to store the datatable columns details.
    * CreatedDate: 19-Jan-2024
    * Modified By: 
    */
    public class DataTableColumns {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled       
        public String fieldName {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public Boolean editable {get;set;}

        //Constructor
        public DataTableColumns(String label, String fieldName, String type, Boolean editable)
        {
            this.label     = label;
            this.fieldName = fieldName;
            this.type      = type;   
            this.editable   = editable;       
        }
    }

    @AuraEnabled
    public static List<ResultWrapper> fetchRecords(SearchWrapper inputWrapper) {
        try {
            if(inputWrapper != null){
                String fieldsToQuery = 'SELECT Id, ';
                if(string.isNotBlank(inputWrapper.fieldApiName)){
                    fieldsToQuery = fieldsToQuery + inputWrapper.fieldApiName;
                }
                if(string.isNotBlank(inputWrapper.otherFieldApiName)){
                    fieldsToQuery = fieldsToQuery + ', ' + inputWrapper.otherFieldApiName;
                }
                List<String> selectedUserList = new List<String>();
                if(String.isNotBlank(inputWrapper.selectedUserIds)) {
                    List<String> str = inputWrapper.selectedUserIds.split(',');
                    for(String strObj : str) {
                        if(strObj.contains('["')) {
                            strObj = strObj.removeStart('["');
                        }
                        if(strObj.contains('"]')) {
                            strObj = strObj.removeEnd('"]');
                        }
                        if(strObj.contains('"')) {
                            strObj = strObj.removeStart('"');
                        }
                        if(strObj.contains('"')) {
                            strObj = strObj.removeEnd('"');
                        }
                        selectedUserList.add(strObj);
                    }
                }
                String query = fieldsToQuery + ' FROM '+ inputWrapper.objectApiName;
                String filterCriteria = inputWrapper.fieldApiName + ' LIKE ' + '\'' + String.escapeSingleQuotes(inputWrapper.searchString.trim()) + '%\' '+  'AND Id NOT IN: selectedUserList LIMIT 10';
                if(String.isNotBlank(inputWrapper.selectedRecordId)) {
                    query += ' WHERE Id = \''+ inputWrapper.selectedRecordId + '\'';
                }else if(String.isNotBlank(inputWrapper.parentFieldApiName) && String.isNotBlank(inputWrapper.parentRecordId)){
                    query += ' WHERE '+ inputWrapper.parentFieldApiName+ ' = \''+ inputWrapper.parentRecordId + '\'';
                    query += ' AND ' + filterCriteria;
                } 
                else {
                    query += ' WHERE '+ filterCriteria;
                }
                List<ResultWrapper> returnWrapperList = new List<ResultWrapper>();
                for(SObject s : Database.query(query)) {
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.mainField = (String)s.get(inputWrapper.fieldApiName);
                    wrap.subField = (String)s.get(inputWrapper.otherFieldApiName);
                    wrap.id = (String)s.get('id');
                    returnWrapperList.add(wrap);
                }
                return returnWrapperList;
            }
            return null;
        } catch (Exception err) {
            System.debug('Error:'+err.getMessage() + '====' + err.getStackTraceString());
            throw new AuraHandledException(err.getMessage() + '====' + err.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static Job_Commission__c getJobCommission(String jobCommissionId) {
        Job_Commission__c jobCommissionObj = new Job_Commission__c();
        jobCommissionObj = [SELECT Id, Margin_Tier__c, Number_of_Commissionable_Employees__c, Max_Split_Percentage__c, Actual_Commissionable__c, Job_Amount__c, Split_Multiplier__c, 
                            Actual_Quick_Collection_Incentive__c, Actual_Slow_Collection_Incentive__c, Actual_Deposit_1st_Payment_Incentive__c 
                            FROM Job_Commission__c 
                            WHERE Id =: jobCommissionId];
        return jobCommissionObj;
    }//End of getJobCommission method

    @AuraEnabled(cacheable=true)
    public static Job_Commission__c calculateSplitMultiplier(String jobCommissionId, String finalSObjectDataStr) {
        Job_Commission__c jobCommissionObj = new Job_Commission__c();
        List<Object> finalSObjectDataStrList = (List<Object>) JSON.deserializeUntyped(finalSObjectDataStr);
        List<Job_Commission__c> jobCommissionList = [SELECT Id, Split_Multiplier__c, 
                                                         Actual_Total_Commission_Payment_Amount__c, 
                                                         Actual_Commissionable__c, Job_Amount__c, 
                                                         Actual_Quick_Collection_Incentive__c, 
                                                         Actual_Slow_Collection_Incentive__c, 
                                                         Actual_Deposit_1st_Payment_Incentive__c, 
                                                         Margin_Tier__c, Max_Split_Percentage__c, 
                                                         Max_Number_of_Employee_Commissions__c, 
                                                         Min_Number_of_Employee_Commissions__c, 
                                                         Added_Employee_Commissions__c, Removed_Employee_Commissions__c, 
                                                         Custom_Splits__c, Number_of_Commissionable_Employees__c,
                                                         Actual_Commissionable_Switch__c 
                                                         FROM Job_Commission__c WHERE Id =: jobCommissionId];
            
        Job_Commission__c jobCommissionRec = jobCommissionList[0];
        jobCommissionList[0].Number_of_Commissionable_Employees__c = finalSObjectDataStrList.size();
        List<Job_Commission__c> jobCommissionSplitMulList = CommissionMultiplierConfigurationService.setMultiplierInfo(jobCommissionList);
        return jobCommissionSplitMulList[0];
    }

    public class ResultWrapper{
        @AuraEnabled public String mainField{get;set;}
        @AuraEnabled public String subField{get;set;}
        @AuraEnabled public String id{get;set;}
    }

    public class SearchWrapper {
        @AuraEnabled public String objectApiName{get;set;}
        @AuraEnabled public String fieldApiName{get;set;}
        @AuraEnabled public String otherFieldApiName{get;set;}
        @AuraEnabled public String searchString{get;set;}
        @AuraEnabled public String selectedRecordId{get;set;}
        @AuraEnabled public String parentRecordId{get;set;}
        @AuraEnabled public String parentFieldApiName{get;set;}
        @AuraEnabled public String selectedUserIds{get;set;}
    }
    
    /*
    * Description: This is wrapper class to store the datatable columns details along with the data.
    * CreatedDate: 19-Jan-2024
    * Modified By: 
    */
    public class DataTableResponse {
        @AuraEnabled
        public List<DataTableColumns> lstDataTableColumns {get;set;}
        @AuraEnabled
        public List<sObject> lstDataTableData {get;set;}
    }
}