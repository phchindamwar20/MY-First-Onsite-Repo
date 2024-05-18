/**
 * @description       : This is the message passed in the platform event for File Links utlized in FileLinkService and then processed by 
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 07-25-2023
 * @last modified by  : Terri Jiles
**/
public with sharing class FileLinkObject {
    public String sObjectRec;

    public FileLinkObject(SObject rec) {
        this.sObjectRec = JSON.serialize(rec);
    }
}