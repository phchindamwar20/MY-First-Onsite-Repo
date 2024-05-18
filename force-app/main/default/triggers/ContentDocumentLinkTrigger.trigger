/**
 * @description       : This is the content document link trigger
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 09-26-2023
 * @last modified by  : Terri Jiles
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   08-02-2021   Terri Jiles                          Initial Version
**/
trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert, after insert) {
    TriggerDispatcher.Run('ContentDocumentLink', Trigger.operationType);
}