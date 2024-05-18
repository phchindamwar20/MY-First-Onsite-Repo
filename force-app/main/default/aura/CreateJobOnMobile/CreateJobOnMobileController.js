//Start of STAR-3502
({
	init : function (cmp) {
        var flow = cmp.find("flowData");
        var inputVariables = [
        {
            name : 'recordId',
            type : 'SObject',
            value : cmp.get("v.recordId")
        }
            ];
        flow.startFlow("Create_Job_for_New_or_Existing_Account", inputVariables);
    }
})
//End of STAR-3502