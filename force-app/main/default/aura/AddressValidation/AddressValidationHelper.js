/* ************************************************************************
Author:         
Company:        FirstOnSite
Description:    JS Controller of Address Validation Lightning Component, 
            which is used to validate address using Experian API.
Helper:         AddressValidationHelper.js
Class:     		AddressValidationController.cls
Test Class:     AddressValidationControllerTest.cls

History:
When        	Who     What
14-May-2019     DV      - Allow set default location using lat + lng
                    - Allow return 'back' to search using place id

20-May-2019     DV      - Added UUID for session token to reduce billing costs

21-May-2019     DV      - Checks if sublocality_level_1 or locality is available as sets it into v.locality as City
                    - County field added as additional optional field

23-May-2019     DV      - Bug fix on handling v.searchTimeout when deleting the input after typing
                    - Reduced padding around layoutItems to better fit the area and adjusted box size of suggestions
                    - Relabeled markers
                    - Enable component to reuse existing data instead of querying the API again using Place ID

26-July-2019    DV      - Updated field labels to use 'Custom Labels'
                    - Updated Component Title to use a dynamic 'Custom Label Name'
                    - Added handling for when the City only shows in the neighborhood field

17-Oct-2019     DV      - Added 'Required' attribute and validation
                    - Cleaned up init methods into helper classes

18-Oct-2019     DV      - Split 'Required' into 'Search Required' and 'Detailed Address Fields Required'

17-June-2022	AV      - Updated the component to add parameter(CountryISO Code, max suggestion, 
                    dataset) values.

************************************************************************ */
({
    CONSTANTS_VARIABLE : {
        SUCCESS : "SUCCESS",
        ERROR : "ERROR",
        INCOMPLETE : "INCOMPLETE",
    },
doInitHelper : function(component, event, helper) {
    helper.setTitle(component);
    helper.checkValidFilter(component);
    helper.setValidation(component);
    helper.initialiseMapData(component, helper);
},
callServer: function(component, method, callback, params) {
    try {
        let action = component.get(method);
        if (params) {
            action.setParams(params);
        }
        
        action.setCallback(this,function(response) {
            let state = response.getState();
            if (state === this.CONSTANTS_VARIABLE.SUCCESS) {
                // pass returned value to callback function
                callback.call(this, response.getReturnValue());
            } else if (state === this.CONSTANTS_VARIABLE.ERROR) {
                // generic error handler
                let errors = response.getError();
                if (errors) {
                    console.log("Errors", errors);
                    if (errors[0] && errors[0].message) {
                        throw new Error("Error" + errors[0].message);
                    }
                } else {
                    throw new Error("Unknown Error");
                }
            }
        });
        
        $A.enqueueAction(action);
    } catch(err) {
        console.log('Error in callServer method::'+err);
    }
},
setTitle : function(component) {
    try {
        /* Set the Dynamic Component Labels */
        let titleLabel = '$Label.' + component.get("v.titleLabel");
        component.set("v.title", $A.getReference(titleLabel));
    } catch(err) {
        console.log('Error in setTitle method::'+err);
    }
},
setValidation : function(component) {
    try {
        let labels = {
            SEARCH_AND_ALL_ADDRESS_FIELDS_REQUIRED : $A.get("$Label.c.Search_and_All_Address_Fields_Required"),
            SEARCH_AND_ADDRESS_FIELD_REQUIRED : $A.get("$Label.c.Search_and_Address_Field_Required"),
            FILLED_ADDRESS_FIELDS_REQUIRED : $A.get("$Label.c.Filled_Address_Fields_Required"),
        }
        
        component.set('v.validate', function() {
            
            let isRequired = component.get("v.isRequired");
            let fieldsRequired = component.get("v.fieldsRequired");
            
            let showAddressFields = component.get("v.showAddressFields");
            let showCountyField = component.get("v.showCountyField");
            let locationValue = component.get("v.location").trim();
            let addressFieldEmpty = false;
            let addressFields = [];
            addressFields.push(component.get("v.fullStreetAddress"));
            addressFields.push(component.get("v.locality"));
            addressFields.push(component.get("v.country"));
            addressFields.push(component.get("v.administrative_area_level_1"));
            addressFields.push(component.get("v.postal_code"));
            showCountyField ? addressFields.push(component.get("v.administrative_area_level_2")) : "";
            
            addressFields.forEach(function(value) {
                value == null || value == "" ? addressFieldEmpty = true : "";
            })
            
            if(fieldsRequired && isRequired) {
                if(locationValue.length > 0 && !addressFieldEmpty) {
                    return { isValid: true };
                } else {
                    return { isValid: false, errorMessage: labels.SEARCH_AND_ALL_ADDRESS_FIELDS_REQUIRED };
                }
            } else if(!fieldsRequired && isRequired) {
                if(locationValue.length > 0)
                    return { isValid: true };
                else
                    return { isValid: false, errorMessage: labels.SEARCH_AND_ADDRESS_FIELD_REQUIRED };
            } else if(showAddressFields && fieldsRequired) {
                if(!addressFieldEmpty) 
                    return { isValid: true };
                else
                    return { isValid: false, errorMessage: labels.FILLED_ADDRESS_FIELDS_REQUIRED };
            }
        })
    } catch(err) {
        console.log('Error in setValidation method::'+err);
    }
},
initialiseMapData : function(component, helper) {
    try {
        let lat = component.get("v.latitude"), lng = component.get("v.longitude");
        let labels = {
            SELECTED_ADDRESS : $A.get("$Label.c.Selected_Address"),
            DEFAULT_ADDRESS : $A.get("$Label.c.Default_Address"),
            CURRENT_LOCATION : $A.get("$Label.c.Current_Location"),
            ENABLE_LOCATION_TRACKING : $A.get("$Label.c.Enable_Location_Tracking"),
            POSITION_UNAVAILABLE : $A.get("$Label.c.Position_Unavailable"),
            REQUEST_TIMED_OUT : $A.get("$Label.c.Request_Timed_Out"),
            UNKNOWN_ERROR : $A.get("$Label.c.Unknown_Error")
        }
        
        if(lat != null && lng != null) {
            
            let formattedAddress = component.get("v.formattedAddress");
            if(formattedAddress) {
                    helper.showMap(component, lat, lng, labels.SELECTED_ADDRESS, formattedAddress);
            } else {
                helper.showMap(component, lat, lng, labels.DEFAULT_ADDRESS);
            }
            // Set search area around the default latitude and longitude 
            component.set("v.currentLatitude", lat);
            component.set("v.currentLongitude", lng);
        }
        else {
            let geoSuccess = function(position) {
                /* Get the current users' location if location tracking is enabled */
                let startPos = position;
                helper.showMap(component, startPos.coords.latitude, startPos.coords.longitude, labels.CURRENT_LOCATION);
                
                /* Set the current latitude and longitude to filter the suggestion API to nearby suggestions only */
                component.set("v.currentLatitude", startPos.coords.latitude);
                component.set("v.currentLongitude", startPos.coords.longitude);
            };
            
            navigator.geolocation.getCurrentPosition(geoSuccess, function (error) {
                switch(error.code) {
                    case error.PERMISSION_DENIED:
                        component.set("v.mapLoadError", labels.ENABLE_LOCATION_TRACKING)
                        break;
                    case error.POSITION_UNAVAILABLE:
                        component.set("v.mapLoadError", labels.POSITION_UNAVAILABLE)
                        break;
                    case error.TIMEOUT:
                        component.set("v.mapLoadError", labels.REQUEST_TIMED_OUT)
                        break;
                    case error.UNKNOWN_ERROR:
                        component.set("v.mapLoadError", labels.UNKNOWN_ERROR)
                        break;
                }
            });
        }
    } catch(err) {
        console.log('Error in initialiseMapData method::'+err);
    }
},
showMap : function(component, lat, lng, title, description) {
    try {
        let showMap = component.get("v.showMap");
        if(showMap == true) {
            component.set("v.markerAvailable", false);
            component.set("v.mapMarkers", [
                {
                    location: {
                        'Latitude': lat,
                        'Longitude': lng
                    },
                    title: title,
                    description: description
                }
            ]);
            component.set("v.markerAvailable", true);
        }
    } catch(err) {
        console.log('Error in showMap method::'+err);
    }
},
startSearch : function(component) {
    try {
        component.set('v.predictions',null);
        let labels = {
            CONTACT_ADMIN : $A.get("$Label.c.Please_contact_your_admin"),
            API_UNKNOWN_ERROR : $A.get("$Label.c.API_Unknown_Error"),
        }
        /* Check if the search timeout exists yet and clear it if exists */
        let searchTimeout = component.get('v.searchTimeout');
        if (searchTimeout) {
            clearTimeout(searchTimeout);
        }
        
        /* Set timeout before starting the search to reduce number of API calls made
            keystrokes within 300ms will not make the call */ 
        searchTimeout = window.setTimeout(
            $A.getCallback(() => {
                /* Set search parameters of location input plus users' longitude and latitude if available */
                let params = {
                "input" : component.get("v.location"),
                "latitude" : component.get("v.currentLatitude"),
                "longitude" : component.get("v.currentLongitude"),
                "sessionToken" : component.get("v.UUID"),
                "countryFilters" : component.get("v.countryFilters"),
                "countryISO" : component.get("v.countryISO"),
                "dataset" : component.get("v.dataset"),
                "maxSuggestion" : component.get("v.maxSuggestion")
            };
                                                  
                            /* Make the server call to get Places Suggestion API results */
                            this.callServer(
                            component,
                            "c.getSuggestions",
                            function(response){
                                let resp = JSON.parse(response);
        						console.log('~~~~Arpit: resp::::');
        						console.log(JSON.parse(JSON.stringify(resp)));
                                if(resp && resp.result && resp.result.more_results_available == false){
                                    component.set("v.searching",false);
                                }
                            
                                if(resp && resp.result && resp.result.hasOwnProperty('suggestions')){
                                    if(resp && resp.result && resp.result.suggestions && resp.result.suggestions.length){
                                        component.set('v.predictions', resp.result.suggestions);
                                    }
                                }
                            }
                    , params);
                    /* Clear timeout when search is completed */
                    component.set('v.searchTimeout', null);
                }), 300); // Wait for 300 ms before sending search request
     
                component.set('v.searchTimeout', searchTimeout);
    } catch(err) {
        console.log('Error in startSearch method::'+err);
    }
},
getPlaceDetails: function(component, placeid) {
    try {
        let labels = {
            SELECTED_ADDRESS : $A.get("$Label.c.Selected_Address"),
            CONTACT_ADMIN : $A.get("$Label.c.Please_contact_your_admin"),
            API_UNKNOWN_ERROR : $A.get("$Label.c.API_Unknown_Error"),
        }
        console.log('::Placeid');
        console.log(placeid);
        let params = {
            "placeId" : placeid,
        }
        
        this.callServer(
            component,
            "c.getPlaceDetails",
            function(response){
                let placeDetails = JSON.parse(response);
                console.log('~~~placeDetails::');
                console.log(placeDetails);
                //--component.set("v.formattedAddress", placeDetails.result.suggestions[0].text);
                //--let addressArray = placeDetails.result.address;
                //--component.set("v.fullStreetAddress", placeDetails.result.address.address_line_1);
                /*if(addressArray.length>2){
                    let addressLocality =addressArray[1].trim().split(' '); 
                    let addressLocality2 =addressArray[2].trim().split(' ');
                    if(addressLocality2.length >3){
                        component.set("v.fullStreetAddress", addressArray[0]+' '+addressArray[1]);
                        component.set("v.locality", addressLocality2[0]+' '+addressLocality2[1]);
                        component.set("v.administrative_area_level_1", addressLocality2[2]);
                        component.set("v.postal_code", addressLocality2[3]);
                    }
                    else if(addressLocality2.length >2){
                        component.set("v.fullStreetAddress", addressArray[0]+' '+addressArray[1]);
                        component.set("v.locality", addressLocality2[0]);
                        component.set("v.administrative_area_level_1", addressLocality2[1]);
                        component.set("v.postal_code", addressLocality2[2]);
                    }else{
                        component.set("v.locality", addressLocality[0]);
                        component.set("v.administrative_area_level_1", addressLocality[1]);
                        component.set("v.postal_code", addressArray[2]);
                    }
                } else {
                    let addressLocality =addressArray[1].trim().split(' ');
                    
                    if(addressLocality.length >3){
                        component.set("v.locality", addressLocality[0]+ ' '+addressLocality[1]);
                        component.set("v.administrative_area_level_1", addressLocality[2]);
                        component.set("v.postal_code", addressLocality[3]);
                    } else {
                        component.set("v.locality", addressLocality[0]);
                        component.set("v.administrative_area_level_1", addressLocality[1]);
                        component.set("v.postal_code", addressLocality[2]);
                    }
                }*/
                var country = placeDetails.result.address.country;
                if(country == 'UNITED STATES OF AMERICA') {
                    country = 'US';
                } else if(country == 'Canada') {
                    country = 'CA';
                }
                component.set("v.fullStreetAddress", placeDetails.result.address.address_line_1 + ' ' + placeDetails.result.address.address_line_2 + ' ' + placeDetails.result.address.address_line_3);
                component.set("v.formattedAddress", placeDetails.result.address.address_line_1 + ' ' + placeDetails.result.address.address_line_2 + ' ' + placeDetails.result.address.address_line_3 + ' ' + placeDetails.result.address.locality + ' ' + placeDetails.result.address.country + ' ' + placeDetails.result.address.postal_code);
                component.set("v.locality", placeDetails.result.address.locality);
                //component.set("v.administrative_area_level_1", placeDetails.result.address.address_line_1 + ' ' + placeDetails.result.address.address_line_2 + ' ' + placeDetails.result.address.address_line_3);
                component.set("v.administrative_area_level_1", placeDetails.result.address.region);
                component.set("v.postal_code", placeDetails.result.address.postal_code);
                component.set("v.country", country);
                component.set('v.predictions', null);
                component.set("v.searching",false);
                //component.set('v.location', placeDetails.result.suggestions[0].text);
                
            },
            params
        );
    } catch(err) {
        console.log('Error in getPlaceDetails method::'+err);
    }
},
clearAddressFields : function(component) {
    try {
        component.set("v.locationSelected", false);
        component.set("v.placeId", null);
        component.set("v.latitude", null);
        component.set("v.longitude", null);
        component.set("v.premise", null);
        component.set("v.fullStreetAddress", null);
        component.set("v.street_number", null);
        component.set("v.route", null);
        component.set("v.locality", null);
        component.set("v.administrative_area_level_1", null);
        component.set("v.administrative_area_level_2", null);
        component.set("v.postal_code", null);
        component.set("v.country", null);
        component.set("v.formattedAddress", null);
    } catch(err) {
        console.log('Error in clearAddressFields method::'+err);
    }
},
checkValidFilter : function(component) {
    try {
        const labels = {
            COUNTRY_FILTER_LIMIIT : $A.get("$Label.c.Country_Filter_Limit"),
            COUNTRY_FILTER_FORMAT : $A.get("$Label.c.Country_Filter_Format"),
        }
        const countryFilters = component.get("v.countryFilters");
        if(countryFilters != '' && countryFilters != null) {
            let countryFiltersArr = countryFilters.split(",");
            
            if(countryFiltersArr.length > 5) {
                component.set("v.apiError", labels.COUNTRY_FILTER_LIMIIT);
            } else {
                countryFiltersArr.forEach(country => {
                    if(country.length != 2) {
                    component.set("v.apiError", labels.COUNTRY_FILTER_FORMAT);
                }
                                            })
            }
        }
    } catch(err) {
        console.log('Error in checkValidFilter method::'+err);
    }
},

generateUUID : function() { // Public Domain/MIT
    try {
        let d = new Date().getTime();
        if (typeof performance !== 'undefined' && typeof performance.now === 'function'){
            d += performance.now(); //use high-precision timer if available
        }
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
            let r = (d + Math.random() * 16) % 16 | 0;
            d = Math.floor(d / 16);
            return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
        });
    } catch(err) {
        console.log('Error in generateUUID method::'+err);
    }
},
onAddressSelectHelper : function(component, event) { // Public Domain/MIT
    try {
        component.set("v.locationSelected", false);

        let selected = event.currentTarget;
        let placeid = selected.getAttribute("data-placeid");
        console.log('******PlaceId=====');
        console.log(placeid);
        let UUID = component.get("v.UUID");
    
        /* Clear UUID session token after suggestion is selected */
        if(UUID != null && UUID != "") {
            component.set("v.UUID", "");
        }
        
        this.getPlaceDetails(component, placeid);
    } catch(err) {
        console.log('Error in onAddressSelectHelper method::'+err);
    }
},
onAddressInputHelper : function(component, event) { // Public Domain/MIT
    try {
        let locationInput = component.get("v.location");
    
        /* Check if the location input isn't empty */
        if(locationInput != null && locationInput != "" && locationInput.length > 4) {
            let UUID = component.get("v.UUID");
    
            /* Set searching status to true for lightning:input */
            component.set("v.searching", true);
    
            /* Generate UUID session token for current search session if it doesn't exist yet */
            if(UUID == null || UUID == "") {
                component.set("v.UUID", this.generateUUID());
            }
    
            this.startSearch(component);
        }
        else { // When text input is empty, clear all address fields
            var searchTimeout = component.get('v.searchTimeout');
            if(searchTimeout) { // Stop search if the input was deleted
                clearTimeout(searchTimeout);
                component.set("v.searching", false);
            }
    
            component.set('v.predictions', []);
            this.clearAddressFields(component);
        }
    } catch(err) {
        console.log('Error in onAddressInputHelper method::'+err);
    }
}
})