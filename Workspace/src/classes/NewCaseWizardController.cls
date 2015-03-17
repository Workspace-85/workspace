// **************************************************************************************************************
// Name:            NewCaseWizardController Class
// Description:     Get location of newly created case
//                  Used to generate the location of case newly created using flow
// Author(s):       Thomas Su
// ************************Version Updates***********************************************************************
//
// Updated Date     Updated By      Update Comments 
//
// **************************************************************************************************************

public class NewCaseWizardController {

    public NewCaseWizardController(ApexPages.StandardController controller) {
    }

    public NewCaseWizardController() {
    }

    public Flow.Interview.New_Case_Wizard newCaseWizardFlow { 
        get; 
        set; 
    }
    
    // Returns the location of the newly created case
    public PageReference finishLocation {
        get {
            PageReference casePage = null;
            if (newCaseWizardFlow != null && newRecordId != null) {
                casePage = new PageReference('/' + newRecordId); casePage.setRedirect(true);
            }
            return casePage;          
        }
        set;
    }
    
    // Returns ID of the newly created case
    public String newRecordId{
        get {
            String record = '';
            
            if (newCaseWizardFlow != null) {
                record = string.valueOf(newCaseWizardFlow.getVariableValue('CaseID'));
            }
            return record;
        }
        set;
    }
}