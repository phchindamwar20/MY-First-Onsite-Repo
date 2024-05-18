/**
 * @File Name          : IcertisAgreementRecallScheduleTest.cls
 * @Description        : Test class for IcertisAgreementRecallScheduleTest
 * @Author             : Arpit Vashishtha
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 02-22-2024
 * @Modification Log   :  
 * Ver       Date            Author                 Modification
**/
@isTest
private class IcertisAgreementRecallScheduleTest {
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    static testmethod void testSchedule() {
        Test.StartTest();
		IcertisAgreementRecallSchedule testsche = new IcertisAgreementRecallSchedule();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
    }
}