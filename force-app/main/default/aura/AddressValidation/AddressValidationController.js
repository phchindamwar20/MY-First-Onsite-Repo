/* ************************************************************************
Author:         
Company:        FirstOnSite
Description:    JS Controller of Address Validation Lightning Component, used to call helper file.
JS Controller:  AddressValidationController.js
Class:     		AddressValidationController.cls
Test Class:     AddressValidationControllerTest.cls
************************************************************************ */
({
    doInit : function(component, event, helper) {
        helper.doInitHelper(component, event, helper);
    },
    /* When typing the search text in input field */
    onAddressInput : function(component, event, helper) {
        helper.onAddressInputHelper(component, event);
    },
    /* When selecting a prediction available in the address suggestion list */
    onAddressSelect : function(component, event, helper) { 
        helper.onAddressSelectHelper(component, event);
    },
})