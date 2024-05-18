/**
 * @description       : This is the selection criteria used to select accounts for go/no go calculation
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionGoNoGoAccount extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        //need to re-query this because I am comparing a formula field (Go No Go) with a text field (Go No Gox)
        //this way and admin can maintain the formula for the logic for (Go No Go) without getting a developer involved
        //we don't need to check the 'old' record because of this
        //putthing this in a Map query instead of within the loop reduce chances of CPU Timeout limit.
        //note:  putting in map, increases heap space but because this is not static, it should clear out of the heap when the control exits this method
        Map<Id, Account> accById = new Map<Id, Account>([SELECT Id, Go_No_Go__c, Go_No_Gox__c FROM Account WHERE Id IN: newById.keySet()]);
        for (Account newAcc : accById.values()) {
            if (isSelectionCriteriaMet(newAcc)) {
                recIds.add(newAcc.Id);
            }
        }
    }  
    
    @TestVisible
    private Boolean isSelectionCriteriaMet(Account newAcc) {
        Boolean isRecForProcessing = false;
        if (newAcc != null && newAcc.Go_No_Go__c != newAcc.Go_No_Gox__c) {
            isRecForProcessing = true;
        }        

        return isRecForProcessing;
    }
}