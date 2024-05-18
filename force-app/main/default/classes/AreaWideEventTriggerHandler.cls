/**
 * @description       : This handler is defined but has been refactored to call the bolt integration utlizing the queueable chain of responsibility framework.
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-04-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class AreaWideEventTriggerHandler extends TriggerHandlerBase {
    public override void afterInsert(Map<Id, SObject> newItems) {}

    public override void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
}