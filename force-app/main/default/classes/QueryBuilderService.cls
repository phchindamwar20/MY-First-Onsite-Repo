/**
 * @description       : This class is a utlitiy for building queries
 * @author            : Terri Jiles
 * @group             : 
 * @last modified on  : 08-09-2023
 * @last modified by  : Terri Jiles
**/
public without sharing class QueryBuilderService {
    //can be saleforce record ids or alternative ids for use in a where in claues
    public static String getIdStringFromLst(Set<String> ids) {
        String idString = '';
        Integer size = ids.size(), row = 1; 
        for (String thisId : ids) {
            idString+='\''+thisId+'\'';
            if (row < size) {
                idString+=', ';
                row++;
            } 
            //ids.remove(thisId); //removing from the set reduces heap size according to Salesforce, but it doesn't 
        }
        //System.debug('~~~~ BoltService::getIdStringFromLst - idString ' + idString);
        return idString;
    }
}