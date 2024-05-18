/**
 * @File Name          : DoNothingService.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 4/13/2020, 1:55:07 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/13/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class DoNothingService {
    @InvocableMethod(label='Do Nothing' description='Class used in first step of a process builder to bypass logic.  It does nothing')
    public static void hacerNada() {
        System.debug('~~~~ DoNothing::doNada: Do Nothing!!!');
    }

}