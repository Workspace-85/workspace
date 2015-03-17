global class g_CustomCaseLookupController {
	public List<Case> case_results {get;set;} // search results
  
	public string searchString {get;set;} // search keyword
	public static string ixnId {get;set;} // interaction id 
	public string caseNumber {get;set;}
	public string subject {get;set;}
	public string createdDate {get;set;}      
  
	public g_CustomCaseLookupController() {
		// get the current search string
		searchString = System.currentPageReference().getParameters().get('lksrch');
		ixnId = System.currentPageReference().getParameters().get('ixnId');
		system.debug('*** CustomCaseLookupController ixnId ' + ixnId);
		//searchString is in this format:
		//{"found":"2","contactId":"","caseId":"500o0000001JD2PAAW,500o0000000e0A4AAI"}
		system.debug('*** CustomCaseLookupController search for ' + searchString);      
		  
		if (searchString != '' && searchString != null) {
			runSearch();
		}
	}
	
	
	// performs the keyword search
	global PageReference search() {
		system.debug('*** search');
		runSearch();
		return null;
	}
    
  
	// prepare the query and issue the search command
	private void runSearch() {
		system.debug('*** runSearch');
		performSearch(searchString);         
	} 
  
  
	// run the search and save the records found. 
	private void performSearch(string searchString) {
		system.debug('*** performSearch for ' + searchString);
		
		case_results = null;
		Integer listSize = 0;
		system.debug('*** caseNumber = ' + caseNumber);
		system.debug('*** subject = ' + subject);
		system.debug('*** createdDate = ' + createdDate);
		String caseIds = '';
		//searchString is in this format:
		//{"found":"2","contactId":"","caseId":"500o0000001JD2PAAW,500o0000000e0A4AAI"}        
		JSONParser parser = JSON.createParser(searchString);
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
				String fieldName = parser.getText();
				parser.nextToken();
				if (fieldName == 'caseId') {
					caseIds = parser.getText(); 
				}
			}
		}
		system.debug('*** caseIds = ' + caseIds);
		List<String> parts = caseIds.split(',');
		Set<Id> caseIdSet = new Set<Id>();
		for (String caseId : parts) {
			// Conversion String -> ID may cause an exception if such ID does not exist
			try {
				caseIdSet.add(caseId);
			}
			catch (Exception e) {
				system.debug('Case ID not found: ' + caseId);
			}
		}
		case_results = [select CaseNumber, Subject, Account.Name, Contact.Name, CreatedDate 
				from case where Id in :caseIdSet];
		/*
		for (String caseId : parts) {
			System.debug('*** caseId = ' + caseId);
			Case case_result = [select CaseNumber, Subject, Account.Name, Contact.Name, CreatedDate 
					from case where Id = :caseId];
			if (case_result != null) {
				if (case_results == null) {
					case_results = new List<Case>();
				}
				case_results.add(case_result);
			}
		}
		*/
	}
	
	
	// used by the visualforce page to send the link to the right dom element
	public string getFormTag() {
		return System.currentPageReference().getParameters().get('frm');
	}
	  
	// used by the visualforce page to send the link to the right dom element for the text box
	public string getTextBox() {
		return System.currentPageReference().getParameters().get('txt');
	}
}