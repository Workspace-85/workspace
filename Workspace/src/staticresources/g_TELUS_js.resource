/*
BKK and AJH
Customised Version of g_Default_js
OVERRIDES some OOB Functionality.
Includes IWS events handling, event routing, search calls, screen pop calls.

Listens to events:
"workspace/message"
"tabchange/message"
"CTIEvent/message"
*/

(function(window, jQuery, undefined) {

var _log = Log ? Log.log : console.log;
var activeInteractionID  = "";

jQuery.subscribe("workspace/message", processMessage);
jQuery.subscribe("tabChange/message", processTabChangeMessage);
jQuery.subscribe("CTIEvent/message", processCTIMessage);


function createAttDataArray(userData) {
	var businessAttributes = Workspace.getBusinessAttributes();
	var attData = new Array();
	$.each(userData, function(key, value) {
		if (! (key in businessAttributes)) {
			return;
		}
		var attr = $.extend(true, {}, businessAttributes[key]);
		attr.value = value;
		attData.push(attr);
	});
	return attData;
}

function showAttachedData(userData) {
    if (!userData) {
    	return;
    }

    Connector.showAttachedData(createAttDataArray(userData));
    if(Workspace.getAutoOpenDataDisplay == 'true')
    	sforce.interaction.setVisible(true);
}

////////////////////////////////////////////////////////////////////////////////////////
// event processing
//
// processMessage is called for all received communications from Interaction Workspace
// that contains valid work to be performed.
////////////////////////////////////////////////////////////////////////////////////////

function processMessage(obj) {
    if (obj.action == "OpenObject") {
        _log("in OpenObject");

        showAttachedData(obj.userData);

        // open based on type attribute
        if (obj.type == "Voice") {
        	var calltype = (obj.calltype===undefined) ? "" : obj.calltype;
        	if(calltype == "Internal"){
        		_log("Internal call, no screen pop");
        		return;
        	}
        	performVoiceScreenpopAction(obj);
        }
        else if (obj.type == "Email") {
            _log("processMessage: Email pop action for address: " + obj.source);
            performEmailAction(obj);
        }
        else if (obj.type == "Chat") {
            _log("processMessage: Chat pop action for address: " + obj.source);
            performChatAction(obj);
        }
        else if (obj.type == "InteractionWorkItem") {
            _log("processMessage: Workitem pop action for mediaType: " + obj.mediaType);
            performWorkItemAction(obj);
        }
        else if (obj.type == "OpenMedia") {
            _log("processMessage: OpenMedia pop action for mediaType: " + obj.mediaType + " for address: " + obj.source);
            performOpenMediaAction(obj);
        }
        else if (obj.type == "InteractionSms") {
            _log("processMessage: Sms pop action for address: " + obj.source);
            performSmsAction(obj);
        }
    }
    else if (obj.action == "CreateActivity") {
    	var ixnId = Salesforce.getIxnId(obj.id);
    	var objectIdForActivity = "";
    	
        _log("CreateActivity for connID " + obj.id + " delete Windows - " + ixnId);
        Salesforce.removeIxnWindow(ixnId);

        var useFocusedRecord = (obj.useFocusedRecord===undefined) ? "" : obj.useFocusedRecord;
    	_log("useFocusedRecord = " + useFocusedRecord);
	    
    	if(useFocusedRecord=="True" || useFocusedRecord=="true")
    	{
	    	sforce.interaction.getPageInfo(function(o) {
	    		if(o!=null && o.result!=null)
	    		{ 
	    			var jsonResult = jQuery.parseJSON(o.result);
	    			if(jsonResult!=null && jsonResult.objectId!=null)
	    			{
			            objectIdForActivity = jsonResult.objectId;
				        _log("CreateActivity for connID " + obj.id + " using object " + objectIdForActivity);
				
				        // create the task
				        createTask(obj, objectIdForActivity);	    			
	    				return;
	    			}
	    		}
    			prepareCreateTask(obj, objectIdForActivity);
	    	});	    
	    	clickToDialNum = "";
	    	resetActiveInteraction();
	    	return;
    	}
    	else
    	{
    		if (obj.type == "Voice"){
	    		//BKK check for attached data Connector_NewCaseID - if it is there, then use that
	    		_log("voice check Connector_NewCaseID");
	    		objectIdForActivity = (obj.userData.Connector_NewCaseID===undefined) ? "" : obj.userData.Connector_NewCaseID;
	    		if(objectIdForActivity == ""){
	    			_log("voice check Outcome_CaseID");
	    			objectIdForActivity = (obj.userData.Outcome_CaseID===undefined) ? "" : obj.userData.Outcome_CaseID;
	    		}
	       		if(objectIdForActivity == ""){
	       			_log("voice check sfdcObjectId");
	    			objectIdForActivity = (obj.userData.sfdcObjectId===undefined) ? "" : obj.userData.sfdcObjectId;
	    		}    		
		    	if(objectIdForActivity != ""){
			        _log("voice CreateActivity for connID " + obj.id + " using object " + objectIdForActivity);
					
			        // create the task
			        createTask(obj, objectIdForActivity);
			        
			        clickToDialNum = "";
			        resetActiveInteraction();
		    		return;
		    	}
    		}
    		if (obj.type == "InteractionWorkItem"){
    			_log("workitem check Outcome_CaseID");
    			objectIdForActivity = (obj.userData.Outcome_CaseID===undefined) ? "" : obj.userData.Outcome_CaseID;
	    		if(objectIdForActivity == ""){
	    			_log("workitem check Outcome_TaskID");
	    			objectIdForActivity = (obj.userData.Outcome_TaskID===undefined) ? "" : obj.userData.Outcome_TaskID;
	    		}
	    		if(objectIdForActivity == ""){
	    			_log("workitem check Connector_NewCaseID");
	    			objectIdForActivity = (obj.userData.Connector_NewCaseID===undefined) ? "" : obj.userData.Connector_NewCaseID;
	    		}    			
	       		if(objectIdForActivity == ""){
	       			_log("workitem check sfdcObjectId");
	    			objectIdForActivity = (obj.userData.sfdcObjectId===undefined) ? "" : obj.userData.sfdcObjectId;
	    		} 
    		}
    	}  	
    	prepareCreateTask(obj, objectIdForActivity);
    	resetActiveInteraction();
	
    }
    else if (obj.action == "MarkedDone") {
    	var ixnId = Salesforce.getIxnId(obj.id);
    	// todo Is it connID or objID?
        _log("MarkedDone for connID " + obj.id + " delete Windows - " + ixnId);
        Salesforce.removeIxnWindow(ixnId);
    }
    else if (obj.action == "FocusTab") {
        _log("FocusTab for " + obj.id);
        Salesforce.focusIxnTab(obj.id);
    }
    else if (obj.action == 'ConnectionDenied') {
    	//PJB: Don't reconnect if denied
    	_log("Connection denied, do not retry");
    	if(typeof(Storage) !== "undefined" && window!=null && window.sessionStorage!=null)
    	{
    		window.sessionStorage.setItem("Genesys_sfdc_Banned", "True");
    	}
    }
    else if (obj.action == 'PerformSFDCRequest') {
    	_log("PerformSFDCRequest");
    }    
    
    clickToDialNum = "";
}

//PJB: Moved some code that I would have had to move to a function to create the task
function prepareCreateTask(obj, objectIdForActivity)
{
	if (obj.type == "Voice")
	{    
		//BKK removing OOB functionality
		/*
    	var lookupNumber='';
        if (obj.calltype == "Inbound" || obj.calltype == "Internal"  || obj.calltype=="Consult" || obj.calltype=="Conference") {
		    lookupNumber = obj.source;
		    if (obj.role == 'RoleOrigination') {
		        lookupNumber = obj.destination;
		    }
		}
		else if(obj.calltype == "Outbound") {
            lookupNumber = obj.destination;
        }				
		_log("CreateActivity for voice without sfdcObjectId with " + lookupNumber);

        g_WorkspaceConnectorController.findObjectFromANI(lookupNumber, function(o) {
            if (o != null) {
	      		if(o != 'not found' && o != 'multiple found')
	      		{
	      			objectIdForActivity = o.Id;
	      			_log("Id found " + objectIdForActivity);
	      		}
	      		else if(o == 'multiple found')
				{
					_log("Multiple results");
					//find the one with the most recent completed activity and create the task there
					findMostRecentlyCompletedActivity(lookupNumber, false, obj.id, obj);
					return;
				}
            }
            else
            {
            	_log("No results");
            }		
            _log("CreateActivity for connID " + obj.id + " using object " + objectIdForActivity);
            createTask(obj, objectIdForActivity);		            
		});	*/
		_log("prepareCreateTask voice - " + objectIdForActivity);
		createTask(obj, objectIdForActivity);
		clickToDialNum = "";
		resetActiveInteraction();
		return;
	}

    _log("CreateActivity for connID " + obj.id + " using object " + objectIdForActivity);

    // create the task
    createTask(obj, objectIdForActivity);
}

////////////////////////////////////////////////////////////////////////////////////////
// Inbound and Outbound Voice handling
////////////////////////////////////////////////////////////////////////////////////////

function performVoiceScreenpopAction(obj){
	_log("in performVoiceScreenpopAction()");
	//if this is from a click to dial, then just save the interaction id
	var SFinteraction = (obj.userData.SFinteraction===undefined) ? "" : obj.userData.SFinteraction;
	if(SFinteraction != ""){
		_log("Click to dial");
		activeInteractionID = obj.id;
		return;
	}
	
	var consult_trans_conf_call = false;
	var request = (obj.userData.IW_RoutingBasedRequestType===undefined) ? "" : obj.userData.IW_RoutingBasedRequestType;
	if(request == "OneStepTransfer" || request == "InitTransfer" || request == "OneStepConference" || request == "InitConference"){
		consult_trans_conf_call = true;
	}
	else consult_trans_conf_call = false;
	_log("consult_trans_conf_call = " + consult_trans_conf_call);
	
	var screenPopObj = "";
	
	//a. Check for transfer/consult/conf
    // 	 If it is then if KVP Connector_NewCaseID is present, then screen pop 
	if(consult_trans_conf_call){
		//orig agent opened a new Case
		_log("voice checking Connector_NewCaseID");
		screenPopObj = (obj.userData.Connector_NewCaseID===undefined) ? "" : obj.userData.Connector_NewCaseID;
	}
	
	//b. If no screen pop, then check KVP Outcome_CaseID
    //   If Outcome_CaseID is present, then screen pop Outcome_CaseID  
	if(screenPopObj == ""){
		_log("voice checking Outcome_CaseID");
		screenPopObj = (obj.userData.Outcome_CaseID===undefined) ? "" : obj.userData.Outcome_CaseID;
	}
	
	//c. If no screen pop, check for transfer/consult/conf
    //   If it is then if KVP sfdcObjectId is present, then screen pop sfdcObjectId
	if(screenPopObj == "" && consult_trans_conf_call){
		//orig agent opened a Contact or Case 
		_log("voice checking sfdcObjectId");
		screenPopObj = (obj.userData.sfdcObjectId===undefined) ? "" : obj.userData.sfdcObjectId;
	}
    
    if(screenPopObj != ""){
    	_log("perform screen pop for " + screenPopObj);
    	Salesforce.screenPop(screenPopObj);
    	activeInteractionID = obj.id;
        var newData = '{"sfdcObjectId":"' + screenPopObj + '","id":"' + activeInteractionID + '"}';
        //Don't need to call sendAttachData, tab tracking will do that
        //Workspace.sendAttachData(newData);
    	return;
    }
    
    //d. If no screen pop, then check KVP TCCS_UTN
    //   If TCCS_UTN is present, then check KVP TCCS_UTN to search for Contact phone fields.
    //   If one Contact is found, then screen pop Contact. 

    screenPopObj = (obj.userData.TCCS_UTN===undefined) ? "" : obj.userData.TCCS_UTN;
    if(screenPopObj == ""){
    	//temp fix for anonymous caller and SD/DT1 has reported a TCCS_UTN in the record_found message
    	screenPopObj = (obj.userData.TCCS_UTN_from_record_found===undefined) ? "" : obj.userData.TCCS_UTN_from_record_found;
    	_log("using TCCS_UTN_from_record_found = " + screenPopObj);
    }
    if(screenPopObj != ""){
    	//check for match
    	_log("call findContactFromANI with TCCS_UTN = " + screenPopObj);
        g_WorkspaceConnectorController.findContactFromANI(screenPopObj, function(o) {
        	if (o != null) {
        		_log("findContactFromANI returns " + o);
        		if(o != 'not found' && o != 'multiple found')
        		{
        	    	Salesforce.screenPop(o.Id);
        	    	activeInteractionID = obj.id;
        	        //var newData = '{"sfdcObjectId":"' + o.Id + '","id":"' + activeInteractionID + '"}';
        	    	return;
        		}
        		else
        		{
        			continueVoiceScreenpopAction(obj);
        			//activeInteractionID = obj.id;
        		    //_log("default search");
        		    //Salesforce.SF_default_search(screenPopObj);
        		}
            }		            
        });
        return;
    }

    continueVoiceScreenpopAction(obj);
    //    activeInteractionID = obj.id;
    //    _log("default search");
    //    Salesforce.SF_default_search(screenPopObj);
}

function continueVoiceScreenpopAction(obj){
	_log("continueVoiceScreenpopAction");
	
	var screenPopObj = (obj.userData.TCCS_UTN===undefined) ? "" : obj.userData.TCCS_UTN;
	
	var SFinteraction = (obj.userData.SFinteraction===undefined) ? "" : obj.userData.SFinteraction;
	var OtherDN = (obj.OtherDN===undefined) ? "" : obj.OtherDN;
	if(OtherDN.length > 10){
		OtherDN = OtherDN.substr(OtherDN.length - 10);
	}
	//e. If no screen pop, then check for outgoing call initiated from Workspace.
    //   If it is then use OtherDN if present to search for Contact (
	//   If 11 digits, the remove the first digit and use that 10 digit DN.
    //   If one Contact is found, then screen pop Contact.
	if(obj.calltype == "Outbound" && SFinteraction == "" && OtherDN != "" ){	
		_log("voice checking OtherDN - " + OtherDN);
        g_WorkspaceConnectorController.findContactFromANI(OtherDN, function(o) {
        	if (o != null) {
        		_log("findContactFromANI returns " + o);
        		if(o != 'not found' && o != 'multiple found')
        		{
        	    	Salesforce.screenPop(o.Id);
        	    	activeInteractionID = obj.id;
        	        //var newData = '{"sfdcObjectId":"' + o.Id + '","id":"' + activeInteractionID + '"}';
        	    	return;
        		}
        		else
        		{
        			//f. If no screen pop, then use TSCCS_UTN in URL for global SF search (sforce.interaction.screenPop):
        		    activeInteractionID = obj.id;
        		    _log("default search");
        		    Salesforce.SF_default_search(screenPopObj);
        		}
            }		            
        });
		return;
	}

    //f. If no screen pop, then use TSCCS_UTN in URL for global SF search
    activeInteractionID = obj.id;
    _log("default search");
    Salesforce.SF_default_search(screenPopObj);
}
 

// screen pop for inbound voice. If role is RoleDestination, then this is inbound, if
// RoleOrigination, then it is an manual outbound dial
function performInboundVoiceAction(obj) {
    _log("in performInboundVoiceAction()");
    

    // determine number to use based on role
    _log("Role is " + obj.role);
    var lookupNumber = obj.source;
    if (obj.role == 'RoleOrigination') {
        lookupNumber = obj.destination;
    }

    // if contains a CaseNumber attached data, pop on it
    if (obj.userData.CaseNumber !== undefined) {
        g_WorkspaceConnectorController.findCaseFromNumber(obj.userData.CaseNumber, function(o) {
            if (o != null) {
                _log("Screen popping CASE record: " + o.Name);
                Workspace.sendFocusChange(o.Id, true);                
                var newData = '{"sfdcObjectId":"' + o.Id + '","id":"' + obj.id + '"}';
                Workspace.sendAttachData(newData);                
            } else {
                _log("No records found with Case Number containing: " + lookupNumber);
            }
        });
    } else {
        if (Salesforce.screenPopUser(obj)) {
            return;
        }

        // using the source attribute locate the contact
        g_WorkspaceConnectorController.findObjectFromANI(lookupNumber, function(o) {
            if (o != null) {
                if (o == 'multiple found' || o == 'not found') {
                    Salesforce.openSearch(lookupNumber, obj.id);
                    return;
                }
                Salesforce.addIxnWindow(obj.id, o.Id);
                //PJB: Had to move screenpop so that it wasn't called while we were still sending events
                Workspace.sendFocusChange(o.Id, true);
                //inform workspace of SFobject id for subsequent use in activity creation and transfer
                var newData = '{"sfdcObjectId":"' + o.Id + '","id":"' + obj.id + '"}';
                Workspace.sendAttachData(newData);			            
            } else {
                _log("No records found with phone field containing: " + lookupNumber);
            }
        });
    }
}

// screen pop for outbound voice
function performOutboundVoiceAction(obj) {
    _log("in performOutboundVoiceAction()");

    if (Salesforce.screenPopUser(obj)) {
        return;
    }

    var lookupNumber = obj.destination;
    // using the destination attribute locate the contact
    g_WorkspaceConnectorController.findObjectFromANI(lookupNumber, function(o) {
        //WorkspaceConnectorController.findContactFromANI(obj.destination,function(o) {
        if (o != null) {
            if (o == 'multiple found' || o == 'not found') {
                Salesforce.openSearch(lookupNumber, obj.id);
                return;
            }
            _log("Screen popping record: " + o.Name);
            //PJB: Had to move screenpop so that it wasn't called while we were still sending events
            Workspace.sendFocusChange(o.Id, true);
            //inform workspace of SFobject id for subsequent use in activity creation and transfer
            var newData = '{"sfdcObjectId":"' + o.Id + '","id":"' + obj.id + '"}';
            Workspace.sendAttachData(newData);
        } else {
            _log("No records found with phone field containing: " + lookupNumber);
        }
    });
}

////////////////////////////////////////////////////////////////////////////////////////
// Email handling
////////////////////////////////////////////////////////////////////////////////////////

// screen pop for email

function performEmailAction(obj) {
    _log("in performEmailAction()");
    if (Salesforce.screenPopUser(obj)) {
        return;
    }
    var lookupContact;
    if(obj.source != undefined && obj.source != '') {
    	lookupContact = obj.source;
    }
    else{
    	if(obj.destination != undefined){
        	var emailAddr = obj.destination;
    		//remove trailing ; or ,
    		var lastChar1 = emailAddr.lastIndexOf(";");
    		var lastChar2 = emailAddr.lastIndexOf(",");
    		if(lastChar1 == (emailAddr.length-1) || lastChar2 == (emailAddr.length-1)){
    			//remove last character
    			emailAddr = emailAddr.slice(0,-1);			
    		}			
    		_log("emailAddr " + emailAddr);
    		lookupContact = emailAddr;
    	}
    }

    g_WorkspaceConnectorController.findContactFromEmailAddress(lookupContact, function(o) {
        if (o != null) {
            //PJB: Had to move screenpop so that it wasn't called while we were still sending events
            Workspace.sendFocusChange(o.Id, true);
            //inform workspace of SFobject id for subsequent use in activity creation and transfer
            var newData = '{"sfdcObjectId":"' + o.Id + '","id":"' + obj.id + '"}';
            Workspace.sendAttachData(newData);
        } else {
            _log("No records found with email address containing: " + lookupContact);
            Salesforce.openSearch("", obj.id);            
        }
    });
}

////////////////////////////////////////////////////////////////////////////////////////
// Chat handling
////////////////////////////////////////////////////////////////////////////////////////

// screen pop for chat
function performChatAction(obj) {
    _log("in performChatAction()");
    // check for attached data sfdcObjectId - if it is already there, then pop that
    if (Salesforce.screenPopUser(obj)) {
        return;
    }

    var name = obj.source;

    // using the source attribute locate the contact
    g_WorkspaceConnectorController.findContactFromChatAddress(name, function(o) {
        if (o != null) {
            //PJB: Had to move screenpop so that it wasn't called while we were still sending events
            Workspace.sendFocusChange(o.Id, true);
            //inform workspace of SFobject id for subsequent use in activity creation and transfer
            var newData = '{"sfdcObjectId":"' + o.Id + '","id":"' + obj.id + '"}';
            Workspace.sendAttachData(newData);
        } else {
            _log("performChatAction: No records found with Name containing: " + name);
        }
    });
}


////////////////////////////////////////////////////////////////////////////////////////
// WorkItem handling
////////////////////////////////////////////////////////////////////////////////////////

// screen pop for WorkItem
function performWorkItemAction(obj) {
    _log("in performWorkItemAction()");
    // check for attached data sfdcObjectId - if it is already there, then pop that
    //TODO - do we need this?
    if (Salesforce.screenPopUser(obj)) {
        return;
    }

    var screenPopOccured = "false";
    var screenPopObj = (obj.userData.Outcome_CaseID===undefined) ? "" : obj.userData.Outcome_CaseID;
    if(screenPopObj != ""){
    	_log("using Outcome_CaseID = " + screenPopObj);
    	Salesforce.screenPop(screenPopObj);
    	activeInteractionID = obj.id;
        var newData = '{"sfdcObjectId":"' + screenPopObj + '","id":"' + activeInteractionID + '"}';
        //Workspace.sendAttachData(newData);   
        screenPopOccured = "true";
    }
    
    screenPopObj = (obj.userData.Outcome_TaskID===undefined) ? "" : obj.userData.Outcome_TaskID;
    if(screenPopObj != ""){
    	_log("using Outcome_TaskID = " + screenPopObj);
    	//task gets focus
    	Salesforce.screenPop(screenPopObj);
    	activeInteractionID = obj.id;
        var newData = '{"sfdcObjectId":"' + screenPopObj + '","id":"' + activeInteractionID + '"}';
        //Workspace.sendAttachData(newData); 
        screenPopOccured = "true";
    }
    
    //default - should not happen
    if(screenPopOccured == "false"){
    	screenPopObj = (obj.userData.TCCS_UTN===undefined) ? "" : obj.userData.TCCS_UTN;
    	activeInteractionID = obj.id;
    	_log("default search");
    	Salesforce.SF_default_search(screenPopObj);
    }
}



////////////////////////////////////////////////////////////////////////////////////////
// Open Media handling
////////////////////////////////////////////////////////////////////////////////////////

// screen pop for OpenMedia
function performOpenMediaAction(obj) {
    _log("in performOpenMediaAction()");
    // check for attached data sfdcObjectId - if it is already there, then pop that
    if (Salesforce.screenPopUser(obj)) {
        return;
    }

    var name = obj.source;

    // using the source attribute locate the contact
    g_WorkspaceConnectorController.findContactFromOpenMediaAddress(name, function(o) {
        if (o != null) {
            //PJB: Had to move screenpop so that it wasn't called while we were still sending events
            Workspace.sendFocusChange(o.Id, true);
            //inform workspace of SFobject id for subsequent use in activity creation and transfer
            var newData = '{"sfdcObjectId":"' + o.Id + '","id":"' + obj.id + '"}';
            Workspace.sendAttachData(newData);
        } else {
            _log("performOpenMediaAction: No records found with Name containing: " + name);
        }
    });
}


////////////////////////////////////////////////////////////////////////////////////////
// Case handling
////////////////////////////////////////////////////////////////////////////////////////

/*
 Opens an existing Case if MainMenu = 'Existing Ticket'
 or creates a new Case if MainMenu = 'New Ticket'
 */
function performCaseAction(openObj) {
    _log("in performCaseAction() with main menu=" + openObj.userData.MainMenu);

    // Existing Ticket
    if (openObj.userData.MainMenu == 'Existing Ticket') {
        _log("Opening an Existing CASE with number: " + openObj.userData.TicketNumber);
        g_WorkspaceConnectorController.findCaseFromNumber(openObj.userData.TicketNumber,
            function(result, event) {
                if (result != null) {
                    _log("found Case.Id=" + result.Id + " (CaseNumber " + result.CaseNumber + ")");
                    //PJB: Had to move screenpop so that it wasn't called while we were still sending events
                    Workspace.sendFocusChange(o.Id, true);
                }
                else {
                    _log('No case found, defaulting to navigator tab for user search');
                    try {
                        // display the CaseNotFound page allowing the user to correct
                        // correct the input case and re-pop.
                        Salesforce.consolePop("apex/WSC_CaseNotFound?CaseNumber=" + openObj.userData.TicketNumber, 
                        	"Case Not Found");
                    } catch (e) {
                        //alert("Error=" + e);
                    }
                }
            });
    }

    // New Ticket
    if (openObj.userData.MainMenu == 'New Ticket') {
        _log("New Ticket requested");
        var displayDate = getDisplayDate();
        var mediaType = (openObj.mediaType === undefined) ? "" : openObj.mediaType;
	    var mapCase = {
	    		"IXN Type" : openObj.type,
	    		"Media Type" : mediaType,
	    		"DATE": displayDate
	    }
	    g_WorkspaceConnectorController.createCase(mapCase, function(result){
	    	_log("createCase result = " + result);
	    	if(result != null && result != 'case not created'){
	            //display the case
	            Salesforce.screenPop(result);
	    	}
	    });
        
        // fetch the product line and product IDs
        var canPop = false;            // indicates if all data attributes available to pop form
        /*
        g_WorkspaceConnectorController.getProductFromName(openObj.userData.FunctionalGroup, function(pl) {
            if (pl != null) {
                g_WorkspaceConnectorController.getProductFromName(openObj.userData.ProductGroup, function (sp) {
                    if (sp != null) {
                        _log("Opening new Product Case for " + openObj.userData.Employer + " using product line: " + openObj.userData.FunctionalGroup + " and product: " + openObj.userData.ProductGroup);
                        // open the New Case page forcing bypass of first two forms with prefilled contacts and products
                        Salesforce.consolePop('apex/Portal_Select_Case_Type?isSaas=true&RecordType=012J0000000CsVB'
                            + '&sto=' + openObj.userData.SoldToSFDCId
                            + '&eu=' + openObj.userData.EndUserSFDCId
                            + '&pl=' + pl.Id
                            + '&sp=' + sp.Id
                            + '&conid=' + openObj.userData.ContactSFDCId,
                            'New Case');
                        canPop = true;        // we have popped
                    }
                });
            }
        });
        */
    }

    // Something Else
    if (openObj.userData.MainMenu == 'Something Else') {
        _log("Something else requested");
        // do nothing
    }
}

////////////////////////////////////////////////////////////////////////////////////////
// Task handling
//
// Writes a simple task from provided disposition information
////////////////////////////////////////////////////////////////////////////////////////

function getDisplayDate() {
    var date = new Date();
    return (date.getMonth() + 1) + '/' + (date.getDate()) + '/' + date.getFullYear()
        + " " + date.getHours() + ':' + date.getMinutes() + ':' + date.getSeconds();
}

function createTask(createObj, objIdForActivity) {
    _log("createTask for " + objIdForActivity);
    var displayDate = (createObj.startDate === undefined) ? getDisplayDate() : createObj.startDate;
    var lookupSource = "";
    //AJH -- Added var callDirection to control subject when createActivity tries to insert Task in g_WorkspaceConnnectorController
    var callDirection = "";
    var ixnType = "";
    var mediaType = "";
    var startDate = createObj.startDate;
    var endDate = createObj.endDate;    
    var transferredFrom = (createObj.transferredFrom===undefined) ? "" : createObj.transferredFrom;
             
	
    _log("createTask for " + createObj.type);
    switch (createObj.type) {
        case "Voice":
            // if outbound then use destination as source
            if (createObj.calltype == "Outbound") {
                lookupSource = createObj.destination;
                //ixnType = "Outbound";
                mediaType = (createObj.mediatype === undefined) ? "" : createObj.mediatype;
                if(createObj.mediatype === undefined || createObj.mediatype === ""){
                	ixnType = "Voice-Outbound Dial";
                    //AJH -- Update callDirection
                    callDirection = "Outbound";
                }
                else ixnType = "Voice-Outbound";
                //AJH -- Update callDirection
                callDirection = "Outbound";
            }
            else {
                if (createObj.role == 'RoleOrigination') {
                    lookupSource = createObj.destination;
                    ixnType = "Voice-Outbound Dial";
                    //AJH -- Update callDirection
                	callDirection = "Outbound";
                }
                else {
                    lookupSource = createObj.source;
                    ixnType = "Voice-Inbound";
                    //AJH -- Update callDirection
                	callDirection = "Inbound";
                }
            }
            break;
        case "Email":        	
        	if(createObj.calltype == "Inbound" && createObj.source != undefined && createObj.source != ''){
        		lookupSource = createObj.source;
        		ixnType = "Email-Inbound";
        	}
        	else if(createObj.calltype == "Outbound" && createObj.destination != undefined && createObj.destination != ''){
        			lookupSource = createObj.destination;
        			ixnType = "Email-Outbound";
				 }
            break;
        case "Chat":
            //lookupSource=createObj.userData.FirstName + ' ' + createObj.userData.LastName
            lookupSource = createObj.source;
            ixnType = createObj.type;
            break;
        case "InteractionWorkItem":
            //lookupSource=createObj.userData.FirstName + ' ' + createObj.userData.LastName
            lookupSource = createObj.source;
            ixnType = createObj.type;
            mediaType = createObj.mediaType;
            break;
        case "OpenMedia":
            //lookupSource=createObj.userData.FirstName + ' ' + createObj.userData.LastName
            lookupSource = createObj.source;
            ixnType = createObj.type;
            mediaType = createObj.mediaType;
            break;
        case "Social":
            lookupSource = createObj.source;
            ixnType = createObj.type;
            break;
        default:
            _log("activity not created for " + createObj.type);
            return;
    }

    if (objIdForActivity != "") {
        _log("createTask: " + ixnType + " using objIdForActivity "
            + objIdForActivity + ", not lookupSource " + lookupSource);
    }
    else {
        _log("createTask: " + ixnType + " using lookupSource "
            + lookupSource + ", not objIdForActivity");
    }

    var _CALL_DURATION = (createObj.duration === undefined) ? "" : createObj.duration;
    var _IXNTYPE = ixnType;
    var _COMMENTS = (createObj.notes === undefined) ? "" : createObj.notes;
    var _DISP = (createObj.userData.DispositionCode === undefined) ? "" : createObj.userData.DispositionCode;
	//AJH -- We will use userData instead of createObj.destination 
	//var _DNIS = (createObj.destination === undefined) ? "" : createObj.destination;
	var _DNIS = (createObj.userData.TCCS_DNIS === undefined)? "" : createObj.userData.TCCS_DNIS ;
	//AJH -- Log the DNIS
	_log("DNIS: " + createObj.destination);
	
    var _GENESYSID = (createObj.id === undefined) ? "" : createObj.id;
    var _ANI = (createObj.source === undefined) ? "" : createObj.source;
    var _SFDC_OBJECT_ID = objIdForActivity;
	
    //AJH -- Added Custom Fields from KVP in Attach Data
	var _ACCOUNT_NUMBER = (createObj.userData.RSV4NL_CUST_ACCOUNTNO === undefined)? "" : createObj.userData.RSV4NL_CUST_ACCOUNTNO;
    var _CALLING_LINE_ID = (createObj.userData.TCCS_ANI === undefined)? "" : createObj.userData.TCCS_ANI;	
    var _CALLTOPIC = (createObj.CallTopic === undefined)? "" : createObj.CallTopic ;
    var _CALLTYPE = (createObj.CallTopicType=== undefined)? "" : createObj.CallTopicType;
     //var _CUST_ID_VERIFIED = (createObj.userData.AUTHENTICATED === undefined)? "" : createObj.userData.AUTHENTICATED;           
    var _GENESYS_CALL_TYPE = (createObj.calltype === undefined)? "" : createObj.calltype;
    var _RSV4NL_LAST_IVR_FUNC = (createObj.userData.RSV4NL_LAST_IVR_FUNC === undefined)? "" : createObj.userData.RSV4NL_LAST_IVR_FUNC; 
    var _SUBSCRIBER_PHONE_NO = (createObj.userData.TCCS_UTN === undefined)? "" : createObj.userData.TCCS_UTN;
    var _TRANSFER_HISTORY = (createObj.userData.TRANSFER_COUNTER === undefined)? "" : createObj.userData.TRANSFER_COUNTER ;
    
    //AJH -- callDirection maps to this var for activityMap
    var _VOICE_CALL_DIRECTION = callDirection;
    
    //Workitem specific
    var _OUTCOME_CASEID = (createObj.userData.Outcome_CaseID === undefined)? "" : createObj.userData.Outcome_CaseID ;
    var _OUTCOME_TASKID = (createObj.userData.Outcome_TaskID === undefined)? "" : createObj.userData.Outcome_TaskID ;
   
    
    //email specific
    var _Attachment_Flag = (createObj.Attachment_Flag === undefined) ? "" : createObj.Attachment_Flag;
    var _EMAIL_DESC = (createObj.emailDescription === undefined) ? "" : createObj.emailDescription;
    if(_EMAIL_DESC != ""){
    	_EMAIL_DESC = "\n" + "***EMAIL***" + _EMAIL_DESC;
    }
    
    var _CHAT_TRANSCRIPT = (createObj.transcript === undefined) ? "" : createObj.transcript;
    if(_CHAT_TRANSCRIPT != ""){
    	_CHAT_TRANSCRIPT = "\n" + "***CHAT***" + "\n" + _CHAT_TRANSCRIPT;
    }
    
    if(_COMMENTS != ""){
    	_COMMENTS = "*** NOTES ***" + "\n" + _COMMENTS;
    }
    if(_EMAIL_DESC != ""){
    		_COMMENTS = "\n" +_COMMENTS + _EMAIL_DESC;
    }
    if(_CHAT_TRANSCRIPT != ""){
    		_COMMENTS = "\n" +_COMMENTS + _CHAT_TRANSCRIPT;
    }

    
    var _SFDC1value = (createObj.SFDC1value === undefined) ? "" : createObj.SFDC1value;
    var _SFDC2value = (createObj.SFDC2value === undefined) ? "" : createObj.SFDC2value;
    var _SFDC3value = (createObj.SFDC3value === undefined) ? "" : createObj.SFDC3value;
    var _SFDC4value = (createObj.SFDC4value === undefined) ? "" : createObj.SFDC4value;
    var _SFDC5value = (createObj.SFDC5value === undefined) ? "" : createObj.SFDC5value;
    var _SFDC1field = (createObj.SFDC1field === undefined) ? "" : createObj.SFDC1field;
    var _SFDC2field = (createObj.SFDC2field === undefined) ? "" : createObj.SFDC2field;
    var _SFDC3field = (createObj.SFDC3field === undefined) ? "" : createObj.SFDC3field;
    var _SFDC4field = (createObj.SFDC4field === undefined) ? "" : createObj.SFDC4field;
    var _SFDC5field = (createObj.SFDC5field === undefined) ? "" : createObj.SFDC5field;

    _log("creating task map");
    var mapActivity = {
    	"Call Duration": _CALL_DURATION,
        "IXN Type": _IXNTYPE,
        "Comments": _COMMENTS,
        "Disposition": _DISP,
		"DNIS": _DNIS,
        "GenesysId": _GENESYSID,
		"ANI": _ANI,
        "sfdc Object Id": _SFDC_OBJECT_ID,
        "SFDC1value": _SFDC1value, "SFDC2value": _SFDC2value, "SFDC3value": _SFDC3value,
        "SFDC4value": _SFDC4value, "SFDC5value": _SFDC5value,
        "SFDC1field": _SFDC1field, "SFDC2field": _SFDC2field, "SFDC3field": _SFDC3field,
        "SFDC4field": _SFDC4field, "SFDC5field": _SFDC5field,
        "Media Type": mediaType,
        "DATE": displayDate, "LOOKUP": lookupSource,
        "StartDate": startDate, "EndDate": endDate,
        "TransferredFrom": transferredFrom,
		//AJH -- Added Custom fields for Activity Record
		"Account Number":_ACCOUNT_NUMBER,
		"Calling Line Id":_CALLING_LINE_ID ,
        "Call Topic":_CALLTOPIC,
		"Call Type":_CALLTYPE,
		"Genesys Call Type":_GENESYS_CALL_TYPE,
		"Subscriber Phone Number":_SUBSCRIBER_PHONE_NO,
        "Last IVR":_RSV4NL_LAST_IVR_FUNC,
		"Transfer history":_TRANSFER_HISTORY,
        //AJH -- Added field for helping create subject in Task creation
        "Voice Call Direction": _VOICE_CALL_DIRECTION,
        "Outcome_CaseId": _OUTCOME_CASEID,
        "Outcome_TaskId": _OUTCOME_TASKID
        //"objId":objIdForActivity
    };
		_log("mapActivity DONE !" + mapActivity);
    
    g_WorkspaceConnectorController.createActivity(mapActivity, function(result, event) {
        _log("createActivity RESULT = " + result);

        if (result != null && result != "not found") {
            _log("redirect to new activity - " + result);
            Salesforce.screenPopRefresh(result);
            if(_Attachment_Flag == 'True'){
            	_log("Get attachment info");
	        	//Attachment info is in the form of :
	        	//	"attachments": [
	            //		{"id":"1", "name":"a.zip", "desc":"file a", "mimeType":"gzip"},
	            //		{"id":"2", "name":"b.zip", "desc":"file b", "mimeType":"gzip"}
	        	//	]
	
	        	var attachmentInfo = createObj.attachments;
	            getAttachment(attachmentInfo,createObj.id,0,result);
            }
        }
        else {
            _log("Could not create task");
        }
    });
}

function getAttachment(arrAttachId,interactionId,idx,myTaskID){
	_log("in getAttachment");
    
    if(arrAttachId.length > idx ){
    	var wsParams = Workspace.getParameters();	
    	var msgJ;
    	if(arrAttachId.length == (idx+1))
    		//final request
    		msgJ = '{"action":"RequestAttachment",' + wsParams.CI_connectionData + ',"actionData":{"id":"' + interactionId + '","attachmentID":"' + arrAttachId[idx].id + '","attachmentName":"' + arrAttachId[idx].name + '","finalRequest":"true"}}';
    	else
    		msgJ = '{"action":"RequestAttachment",' + wsParams.CI_connectionData + ',"actionData":{"id":"' + interactionId + '","attachmentID":"' + arrAttachId[idx].id + '","attachmentName":"' + arrAttachId[idx].name + '"}}';
    	
        this.requestUrl = wsParams.pollUrl + ":" + wsParams.pollPort + "/request=" + msgJ;
        _log("getAttachment url = " + this.requestUrl);
	    $.ajax({
	        url: requestUrl,
	        timeout: 20000,
	        async: true,
	        crossDomain: true,
	        cache: false,
	        //dataType: 'text',
	        dataType: 'jsonp',
	        success: function (data) {
	            // call the callback on retrieval

            	//setup first time call info
    			var attachmentInfo = arrAttachId[idx];
    			attachmentInfo.positionIndex = 0;
    			var attachmentId = null;
    			uploadAttachment(attachmentId,data,attachmentInfo,myTaskID);
    			getAttachment(arrAttachId,interactionId,idx+1,myTaskID);
        	},
	        error: function (xhr, ajaxOptions, thrownError) {
	            if (thrownError == 'timeout')
	                _log("Failed to connect for attachment request");
	            else
	                _log('Request error ' + xhr.status + ' ' + thrownError);
	        }
	    });
    }
}

/*
* Process the attachment data response
*/


var maxStringSize = 6000000;    //Maximum String size is 6,000,000 characters
var maxFileSize =   4350000;    
var chunkSize =      950000;    //Maximum Javascript Remoting message size is 1,000,000 characters


function uploadAttachment(attachmentId,attachmentData,attachmentInfo,myTaskID) {
    var attachmentBody = "";
    var descriptionText = "";
    var nameText = "";
    var mimeType = "";
    var doneUploading = false;
    var positionIndex = attachmentInfo.positionIndex;
    var attachment = (attachmentData.attachment === undefined) ? "" : attachmentData.attachment;
    var fileSize = attachment.length;
    _log("uploadAttachment fileSize = " + fileSize);
    if(fileSize <= positionIndex + chunkSize) {
      attachmentBody = attachment.substring(positionIndex);
      doneUploading = true;
    } else {
      attachmentBody = attachment.substring(positionIndex, positionIndex + chunkSize);
      descriptionText = (attachmentInfo.desc === undefined) ? "" : attachmentInfo.desc;
      nameText = (attachmentInfo.name === undefined) ? "" : attachmentInfo.name;
      mimeType = (attachmentInfo.mimeType === undefined) ? "" : attachmentInfo.mimeType;
    }

    _log("Uploading " + attachmentBody.length + " chars of " + fileSize);
    g_WorkspaceConnectorController.addAttachment(myTaskID,descriptionText,nameText,mimeType,attachmentBody,attachmentId, function(result){
    	_log("addAttachment result = " + result);
    	if(result != null && result != "error") {
        	//OOP = Attachment
          if(result.substring(0,3) == '00P') { 
            if(doneUploading == true) {
              _log("doneUploading");
              //refresh the attachment
              Salesforce.screenPopRefresh(myTaskID);
            } else {
              _log("continueUploading");             
              attachmentInfo.positionIndex += chunkSize; 
              _log("total uploaded so far = " + attachmentInfo.positionIndex);
              uploadAttachment(result,attachmentData,attachmentInfo,myTaskID);
            }
          }
        } else {
          _log("error adding attachment");
        }
      }
    );
  }

var tabId = function tabId(result){
		_log("tabId result = "+result.id);
		sforce.console.refreshPrimaryTabById(result.id,true,function(refreshResult){
			_log("refreshPrimaryTabById result = "+refreshResult.success);
		});
}

////////////////////////////////////////////////////////////////////////////////////////
//Tab handling
//--Added by BKK
//
////////////////////////////////////////////////////////////////////////////////////////

function processTabChangeMessage(sfObjID){
      _log("processTabChangeMessage " + sfObjID);
      //check for case (500) or contact (003)
      //Case opens as sub under Contact Primary tab
      if(activeInteractionID != ""){
            if(sfObjID.substring(0, 3) == "003" ){
                  //check sub tab focus 
                  sforce.console.getFocusedSubtabObjectId(function(subTab) {
                        if(subTab.success == true){
                              _log("processTabChangeMessage sub id = " + subTab.id);
                              if(subTab.id.substring(0, 3) == "500"){
                                var newData = '{"sfdcObjectId":"' + subTab.id + '","id":"' + activeInteractionID + '"}';
                                Workspace.sendAttachData(newData);
                                return;
                              }
                        }
                    var newData = '{"sfdcObjectId":"' + sfObjID + '","id":"' + activeInteractionID + '"}';
                    Workspace.sendAttachData(newData);
                    return;
                  });               
            }
            if(sfObjID.substring(0, 3) == "500" ){
              var newData = '{"sfdcObjectId":"' + sfObjID + '","id":"' + activeInteractionID + '"}';
              Workspace.sendAttachData(newData);
              return;
            }
      }
      else{
            _log("activeInteractionID is blank");
      }
}

function processCTIMessage(messageObj,CI_ConnectionData){
	_log("in processCTIMessage");
	if(messageObj.action == "AttachData"){
		_log("processCTIMessage to AttachData");
		var sfObjID = messageObj.Connector_NewCaseID;
		var newData = '{"Connector_NewCaseID":"' + sfObjID + '","id":"' + activeInteractionID + '"}';
		_log("newData = "+newData);
		Workspace.sendAttachData(newData);
	}
}

function resetActiveInteraction(){
	_log("resetActiveInteraction");
	activeInteractionID = "";	
}

})(window, jQuery, undefined);
