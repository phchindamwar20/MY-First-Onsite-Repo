/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-23-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class QueryBuilderServiceTest {
    @isTest
    private static void testGetIdStringFromLst() {
        Set<String> testIds = new Set<String>{'abc', 'def', 'ghi'};
        String result;

        Test.startTest();
        result=QueryBuilderService.getIdStringFromLst(testIds);
        Test.stopTest();

        System.assertEquals('\'abc\', \'def\', \'ghi\'', result);
    }
}