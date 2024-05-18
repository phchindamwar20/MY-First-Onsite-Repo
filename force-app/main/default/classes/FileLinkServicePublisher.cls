/**
 * @description       : This publishes file link service events to be processed later on to updat the parent record with file links
 *                      The publish subscribe model was utlized to try to reduce row locks, since content document link object isn't bulkifed
 *                      and loading multiple records at a time from the custom ui component causes row locks.  Although we were aren't to
 *                      prevent row locks, we were able to add re-processing logic so the number of html links published to the parent record 
 *                      match the number of actual links on the parent record
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : Terri Jiles
**/
public with sharing class FileLinkServicePublisher {
    public static void publishFileLinkServiceEvents(List<FileLinkObject> fileLinkObjLst) {
        List<FileLinkServiceEvent__e> fileLinkServiceEventLst = new List<FileLinkServiceEvent__e>();

        for (FileLinkObject flo : fileLinkObjLst) {
            FileLinkServiceEvent__e flse = (FileLinkServiceEvent__e)FileLinkServiceEvent__e.SObjectType.newSObject(null, true);
            flse.SObject_Record__c = flo.sObjectRec;

            fileLinkServiceEventLst.add(flse);
        }

        List<Database.SaveResult> resultLst = EventBus.publish(fileLinkServiceEventLst);
    }
}