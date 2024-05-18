/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-21-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/Test/*')
global without sharing class TestManager extends RecordManagerTemplate {
    @HttpPost
    global static void createRecordTest(){
        createRecord('testClassMethod', 'TestManager');
    }

    public static void updateRecordListTest() {
        updateRecordList( 'testClassMethod', 'TestManager'); 
    }    
}