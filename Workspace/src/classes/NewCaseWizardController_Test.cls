@isTest
private class NewCaseWizardController_Test {

    public static testMethod void testNewCaseWizardController() {
        // SFDC known limitation: unable to use assert in test class for flow
        NewCaseWizardController controller = new NewCaseWizardController();
        PageReference page = controller.finishLocation;
        String recordId = controller.newRecordId;
    }
}