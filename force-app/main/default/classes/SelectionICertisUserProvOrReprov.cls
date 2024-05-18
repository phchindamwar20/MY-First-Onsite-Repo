public class SelectionICertisUserProvOrReprov extends SelectionBase {
    public override void setRecIdsToProcess(Map<Id, SObject> newById, Map<Id, SObject> oldById) {
        for (User newUser : (List<User>)newById.values()) {                
            User oldUser = oldById != null && oldById.containsKey(newUser.Id) ? (User)oldById.get(newUser.Id) : null;
                    
            if (isICertisUser(newUser,oldUser)) {
                recIds.add(newUser.Id);
            }
        } 
    }
    
    @TestVisible
    private Boolean isICertisUser(User newUser, User oldUser) {
        Boolean processRec = false;
        
        if(newUser.IC_User__c != oldUser?.IC_User__c) {
        	processRec = true;
        }
		
        return processRec;
    }
}