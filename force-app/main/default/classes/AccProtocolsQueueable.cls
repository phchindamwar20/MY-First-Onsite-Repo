public without sharing class AccProtocolsQueueable extends GenericQueueable{
    
    
    public override void execute(QueueableContext context) { 
        try {
            
            Map<Id, Set<String>>  fieldsByAccId = ((SelectionAccProtocols) currentSelection).getFieldsByAccId();
            System.debug('fieldsByAccId- in Queue'+ JSON.serializePretty(fieldsByAccId));
            List<Account> updChildrenAccLst = AccProtocolsService.setChildrenProtocolsFromParents(fieldsByAccId);
            
            handleNext();
        } catch (Exception e) {
            handleError(e);
     	}
	}
    
    public override void handleError(Exception e) {
        handleNext();
    }
}