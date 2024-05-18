/**
 * @File Name          : TestFactoryDefaults.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 03-22-2024
 * @Modification Log   : 
 * Ver          Date            Author      		    Modification
 * 1.0          2/19/2020       dhoechst                https://github.com/dhoechst/Salesforce-Test-Factory
 * 2.0          2/20/2020       TJiles                      Added defaults for user
**/
@IsTest
public  class TestFactoryDefaults{

    // To specify defaults for objects, use the naming convention [ObjectName]Defaults.
    // For custom objects, omit the __c from the Object Name

    public class AccountDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Account.Name => 'Test Account',
                    Account.Status__c=>GeneralConstants.ACC_STATUS_NEEDS_ASSESSMENT, 
                    Account.Drive_Down__c=>'No',
                    Account.Drive_Down_Plan_in_Place__c=>'No',
                    Account.National_Account__c=>'Yes', 
                    Account.Number_of_Active_Contracts__c=>1,
                    Account.CurrencyIsoCode=>'USD',
                    Account.Legal_Name__c=>'Test Legal',
                    Account.Protocols_ACM_Testing__c=>'Test',
                    Account.Protocols_Adjusters__c=>'Test',
                    Account.Protocols_Billing__c=>'Test',
                    Account.Protocols_Broker__c=>'Test',
                    Account.Protocols_DFRs__c=>'Test',
                    Account.Protocols_Portal__c=>'Test',
                    Account.Protocols_Pricing__c=>'Test',
                    Account.Protocols_Special_Concerns__c=>'Test',
                    Account.Protocols_Work_Auth_PO__c=>'Test',
                    Account.Data_Admin_Reason__c=>'Bypass Validation Errors',
                    Account.RecordTypeId=>GeneralConstants.RT_ID_ACC_ACCOUNT,
                    Account.Vertical__c=>'Facility Management',
                    Account.Subvertical__c=>'Aviation',
                    Account.Contract_Type__c=>'CWA Only',
                    Account.Payment_Terms__c=>'Net 10', 
                    Account.MSA_Rate_Type__c=>'T&M',
                    Account.T_M_Year__c=>'Client-specific',
                    Account.Client_WO_PO_Required__c=>false,
                    Account.House_Account__c=>false
            };
        }
    }

    public class AccountTeamMemberDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    AccountTeamMember.AccountAccessLevel=>'Edit',
                    AccountTeamMember.CaseAccessLevel=>'None',
                    AccountTeamMember.ContactAccessLevel=>'Edit',
                    AccountTeamMember.OpportunityAccessLevel=>'Edit',
                    AccountTeamMember.TeamMemberRole=>'Business Development Manager'
            };
        }
    }    

    public class MyAccountDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Account.Name => 'My Test Account', 
                    Account.Status__c=>'Dormant', 
                    Account.Drive_Down__c=>'No',
                    Account.National_Account__c=>'Yes', 
                    Account.Contract_Type__c=>'Master Agreement',
                    Account.Number_of_Active_Contracts__c=>1,
                    Account.CurrencyIsoCode=>'USD',
                    Account.Protocols_ACM_Testing__c=>'Test',
                    Account.Protocols_Adjusters__c=>'Test',
                    Account.Protocols_Billing__c=>'Test',
                    Account.Protocols_Broker__c=>'Test',
                    Account.Protocols_DFRs__c=>'Test',
                    Account.Protocols_Portal__c=>'Test',
                    Account.Protocols_Pricing__c=>'Test',
                    Account.Protocols_Special_Concerns__c=>'Test',
                    Account.Protocols_Work_Auth_PO__c=>'Test',
                    Account.Data_Admin_Reason__c=>'Bypass Validation Errors',
                    Account.RecordTypeId=>GeneralConstants.RT_ID_ACC_ACCOUNT,
                    Account.House_Account__c=>false
            };
        }
    }

    public class PropertyDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Account.Name => 'Test Property',
                    Account.ShippingStreet => '1234 Stinky Street',
                    Account.ShippingCity => 'San Francisco',
                    Account.ShippingCountryCode=>'US',
                    Account.ShippingStateCode => 'CA',
                    Account.ShippingPostalCode => '94102',
                    Account.CurrencyIsoCode=>'USD',
                    Account.Protocols_ACM_Testing__c=>'Test',
                    Account.Protocols_Adjusters__c=>'Test',
                    Account.Protocols_Billing__c=>'Test',
                    Account.Protocols_Broker__c=>'Test',
                    Account.Protocols_DFRs__c=>'Test',
                    Account.Protocols_Portal__c=>'Test',
                    Account.Protocols_Pricing__c=>'Test',
                    Account.Protocols_Special_Concerns__c=>'Test',
                    Account.Protocols_Work_Auth_PO__c=>'Test' ,
                    Account.RecordTypeId=>GeneralConstants.RT_ID_ACC_PROPERTY,
                    Account.Data_Admin_Reason__c=>'Bypass Validation Errors'                  

            };
        }
    }

    public class ContactDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Contact.FirstName => 'First',
                    Contact.LastName => 'Last',
                    Contact.Email => 'testEmail@test.com',
                    Contact.Phone=> '(838) 837-9583'
            };
        }
    }

    public class InvoiceDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Invoice__c.Invoice_Date__c => Date.today(),
                    Invoice__c.Status__c=>'Open'
            };
        }
    }    

    public class OpportunityDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.StageName => 'Closed Won',
                    Opportunity.CloseDate => System.today()
            };
        }
    }

    public class CaseDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Case.Subject => 'Test Case'
            };
        }
    }

    public class UserDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                USER.LocaleSidKey => 'en_US',
                User.TimeZoneSidKey => 'America/Chicago'
            };
        }
    }   

    public class ContractClientDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Contract.Status => 'Draft',
                Contract.Contract_Changes__c => 'Standard',
                Contract.Client_Contract_Type__c => 'National Account Agreement',
                Contract.Government_Contract__c => 'No',
                Contract.CustomerSignedTitle => 'CEO',
                Contract.RecordTypeId => GeneralConstants.RT_ID_CONTRACT_CLIENT,
                Contract.Account_Contract_Type__c => 'MSA Only',
                Contract.Rate_Type__c => 'Fixed',
                Contract.Auto_Renew__c => true
            };
        }
    } 


    public class JobDefaults implements TestFactory.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                WorkOrder.Job_Name__c=>'Brookdale-Tempe', 
                WorkOrder.Status=>'In Queue',
                 
                //WorkOrder.Actual_Start_Date__c=>Date.newInstance(2020,01,13), 
                //WorkOrder.Estimated_Completion_Date__c=>Date.newInstance(2020,02,02), 
                //WorkOrder.Actual_Complete_Date__c=>Date.newInstance(2020,02,04),
                //WorkOrder.Original_Contract_Amount__c=>23760, 
                //WorkOrder.Revised_Contract_Amount__c=>36000, 
                //WorkOrder.Date_of_Call__c=>Date.newInstance(2020,01,13), 
                //WorkOrder.Date_of_Loss__c=>Date.newInstance(2020,01,130), 
                //WorkOrder.Practice__c=>'Healthcare', 
                //WorkOrder.Type_of_Facility__c=>'Hospital', 
                //WorkOrder.Street=>'1610 E Guadalupe Rd.', 
                //WorkOrder.City=>'Tempe', 
                //WorkOrder.StateCode=>'AZ', 
                //WorkOrder.PostalCode=>'85283', 
                //WorkOrder.CountryCode=>'US',
                //WorkOrder.Sage_Job_Business_Dev__c=>'Kimbrell/Torrey', 
                //WorkOrder.Sage_Job_CM_OM__c=>'Eric Maves', 
                //WorkOrder.Sage_Job_PM_SU__c=>'Rhonwen Holmes', 
                //WorkOrder.Sage_Job_Proj_Director__c=>'Mark Serey', 
                WorkOrder.Status_Note__c=>'test', 
                WorkOrder.Send_to_Accounting__c=>false,
                //WorkOrder.Job_To_Date_Payments_Received__c=>100, 
                //WorkOrder.AR_Receivable_Balance__c=>100
                //WorkOrder.Job_Number_Claim__c=>'2030-20-3453'
                WorkOrder.Data_Admin_Reason__c=>'Bypass Validation Errors',
                WorkOrder.House_Account__c=>false
            };
        }
    }
}