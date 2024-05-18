import { LightningElement,track, wire, api } from 'lwc';
import getEmployeeCommission from '@salesforce/apex/ManageEmployeeController.getEmployeeCommission';
import getJobCommission from '@salesforce/apex/ManageEmployeeController.getJobCommission';
import getConfirmationScreenRecords from '@salesforce/apex/ManageEmployeeController.getConfirmationScreenRecords';
import saveEmployeeCommissionRecord from '@salesforce/apex/ManageEmployeeController.saveEmployeeCommissionRecord';
import calculateSplitMultiplier from '@salesforce/apex/ManageEmployeeController.calculateSplitMultiplier';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';




export default class ManageEmployees extends NavigationMixin(LightningElement) {
    @track dataTableResponseWrappper;//columns information available in the data table
    @track finalSObjectDataList;//All records available in the data table
    @track paidRecordsList = [];
    @track confirmationDataTableResponseWrappper;//columns information available in the data table
    @track confirmationFinalSObjectDataList;//All records available in the data table
    @track finalSObjectDataListTemp = [];
    @track exceptionReasonValue;
    showTable = false;
    recordId;
    error;
    saveDraftValues = [];
    showAddEmployee = false;
    showConfirmationScreen = false;
    showManageCommissionScreen = true;
    disableNextButton = false;
    selectedUserRecord;
    lstCheckedRecords = [];
    selectedUserIds = [];
    deletedUserIds = [];
    customSplits = false;
    splitPercentageOverride = false;
    checkedIds;
    checkedEmpCommIds;
    totalPercent = 0;
    displayActualTotalCommissionPayment = 0;
    actualTotalCommissionPayment = 0;
    jobCommissionRec;
    splitMultiplier;
    jobAmount;
    actualSlowCollIncentive;
    actualQuickCollIncentive;
    actualDepositPaymentIncentive;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            if(typeof this.recordId !== 'undefined') {
                this.getEmployeeCommissionJs(this.recordId);
                this.getJobCommissionJs(this.recordId);
            }
        }
    }

    getJobCommissionJs(recId) {
        getJobCommission({jobCommissionId: recId})
        .then(data=>{
            this.jobCommissionRec = data;
            this.jobAmount = this.currencyFormatter(this.jobCommissionRec.Job_Amount__c);
            this.actualSlowCollIncentive = this.percentageFormatter(this.jobCommissionRec.Actual_Slow_Collection_Incentive__c);
            this.actualQuickCollIncentive = this.percentageFormatter(this.jobCommissionRec.Actual_Quick_Collection_Incentive__c);
            this.actualDepositPaymentIncentive = this.percentageFormatter(this.jobCommissionRec.Actual_Deposit_1st_Payment_Incentive__c);
            console.log('this.jobCommissionRec::::',this.jobCommissionRec);
        })
        .catch(error => {
            this.showTable = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        })
    }


    getEmployeeCommissionJs(recId) {
        getEmployeeCommission({jobCommissionId: recId})
        .then(results=>{
            let sObjectRelatedFieldListValues = [];
            
            for (let row of results.lstDataTableData) {
                const finalSobjectRow = {}
                let rowIndexes = Object.keys(row); 
                rowIndexes.forEach((rowIndex) => {
                    const relatedFieldValue = row[rowIndex];
                    if(rowIndex == 'Individual_Split_Percentage__c') {
                        this.totalPercent = parseFloat(this.totalPercent) + parseFloat(relatedFieldValue);
                        parseFloat(this.totalPercent).toFixed(4);
                    }
                    if(relatedFieldValue.constructor === Object){
                        this._flattenTransformation(relatedFieldValue, finalSobjectRow, rowIndex)        
                    } else {
                        if(rowIndex == 'Individual_Split_Percentage__c') {
                            finalSobjectRow[rowIndex] = this.percentageFormatter(relatedFieldValue.toFixed(4));
                        } else {
                            finalSobjectRow[rowIndex] = relatedFieldValue;
                        }
                    }
                });
                this.selectedUserIds.push(finalSobjectRow['Employee__c']);
                sObjectRelatedFieldListValues.push(finalSobjectRow);
            }
            this.dataTableResponseWrappper = results;
            this.finalSObjectDataList = sObjectRelatedFieldListValues;
            console.log('this.finalSObjectDataList:::',this.finalSObjectDataList.length);
            if(this.finalSObjectDataList.length > 0) {
                this.showTable = true;
            } else {
                this.showTable = false;
            }
            
        })
        .catch(error => {
            this.showTable = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        })
    }


    
    connectedCallback() {
        //code here
        console.log('I am in connectedCallback');
        this.showManageCommissionScreen = true;
    }

    _flattenTransformation = (fieldValue, finalSobjectRow, fieldName) => 
    {        
        let rowIndexes = Object.keys(fieldValue);
        rowIndexes.forEach((key) => 
        {
            let finalKey = fieldName + '.'+ key;
            finalSobjectRow[finalKey] = fieldValue[key];
        })
    }

    getSelectedRec() {
        try {
            console.log('I am in getSelectedRec');
            var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
            console.log(selectedRecords.length);
            if(selectedRecords.length > 0){
                let ids = '';
                let checkedEmpIds = '';
                selectedRecords.forEach(currentItem => {
                    if(currentItem.Status__c === 'Paid') {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'You can not make changes to Paid records.',
                                variant: 'error'
                            })
                        );
                        this.saveDraftValues = [];
                        return;
                    } else {
                        ids = ids + ',' + currentItem.Employee__c;
                        checkedEmpIds = checkedEmpIds + ',' + currentItem.Id;
                    }
                });
                if (ids != '') this.checkedIds = ids.replace(/^,/, '');
                if (checkedEmpIds != '') this.checkedEmpCommIds = checkedEmpIds.replace(/^,/, '');
                this.lstCheckedRecords = selectedRecords;
            } 
        } catch(error) {
            console.log('error::',error);
        }
    }

    handleSave(event) {
        try {debugger;
            console.log('I am in handleSave');
            this.saveDraftValues = event.detail.draftValues;
            let empCommissionGreaterThanJobComm = false;
            this.saveDraftValues.forEach((ele) => {
                this.finalSObjectDataList.forEach((obj) => {
                    if(ele.Id === obj["Id"]) {
                        if(obj["Status__c"] === 'Paid') {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'You can not make changes to Paid records.',
                                    variant: 'error'
                                })
                            );
                            return;
                        }
                        if(ele.Individual_Split_Percentage__c) {
                            if(ele.Individual_Split_Percentage__c > this.jobCommissionRec.Max_Split_Percentage__c) {
                                empCommissionGreaterThanJobComm = true;
                            } else {
                                obj["Individual_Split_Percentage__c"] = this.percentageFormatter(parseFloat(ele.Individual_Split_Percentage__c).toFixed(4));
                            }
                        }
                        
                        if(ele.Exception_Commission_Amount__c) {
                            obj["Exception_Commission_Amount__c"] = parseFloat(ele.Exception_Commission_Amount__c).toFixed(4);
                        }
                        

                        if(ele.Exception_Reason__c) {
                            obj["Exception_Reason__c"] = ele.Exception_Reason__c;
                        }
                    }
                });
            });
            this.totalPercent = 0.0000;
            this.finalSObjectDataList.forEach((obj) => {
                if(obj['Individual_Split_Percentage__c']) {
                    this.totalPercent = parseFloat(this.totalPercent) + parseFloat(obj['Individual_Split_Percentage__c']);
                    this.totalPercent.toFixed(4);
                }
            });
            if(empCommissionGreaterThanJobComm) {
                this.disableNextButton = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'An Employee Commission can\'t exceed ' + this.jobCommissionRec.Max_Split_Percentage__c + '% of the Job Commission.',
                        variant: 'error'
                    })
                );
            } else if(this.totalPercent.toFixed(4) > 100.0000) {
                this.disableNextButton = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Total percentage cannot be more than 100%.',
                        variant: 'error'
                    })
                );
            } else if(this.totalPercent.toFixed(4) < 100.0000) {
                this.disableNextButton = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Total percentage cannot be less than 100%.',
                        variant: 'error'
                    })
                );
            } else {
                this.saveDraftValues = [];
                this.disableNextButton = false;
            }
            this.customSplits = true;
            this.splitPercentageOverride = true;
            console.log('END I am in handleSave');
        } catch(err) {
            console.log('error::',err);
        }
    }

    handleAddEmployeeClick() {
        this.showAddEmployee = true;
        this.showManageCommissionScreen = false;
    }

    handleBackAddEmployeeClick() {
        this.showAddEmployee = false;
        this.showManageCommissionScreen = true;
    }

    handleValueSelectedOnUser(event) {
        this.selectedUserRecord = event.detail;
    }

    handleAddAddEmployeeClick() {
        try {
            this.disableNextButton = false;
            const selectedUser = {};
            selectedUser["Id"] = this.selectedUserRecord["id"];
            selectedUser["Name"] = this.selectedUserRecord["mainField"];
            selectedUser["Employee__c"] = this.selectedUserRecord["id"];
            selectedUser["Status__c"] = "";
            selectedUser["Commission_Payment_Date__c"] = "";
            selectedUser["Individual_Split_Percentage__c"] = 0.0000.toFixed(4);
            selectedUser["Employee_Name__c"] = this.selectedUserRecord["mainField"];
            selectedUser["Employee__r.Id"] = this.selectedUserRecord["id"];
            selectedUser["Exception_Commission_Amount__c"] = 0.0000.toFixed(4);
            selectedUser["Exception_Reason__c"] = "";
            this.finalSObjectDataList.push(selectedUser);
            let totalRecordsLength = this.finalSObjectDataList.length;
            this.paidRecordsList = [];

            let totalPaidPercent = 0.0000;
            this.finalSObjectDataList.forEach((obj) => {
                if(obj["Status__c"] === 'Paid') {
                    this.paidRecordsList.push(obj);
                    totalPaidPercent = parseFloat(totalPaidPercent) + parseFloat(obj["Individual_Split_Percentage__c"]);
                }
            });

            let paidRecordsLength = 0;
            paidRecordsLength = this.paidRecordsList.length;
            this.totalRecordsLength = parseFloat(totalRecordsLength) - parseFloat(paidRecordsLength);

            let percentSum = 0.0000;
            this.totalPercent = 0.0000;
            let totalPer = 100.0000;
            if(totalPaidPercent) {
                totalPer = totalPer - totalPaidPercent;
            }
            for (let i = 0; i < this.finalSObjectDataList.length; i++) {
                if(this.finalSObjectDataList[i].Status__c != 'Paid') {
                    this.finalSObjectDataList[i]['Individual_Split_Percentage__c'] = this.percentageFormatter((totalPer/this.totalRecordsLength).toFixed(4));
                    percentSum = percentSum + parseFloat((totalPer/this.totalRecordsLength).toFixed(4));
                }
            }
            
            let eachPer = percentSum/this.totalRecordsLength;
            let finalLastRecPer = eachPer * (this.totalRecordsLength - 1);
            let perLastRec = (totalPer.toFixed(4) - finalLastRecPer.toFixed(4));
            this.finalSObjectDataList[this.totalRecordsLength - 1]['Individual_Split_Percentage__c'] = this.percentageFormatter(perLastRec);
            this.finalSObjectDataList.forEach((obj) => {
                this.totalPercent = parseFloat(this.totalPercent) + parseFloat(obj['Individual_Split_Percentage__c']);
                this.totalPercent.toFixed(4);
            });
            this.selectedUserIds.push(this.selectedUserRecord["id"]);
            this.customSplits = true;
            this.showAddEmployee = false;
            this.showManageCommissionScreen = true;
            if(!this.showTable) {
                this.showTable = true;
            }
        } catch(err) {
            console.log(err);
        }
    }

    handleRemoveEmployeeClick() {
        try {
            let checkedArr = [];
            let checkedEmpCommArr = [];
            if(typeof this.checkedEmpCommIds != 'undefined' && this.checkedEmpCommIds.length > 0) {
                if(this.checkedEmpCommIds.includes(',')) {
                    checkedEmpCommArr = this.checkedEmpCommIds.split(',');
                } else {
                    checkedEmpCommArr.push(this.checkedEmpCommIds);
                }
                this.deletedUserIds = checkedEmpCommArr;
            }
            if(this.lstCheckedRecords.length === this.finalSObjectDataList.length) {
                this.disableNextButton = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'This job commission must have atleast one employee comission.',
                        variant: 'error'
                    })
                );
            }
            if(typeof this.checkedIds != 'undefined' && this.checkedIds.length > 0) {
                if(this.checkedIds.includes(',')) {
                    checkedArr = this.checkedIds.split(',');
                } else {
                    checkedArr.push(this.checkedIds);
                }
                this.finalSObjectDataListTemp = [];
                this.finalSObjectDataList.forEach((element) => {
                    checkedArr.forEach((ele) => {
                        if(element['Employee__c'] === ele && element['Status__c'] != 'Paid') {
                            let index = this.selectedUserIds.indexOf(ele);
                            this.selectedUserIds.splice(index, 1);
                        }
                    });
                });

                this.finalSObjectDataList.forEach((element) => {
                    this.selectedUserIds.forEach((ele) => {
                        if(element['Employee__c'] === ele) {
                            this.finalSObjectDataListTemp.push(element);
                        }
                    });
                });
                this.finalSObjectDataList = [];
                this.finalSObjectDataList = this.finalSObjectDataListTemp;
                let totalRecordsLength = this.finalSObjectDataList.length;
                

                this.paidRecordsList = [];

            let totalPaidPercent = 0.0000;
            this.finalSObjectDataList.forEach((obj) => {
                if(obj["Status__c"] === 'Paid') {
                    this.paidRecordsList.push(obj);
                    totalPaidPercent = parseFloat(totalPaidPercent) + parseFloat(obj["Individual_Split_Percentage__c"]);
                }
            });

            let paidRecordsLength = 0;
            paidRecordsLength = this.paidRecordsList.length;
            this.totalRecordsLength = parseFloat(totalRecordsLength) - parseFloat(paidRecordsLength);
            
            let percentSum = 0.0000;
            this.totalPercent = 0.0000;
            let totalPer = 100.0000;
            
            if(totalPaidPercent) {
                totalPer = totalPer - totalPaidPercent;
            }
            
            for (let i = 0; i < this.finalSObjectDataList.length; i++) {
                if(this.finalSObjectDataList[i].Status__c != 'Paid') {
                    this.finalSObjectDataList[i]['Individual_Split_Percentage__c'] = this.percentageFormatter((totalPer/this.totalRecordsLength).toFixed(4));
                    percentSum = percentSum + parseFloat((totalPer/this.totalRecordsLength).toFixed(4));
                }
            }
            let eachPer = percentSum/this.totalRecordsLength;
            let finalLastRecPer = eachPer * (this.totalRecordsLength - 1);
            let perLastRec = (totalPer.toFixed(4) - finalLastRecPer.toFixed(4));
            if(this.finalSObjectDataList[this.totalRecordsLength - 1]['Status__c'] != 'Paid') this.finalSObjectDataList[this.totalRecordsLength - 1]['Individual_Split_Percentage__c'] = this.percentageFormatter(perLastRec);
                this.finalSObjectDataList.forEach((obj) => {
                    this.totalPercent = parseFloat(this.totalPercent) + parseFloat(obj['Individual_Split_Percentage__c']);
                    this.totalPercent.toFixed(4);
                });
                this.customSplits = true;
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select atleast one record.',
                        variant: 'error'
                    })
                );
            }
        } catch(err) {
            console.log(err);
        }
    }

    handleNextClick() {
        try {
            if(!this.exceptionReasonValue) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Exception Reason is Required.',
                        variant: 'error'
                    })
                );
                return;
            }
            if(this.totalPercent.toFixed(4) < 100.0000) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Employees should have total 100% percentage.',
                        variant: 'error'
                    })
                );
                return;
            }
            this.showConfirmationScreen = true;
            this.showManageCommissionScreen = false;
            this.actualTotalCommissionPayment = 0;
            getConfirmationScreenRecords({ 
                jobCommissionId: this.recordId,
                dataTableResponseWrapStr: JSON.stringify(this.dataTableResponseWrappper),
                finalSObjectDataStr: JSON.stringify(this.finalSObjectDataList)
            })
            .then(results=>{
                console.log('Next====');
                console.log(results);
                this.splitMultiplier = 0;
                this.calculateSplitMultiplierJs();
                let sObjectRelatedFieldListValues = [];
                if(results.lstDataTableData) {
                    for (let row of results.lstDataTableData) {
                        const finalSobjectRow = {}
                        let rowIndexes = Object.keys(row); 
                        rowIndexes.forEach((rowIndex) => {
                            const relatedFieldValue = row[rowIndex];
                            if(relatedFieldValue.constructor === Object){
                                this._flattenTransformation(relatedFieldValue, finalSobjectRow, rowIndex)        
                            } else {
                                if(rowIndex == 'Individual_Split_Percentage__c') {
                                    finalSobjectRow[rowIndex] = this.percentageFormatter(relatedFieldValue.toFixed(4));
                                } else if(rowIndex == 'Actual_Commission_Amount__c') {
                                    this.actualTotalCommissionPayment += parseFloat(relatedFieldValue);
                                    finalSobjectRow[rowIndex] = relatedFieldValue;
                                }  else {
                                    finalSobjectRow[rowIndex] = relatedFieldValue;
                                }
                            }
                        });
                        sObjectRelatedFieldListValues.push(finalSobjectRow);
                    }
                    this.confirmationDataTableResponseWrappper = results;
                    this.confirmationFinalSObjectDataList = sObjectRelatedFieldListValues;
                    this.displayActualTotalCommissionPayment = this.actualTotalCommissionPayment;
                    this.displayActualTotalCommissionPayment = this.currencyFormatter(this.displayActualTotalCommissionPayment);
                    this.showTable = true;
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'No Results Returned.',
                            variant: 'error'
                        })
                    );
                }
            })
            .catch(error => {
                this.showTable = false;
                console.log('error');
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
        } catch(err) {
            console.log('err');
            console.log(err);
        }
    }

    calculateSplitMultiplierJs() {
        console.log('I am in calculateSplitMultiplierJs');
        calculateSplitMultiplier({ 
            jobCommissionId: this.recordId,
            finalSObjectDataStr: JSON.stringify(this.finalSObjectDataList)
        })
        .then(results=>{
            console.log('results',results);
            this.splitMultiplier = results.Split_Multiplier__c;
        })
        .catch(error => {
            this.showTable = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        })
    }

    percentageFormatter(num) {
        return new Intl.NumberFormat('default', {
            style: 'percent',
            minimumFractionDigits: 4,
            maximumFractionDigits: 4,
        }).format(num / 100);
    }

    currencyFormatter(num) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(num);
    }

    handleCancelClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    handleChangeExceptionReason(event) {
        this.exceptionReasonValue = event.detail.value;
    }

    handleConfirmationScreenPreviousClick() {
        this.showConfirmationScreen = false;
        this.showManageCommissionScreen = true;
        this.showTable = true;
    }

    handleConfirmationScreenSaveClick() {
        try {
            saveEmployeeCommissionRecord({ 
                jobCommissionId: this.recordId,
                exceptionReasonValue: this.exceptionReasonValue,
                finalSObjectDataStr: JSON.stringify(this.finalSObjectDataList),
                selectedUserIds: JSON.stringify(this.selectedUserIds),
                deletedUserIds: JSON.stringify(this.deletedUserIds),
                customSplits: this.customSplits,
                splitPercentageOverride: this.splitPercentageOverride
            })
            .then(results=>{
                if(results === 'success') {
                    let url = window.location.origin + '/' + this.recordId;
                    window.open(url, "_self");
                } else {
                    this.showTable = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: results,
                            variant: 'error'
                        })
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            })
            .catch(error => {
                this.showTable = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
        } catch(err) {
            console.log('Error:::',err);
        }
    }
}