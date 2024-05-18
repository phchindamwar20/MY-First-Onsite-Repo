/**
 * @File Name          : IcertisAgreementCancelSchedule.cls
 * @Description        : This scheduler calls the IcertisAgreementCancelBatch in order to cancel duplicate agreements.  
 *                          It needed to be scheduled for a delay because iCertis callout to in the previous calling batch to recall 
 *                          the duplicate agreement is partially an asynchrounous process.  There would be issues cancelling the contract if it hadn't been fully recalled
 *                          The asynchronous part of the process calls out to Adobe eSignature to recall the agreements
 * @Author             : Arpit Vashistha
 * @Group              : 
 * @Last Modified By   : Terri Jiles
 * @Last Modified On   : 01-17-2024
 * @Modification Log   :  
 * Ver       Date            Author      		    Modification
 * 1.0      13/12/2020        AVashishtha           INITIAL DEVELOPMENT STAR-5366
**/
global class IcertisAgreementCancelSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        try {
            IcertisAgreementCancelBatch bcn = new IcertisAgreementCancelBatch();
            Database.executeBatch(bcn, ICertisConstants.BATCH_SIZE_CANCEL);
        } catch(Exception ex) {
            System.debug('Job Error: '+ex.getMessage());
        } finally { 
            Id cronTrigId = ctx.getTriggerId(); 
            System.abortJob(cronTrigId);
        }
    }   
}