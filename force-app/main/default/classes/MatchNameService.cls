/**
 * @description       : This recursively sets the match name of an account and it's children based on the Match Name formula field
 *                      The Match Name Formula field allows an admin to easily change the logic of the match name
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 07-31-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class MatchNameService {
    public void setMatchNames(Set<Id> accIds) {

        try {
            AccountTriggerHandler.isSuppressTrigger=true;
            List<Account> accUpdLst = new List<Account>();
            Map<Id, Account> accById = new Map<Id, Account>([SELECT Id, Match_Name__c, Match_Name_Formula__c FROM Account WHERE Id IN : accIds ORDER BY ParentId]);
            for (Account acc : accById.values()) {
                if (acc.Match_Name__c != acc.Match_Name_Formula__c) {
                    accUpdLst.add(new Account(Id=acc.Id, Match_Name__c=acc.Match_Name_Formula__c));
                    System.debug('~~~~ MatchNameService::setMatchNames: accUpdLst.Match_Name__c - ' + accUpdLst[accUpdLst.size()-1].Match_Name__c);
                }
            }

            if (!accIds.isEmpty()) {
                if (!accUpdLst.isEmpty()) {
                    String errorMsg = '';
                    Database.SaveResult[] resultLst = Database.update(accUpdLst, false);
                    for (Database.SaveResult sr : resultLst) {
                        if(!sr.isSuccess()) {
                            for (Database.Error err : sr.getErrors()) {
                                errorMsg += ' Error: ' + sr.getId() + ', status code: ' + err.getStatusCode() + ',  messsage: ' + err.getMessage() + '\n';
                            }
                        }
                    }

                    if (errorMsg.length() > 0 ) {
                        System.debug('~~~~ MatchNameService::setMatchNames: errorMsg - ' + errorMsg);
                        throw new MatchNameServiceException(errorMsg);
                    }
                }

                //recurisvely call the children accounts until no account remaining
                Map<Id, Account> childAccById = new Map<Id, Account>([SELECT Id FROM Account WHERE ParentId IN : accIds]);
                setMatchNames(childAccById.keySet());
            }
        } catch (MatchNameServiceException e) {
            //
        } catch (Exception e) {
            String errorMsg = 'Please log a ticket with Service Now and provide the following details: \n' ;
            errorMsg += ' Message: ' + e.getMessage() + '\n';
            errorMsg += ' Cause: ' + e.getCause() + '\n';
            errorMsg += ' Line Number: ' + e.getLineNumber() + '\n';
            errorMsg += ' StackTrace: ' + e.getStackTraceString() + '\n';
            errorMsg += ' Impacted account Ids: \n';
            for (Id thisId : accIds) {
                errorMsg += '  ' + thisId + '\n';
            }

            throw new MatchNameServiceException(errorMsg);
        } finally {
            
        }
    }

    class MatchNameServiceException extends Exception {}
}