({
	 doInit : function(component, event, helper) {         
        var userinfoaction = component.get("c.getUserInformation");
        userinfoaction.setCallback(this,function(response){
             var state = response.getState();
             console.log(response.getReturnValue());
             if (state == 'SUCCESS') {
                 component.set("v.userinfo", JSON.stringify(response.getReturnValue()));
             }
        });
        $A.enqueueAction(userinfoaction);
	}
})