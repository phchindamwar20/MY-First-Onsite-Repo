@isTest
private class IcertisAgreementCancelScheduleTest {
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    static testmethod void testSchedule() {
        Test.StartTest();
		IcertisAgreementCancelSchedule testsche = new IcertisAgreementCancelSchedule();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
    }
}