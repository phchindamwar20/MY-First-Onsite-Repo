/**
 * @File Name          : IcertisAgreementRecallSchedule.cls
 * @Description        : THis schedules the IcertisAgreementRecallBatch
 * @Author             : Arpit Vashishtha
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 02-22-2024
 * @Modification Log   :  
 * Ver       Date            Author                 Modification
**/
global class IcertisAgreementRecallSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        try {
            IcertisAgreementRecallBatch bcn = new IcertisAgreementRecallBatch();
            Database.executeBatch(bcn, ICertisConstants.BATCH_SIZE_RECALL);
        } catch(Exception ex) {
            System.debug('Job Error: '+ex.getMessage());
        } 
    }   
}