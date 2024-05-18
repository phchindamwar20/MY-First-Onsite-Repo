/**
 * @description       : This select 'parent' records that change formula fields on child objects.  When the values of the fields the formula depend on change, these records should be selected to send to Bolt
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-20-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class SelectionBoltIntegrationFormula extends SelectionBase{
    private Map<String,  Set<Id>> idsByTrgObjParFlds = new Map<String, Set<Id>>();
    private Map<String, Set<String>> trgObjsParFldsBySrcFld = new Map<String, Set<String>>();
    private Map<String, String> boltSelClassByTrgObjParFld = new Map<String, String>();

    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        String thisObjectType = String.valueOf(newById.values()[0].Id.getSObjectType());

        getTrgObjsBySrcField(thisObjectType);

        for (SObject newRec : newById.values()) {
            if (newRec != null && oldById != null && selectRecord(newRec, oldById.get(newRec.Id))) {
                recIds.add(newRec.Id);
            }
        }
    }

    public Map<String,  Set<Id>> getIdsByTrgObjParFlds() {
        return idsByTrgObjParFlds;
    }

    public Map<String, String> getBoltSelClassByTrgObjParFld() {
        return boltSelClassByTrgObjParFld;
    }


    private void getTrgObjsBySrcField (String targetObject) {
        for (Bolt_Integration_Formula_Field_Mapping__mdt biffm : [SELECT 
                                                                        Id, BoltSelectionClassName__c, Source_Object_API_Name__c, Source_Field_API_Name__c, Target_Object_API_Name__c, Target_Parent_Field__c 
                                                                    FROM Bolt_Integration_Formula_Field_Mapping__mdt 
                                                                    WHERE Source_Object_API_Name__c =: targetObject]) {
            String trgObjParFldKey = biffm.Target_Object_API_Name__c + '-' + biffm.Target_Parent_Field__c;

            //create mapping between the target object/Parent Field and the Bolt Selection Class
            if (!boltSelClassByTrgObjParFld.containsKey(trgObjParFldKey)) {
                boltSelClassByTrgObjParFld.put(trgObjParFldKey, biffm.BoltSelectionClassName__c);
            }

            //create mapping between src field and target objects/Parent Fields
            if (!trgObjsParFldsBySrcFld.containsKey(biffm.Source_Field_API_Name__c)) {
                trgObjsParFldsBySrcFld.put(biffm.Source_Field_API_Name__c, new Set<String>());
            }
            trgObjsParFldsBySrcFld.get(biffm.Source_Field_API_Name__c).add(trgObjParFldKey);
        }

    }


    @TestVisible 
    private Boolean selectRecord(SObject newRec, SObject oldRec) {
        Boolean selectRec = false;
        for (String srcFld : trgObjsParFldsBySrcFld.keySet()) {
            if (newRec != null && oldRec != null && newRec.get(srcFld) != oldRec.get(srcFld)) {

                //create mapping between ids and target object/parent field
                for (String trgObjParFld : trgObjsParFldsBySrcFld.get(srcFld)) {
                    if (!idsByTrgObjParFlds.containsKey(trgObjParFld)) {
                        idsByTrgObjParFlds.put(trgObjParFld, new Set<Id>());
                    }
                    idsByTrgObjParFlds.get(trgObjParFld).add(newRec.Id);
                }
                selectRec = true;
            }
        }

        return selectRec;
    }

}