global class g_WorkspaceConnectorController {
     
  

    
    @RemoteAction
    global static Case findCaseFromNumber(String num)
    {
        system.debug('[WSC] findCaseFromNumber using  ' + num);       
        try {
           List<Case> cases = [SELECT CaseNumber FROM Case WHERE CaseNumber= :num];            
           if(!cases.isEmpty()) {
               // return the first case found (should only be one)                            
               for (Case c : cases) {
                   return c;
               } 
           }
        } catch(QueryException e){
            return null; 
        }
        return null; 
    }
 
   

    @RemoteAction
    global static Object findObjectFromANI(String ANI)
    {
        system.debug('*** findObjectFromANIfor '+ANI); 
        Integer listSize = 0; 
        //List<SObject> objList;
        SObject obj_found = null;     
        try{
            
            List<List<SObject>> aobjects = [FIND :ANI IN PHONE FIELDS RETURNING Account];
            if (!aobjects.isEmpty()){
              List<Account> accounts = ((List<Account>)aobjects[0]);
              listSize = accounts.size();
              system.debug('*** accounts listSize = ' + listSize);
              if(listSize > 1){
                    return 'multiple found';
              }
              if(listSize != 0){
                  for (List<SObject> objList : aobjects)
                      for (SObject aobj : objList){
                        obj_found = aobj;
                        system.debug('*** findObjectFromANI account = '+ obj_found.Id);
                  } 
              }
            }                
            

            List<List<SObject>> cobjects = [FIND :ANI IN PHONE FIELDS RETURNING Contact];
            if (!cobjects.isEmpty()){
              List<Contact> contacts= ((List<Contact>)cobjects[0]);
              listSize = contacts.size();
              system.debug('*** contacts listSize = ' + listSize);
              if(listSize > 1){
                    return 'multiple found';
              }
              if(listSize == 1 && obj_found != null){
                    return 'multiple found';
              }
              if(listSize != 0){
                  for (List<SObject> objList : cobjects)
                      for (SObject cobj : objList){
                        obj_found = cobj;
                        system.debug('*** findObjectFromANI contact = '+ obj_found.Id);
                      } 
                  }
            }  
                                   

            List<List<SObject>> lobjects = [FIND :ANI IN PHONE FIELDS RETURNING Lead];
            if (!lobjects.isEmpty()){
              List<Lead> leads= ((List<Lead>)lobjects[0]);
              listSize = leads.size();
              system.debug('*** leads listSize = ' + listSize);              
              if(listSize > 1){
                    return 'multiple found';
              }
              if(listSize == 1 && obj_found != null){
                    return 'multiple found';
              }
              if(listSize != 0){                            
                  for (List<SObject> objList : lobjects)
                      for (SObject lobj: objList){
                        obj_found = lobj;
                        system.debug('*** findObjectFromANI lead= '+obj_found.Id);
                      } 
              }
            }
            
            if(obj_found != null)              
                return obj_found; 
            return 'not found';

        }
        catch(QueryException e){
            return 'not found'; 
        }        
    }
    
    
    @RemoteAction
    global static Object findContactFromANI(String ANI)
    {
        system.debug('*** findContactFromANI '+ANI);       
        try{                                  
            List<List<SObject>> cobjects = [FIND :ANI IN PHONE FIELDS RETURNING Contact];
            Integer listSize = cobjects.size();
            system.debug('*** listSize = ' + listSize);
            if(listSize > 1){
                    return 'multiple found'; //not expected
            }
            if (!cobjects.isEmpty()){
              List<Contact> contacts = ((List<Contact>)cobjects[0]);
              listSize = contacts.size();
              system.debug('*** contacts listSize = ' + listSize);
              if(listSize > 1){
                    return 'multiple found';
              }
              if(listSize == 0){
                  return 'not found';
              }
              for (List<SObject> objList : cobjects)
                  for (SObject cobj : objList){
                    system.debug('*** findContactFromANI contact = '+ cobj.Id);
                    return cobj;
                  } 
            }                
            return null; 

        }
        catch(QueryException e){
            return null; 
        }        
    }

    @RemoteAction
    global static Object findContactFromEmailAddress(String address)
    {
        system.debug('*** findObjectFromEmailAddress' + address);       
        try {
            List<Contact> objects = [select name from contact where email= :address ];
            if (!objects.isEmpty()) {
                  for (Contact obj : objects) {
                    system.debug('*** findContactFromEmailAddress contact = '+ obj.Name);
                    return obj;
                  } 
            }                
            return null; 
        }
        catch(QueryException e){
            return null; 
        }        
    }
    
    @RemoteAction
    global static Object findContactFromChatAddress(String theName)
    {
        system.debug('*** findObjectFromChatAddress' + theName);       
        try {
            List<Contact> objects = [select name from contact where name= :theName];
            if (!objects.isEmpty()) {
                  for (Contact obj : objects) {
                    system.debug('*** findObjectFromChatAddresscontact = '+ obj.Name);
                    return obj;
                  } 
            }                
            return null; 
        }
        catch(QueryException e){
            return null; 
        }        
    }

        
    @RemoteAction
    global static Object findContactFromWorkItemAddress(String theName)
    {
        system.debug('*** findContactFromWorkItemAddress' + theName);       
        try {
            List<Contact> objects = [select name from contact where name= :theName];
            if (!objects.isEmpty()) {
                  for (Contact obj : objects) {
                    system.debug('*** findContactFromWorkItemAddress = '+ obj.Name);
                    return obj;
                  } 
            }                
            return null; 
        }
        catch(QueryException e){
            return null; 
        }        
    }    


    @RemoteAction
    global static Object findContactFromOpenMediaAddress(String theName)
    {
        system.debug('*** findContactFromOpenMediaAddress' + theName);       
        try {
            List<Contact> objects = [select name from contact where name= :theName];
            if (!objects.isEmpty()) {
                  for (Contact obj : objects) {
                    system.debug('*** findContactFromOpenMediaAddress = '+ obj.Name);
                    return obj;
                  } 
            }                
            return null; 
        }
        catch(QueryException e){
            return null; 
        }        
    }
 

    @RemoteAction global static String createActivity(Map<String,String> activityMap){
        system.debug('*** createActivity' );
        String result = 'not found';
        
        //AJH Added in BKK's old code for activityRecordType
        //Code from WorkSpaceConnector - Outcome v2.0
        
        RecordType activityRecordType;
        try {
            activityRecordType = [SELECT Id from RecordType Where SobjectType = 'Task' and DeveloperName = 'Call_Activity_Record_Type'];
        } catch(QueryException e) {
            system.debug('*** QueryException ' + e);
        }            
        
        String ANI = activityMap.get('ANI');
        String lookupSource = activityMap.get('LOOKUP');
        system.debug('*** createActivity for '+lookupSource + ' - ANI = '+ANI);
        system.debug('*** duration = ' + activityMap.get('Call Duration'));
        String callType = activityMap.get('IXN Type');
        String mediaType = activityMap.get('Media Type');
        //AJH -- get Voice Call Direction from activityMap
        String callDx = activityMap.get('Voice Call Direction');
        //AJH -- commenting out OOB subject 
        //String subject = callType + ' ' + mediaType + ' ' + activityMap.get('DATE'); 
        String subject = '';
        if((activityMap.get('Subject') != null)){
            subject = activityMap.get('Subject');
        }
        else {
         subject = callDx + ' call ';
        }
        String TypeOfTask = callDx;
        String objectToUse = '';
        String duration = activityMap.get('Call Duration');
        Integer durationInSecs = Integer.valueOf(duration);
        
        //workitem handling        
        if(callType == 'InteractionWorkItem'){
            subject = 'Pushed Item';
            TypeOfTask = 'Work Item';
            //check for 
            String workitemObj = activityMap.get('Outcome_CaseId');
            if(workitemObj == '')
                workitemObj = activityMap.get('Outcome_TaskId');
            objectToUse = workitemObj;
            system.debug('*** workitemObj = ' + workitemObj);
        }
        String pushedWorkitem = activityMap.get('Outcome_TaskId');
        String pushedItemSubject = '';
        if(pushedWorkitem != ''){
            try{
                Task myTask= [SELECT Subject FROM Task WHERE Id= :pushedWorkitem];
                pushedItemSubject = myTask.Subject;
            }catch(Exception e) {
            system.debug(e); 
            }
        }
        
        DateTime startDate=null;
        try{
            startDate = (activityMap.get('StartDate')=='' && activityMap.get('StartDate')==null) ? null : dateTime.valueOf(activityMap.get('StartDate'));
        }catch(Exception e) {
            system.debug(e); 
        }
        system.debug('*** start date = ' + startDate);

        DateTime endDate=null;
        try{
            endDate = (activityMap.get('EndDate')=='' && activityMap.get('EndDate')==null) ? null : dateTime.valueOf(activityMap.get('EndDate'));
        }catch(Exception e) {
            system.debug(e); 
        }
        
        system.debug('*** end date = ' + endDate);
        
        if(activityMap.get('sfdc Object Id')!= ''){
                system.debug('*** createActivity sfdc Object Id = ' + activityMap.get('sfdc Object Id'));
                objectToUse = activityMap.get('sfdc Object Id');
        }
        /*
        if(objectToUse == ''){
           object objectFromLookup;

            if(callType == 'Email')
            {
                objectFromLookup = findContactFromEmailAddress(lookupSource);
            }
            else if(callType == 'Chat')
            {
                objectFromLookup = findContactFromChatAddress(lookupSource);
            }
            else if(callType == 'InteractionWorkItem')
            {    
                objectFromLookup = findContactFromWorkItemAddress(lookupSource);
            }
            else if(callType == 'OpenMedia')
            {
                objectFromLookup = findContactFromOpenMediaAddress(lookupSource);
            }
            else
            {
                objectFromLookup = findContactFromANI(lookupSource);
            }


          if(objectFromLookup != null && objectFromLookup != 'not found' && objectFromLookup != 'multiple found'){
                    Contact c = (Contact)objectFromLookup;
                    if(c != null){
                        system.debug('*** createActivity c Id = ' + c.Id);
                        objectToUse = c.Id;
                    }
          }

        }
        */
        
        system.debug('*** createActivity for object ' + objectToUse);
        
        String accountPrefix = Schema.SObjectType.Account.getKeyPrefix();
        String contactPrefix = Schema.SObjectType.Contact.getKeyPrefix();
        String leadPrefix = Schema.SObjectType.Lead.getKeyPrefix();        
        //AJH--added for getting Case keyPrefix
        String casePrefix = Schema.SObjectType.Case.getKeyPrefix();
        String taskPrefix = Schema.SObjectType.Task.getKeyPrefix();
        //log it just to see if its 500
        if(casePrefix != '')
            system.debug('*** Case keyPrefix is ' + casePrefix);    
        String prefix = '';
        if(objectToUse != '')
            prefix = objectToUse.substring(0, 3);
        system.debug('*** prefix = '+prefix);
        
        
        

        Task t = new Task (
         
          Type = TypeOfTask,
          Status = 'Completed',
          Subject = subject,
          CallDurationInSeconds = durationInSecs,            
          //Interaction_Type__c = callType,
   
          Description = activityMap.get('Comments'),
          CallDisposition = activityMap.get('Disposition'),
          CallObject = activityMap.get('GenesysId'),
          //AJH -- Added Custom Fields for Activity Creation
          // Commented for Package creation
        /*
          Disposition__c = activityMap.get('Disposition'), 
          Call_Duration__c = activityMap.get('Call Duration'),
          Calling_Line_ID__c = activityMap.get('Calling Line Id'),
          Call_Topic__c = activityMap.get('Call Topic'),
          Call_Type__c = activityMap.get('Call Type'),
          //AJH -- Use Voice only for now, Later will use _IXN_TYPE
          DNIS__c = activityMap.get('DNIS'),
          GenesysId__c = activityMap.get('GenesysId'),
          Last_IVR_Menu__c = activityMap.get('last IVR'),
          TN_Number__c = activityMap.get('Subscriber Phone Number'),
          Transfer_History__c = activityMap.get('transfer history'),
          Activity_Date__c = activityMap.get('DATE'),
          Pushed_Item_ID__c = pushedWorkitem,
          Pushed_Item_Subject__c = pushedItemSubject,
          */
          
          CallType = activityMap.get('Voice Call Direction')
        );      
            
        if(objectToUse == ''){
            //Do nothing
            system.debug('**** objectToUse was blank');    
        }
        else{
            if(prefix == accountPrefix){
              //AJH -- added objectToUse in debug so we can see ID 
              system.debug('*** create task for Account ' + objectToUse);
              t.put('WhatId',objectToUse);
            }
            //AJH -- Check for Case
            else if(prefix == casePrefix){
                system.debug('*** create task for Case ' + objectToUse);
                t.put('WhatId',objectToUse);
            }
            else if(prefix == taskPrefix){
                system.debug('*** create new task using Contact under the current Task ' + objectToUse);
                Task myTask;
                try{
                    myTask= [SELECT WhoId FROM Task WHERE Id= :objectToUse];
                }catch(QueryException e){
                    system.debug('*** QueryException = ' + e);
                }
                if(myTask != null)
                    t.put('WhoId',myTask.WhoId);
            }
            else{
              t.put('WhoId',objectToUse);
                //AJH - Comment for myself -
                //If it is not an Account or a Case then it must be a Who
                //Like a Contact
            }
        }    
        if(prefix == contactPrefix)
        {
          Contact contact;
          try{
            contact = [SELECT AccountId, Id FROM Contact WHERE Id= :objectToUse];
          }catch(QueryException e){
                    system.debug('*** QueryException = ' + e);
          }          
          //AJH -- Added Contact Id for Debug 
          system.debug('*** create task for Contact ' + objectToUse);
          if(contact != null)
            t.put('WhatId',contact.AccountId);
            //AJH - Comment for myself
            //So we already set the WhoId above
            //Here we make sure we set the WhatId to the Account
            //associated to the Contact Id we were passed
        }
                           
        String mySFDCfield = '';
        String mySFDCvalue = '';
        if (activityMap.get('SFDC1field') != '' && (activityMap.get('SFDC1field') != null) && activityMap.get('SFDC1value') != '' && activityMap.get('SFDC1value') != null)
        {
            mySFDCfield = activityMap.get('SFDC1field');
            mySFDCvalue = activityMap.get('SFDC1value');
            system.debug('*** mySFDCfield1 ' + mySFDCfield + ' -- ' + mySFDCvalue);
            t.put(mySFDCfield,mySFDCvalue);
        }
        if (activityMap.get('SFDC2field') != '' && (activityMap.get('SFDC2field') != null) && activityMap.get('SFDC2value') != '' && activityMap.get('SFDC2value') != null)
        {
            mySFDCfield = activityMap.get('SFDC2field');
            mySFDCvalue = activityMap.get('SFDC2value');
            system.debug('*** mySFDCfield2 ' + mySFDCfield + ' -- ' + mySFDCvalue);
            t.put(mySFDCfield,mySFDCvalue);
        }
        if (activityMap.get('SFDC3field') != '' && (activityMap.get('SFDC3field') != null) && activityMap.get('SFDC3value') != '' && activityMap.get('SFDC3value') != null)
        {
            mySFDCfield = activityMap.get('SFDC3field');
            mySFDCvalue = activityMap.get('SFDC3value');
            system.debug('*** mySFDCfield3 ' + mySFDCfield + ' -- ' + mySFDCvalue);
            t.put(mySFDCfield,mySFDCvalue);
        }
        if (activityMap.get('SFDC4field') != '' && (activityMap.get('SFDC4field') != null) && activityMap.get('SFDC4value') != '' && activityMap.get('SFDC4value') != null)
        {
            mySFDCfield = activityMap.get('SFDC4field');
            mySFDCvalue = activityMap.get('SFDC4value');
            system.debug('*** mySFDCfield4 ' + mySFDCfield + ' -- ' + mySFDCvalue);
            t.put(mySFDCfield,mySFDCvalue);
        }
        if (activityMap.get('SFDC5field') != '' && (activityMap.get('SFDC5field') != null) && activityMap.get('SFDC5value') != '' && activityMap.get('SFDC5value') != null)
        {
            mySFDCfield = activityMap.get('SFDC5field');
            mySFDCvalue = activityMap.get('SFDC5value');
            system.debug('*** mySFDCfield5 ' + mySFDCfield + ' -- ' + mySFDCvalue);
            t.put(mySFDCfield,mySFDCvalue);
        }            
          
        //Activity Record Type Attempt to map Call_Activity_Record_Type
       if (activityRecordType != null ) {
        t.RecordTypeId = activityRecordType.Id;
        } else {
            system.debug('*** No activityRecordType');
       }    
            
        try{                        
                insert t;
        }
        catch(QueryException e){
                 return 'not found'; 
        }
        catch(DmlException e){
            t.put('WhatId',objectToUse);
            system.debug('*** Invalid Id provided. Caught DMLException and using this object to create Activity :' + objecttoUse);
            insert t; 
        }
        system.debug('*** Task id = '  +t.Id);
        result = t.Id;
        return result;
     }
     
    @RemoteAction      
    global static String createCase(Map<String,String> caseMap)
    {        
        system.debug('*** createCase');
        String result = 'case not created';
        String ixnType = caseMap.get('IXN Type');
        String mediaType = caseMap.get('Media Type');
        //String subject = ixnType + ' ' + mediaType + ' ' + caseMap.get('DATE'); 
        String subject = 'Inbound Call';
        Case c = new Case (
            Subject = subject,
            Priority = 'Medium',
            Origin = ixnType        
        );
               
        
        try{                        
                insert c;
        }
        catch(QueryException e){
                 return result; 
        }
        system.debug('*** Case id = '  +c.Id);
        result = c.Id;
        return result;
    }  
      
    @RemoteAction      
    global static String addAttachment(String objectId, String descriptionText, String nameText, String mimeType, Blob attachmentBody, String attachmentId)
    {        
        system.debug('*** addAttachment to '+objectId);
        try{           
 
                if(attachmentBody != null) {
                    Attachment att = getAttachment(attachmentId);
                    
                    String newBody = '';
                    if(att.Body != null) {
                        newBody = EncodingUtil.base64Encode(att.Body);
                    }
                    
                    String newAttachmentBody = EncodingUtil.base64Encode(attachmentBody);                    
                    
                    newBody += newAttachmentBody;
                    
                    att.Body = EncodingUtil.base64Decode(newBody);
                    //att.Body = Blob.valueOf(newBody);                    
                    
                    if(attachmentId == null) {
                        system.debug('*** First time through');
                        att.Name = nameText;
                        att.parentId = objectId;
                    }
                    upsert att;
                    return att.Id;
                } else {
                    return 'error';
                }
        }
        catch(QueryException e){
            system.debug('*** addAttachment error ' + e);
            return 'error';
        }
    }
    
    private static Attachment getAttachment(String attId) {
        list<Attachment> attachments = [SELECT Id, Body
                                        FROM Attachment 
                                        WHERE Id =: attId];
        if(attachments.isEmpty()) {
            Attachment a = new Attachment();
            return a;
        } else {
            return attachments[0];
        }
    }

/*
   @RemoteAction
    global static String findAccount(String searchFieldName, String searchFieldValue){
        system.debug('*** findAccount: searchFieldName - ' + searchFieldName +', searchFieldValue - ' + searchFieldValue);
        try{

           String query = 'SELECT Id, Name, Phone FROM Account WHERE ' + searchFieldName  + ' = \'' + searchFieldValue + '\'';
           system.debug('*** findAccount: query = ' + query);            
           List<Account> accounts = Database.query(query);
           //List<Account> accounts = [SELECT Id, Name, Phone FROM Account WHERE Phone = :searchFieldValue]; 
            if (!accounts.isEmpty()){
                Integer listSize = accounts.size();
                if(listSize > 1){
                    return 'multiple found';
                }
                for (Account a : accounts){
                    system.debug('***  Id = ' + a.Id);
                    system.debug('***  Name = '+ a.Name);
                    system.debug('*** Phone = '+ a.Phone);
                    //return json string id  and full name
                    return '{"id":"' + a.Id + '","name":"' + a.Name + '"}';
                }
            }
        }
        catch(QueryException e){
                return 'QueryException ' + e; 
        }
        //check contact
        String query = 'SELECT Id, Name, Phone FROM Contact WHERE ' + searchFieldName  + ' = \'' + searchFieldValue + '\'';
        system.debug('*** findAccount - contact: query = ' + query);            
        List<Contact> contacts = Database.query(query);
        if (!contacts.isEmpty()){
                Integer listSize = contacts.size();
                if(listSize > 1){
                    return 'multiple found';
                }
                for (Contact c: contacts ){
                    system.debug('***  Id = ' + c.Id);
                    system.debug('***  Name = '+ c.Name);
                    system.debug('*** Phone = '+ c.Phone);
                    //return json string id  and full name
                    return '{"id":"' + c.Id + '","name":"' + c.Name + '"}';
                }
            }
        
        return 'not found';
    }    
*/
  
    @RemoteAction
    global static String testConnection()
    {   
        return 'Active';
    }

/*     
    @RemoteAction
    global static String validateObject(String objectToUse)
    {   
        system.debug('*** validateObject: objectToUse - ' + objectToUse);
        String ret = 'not valid';
        String casePrefix = Schema.SObjectType.Case.getKeyPrefix();
        String taskPrefix = Schema.SObjectType.Task.getKeyPrefix();
        String prefix = objectToUse.substring(0, 3);
        if(prefix == casePrefix){
            system.debug('*** checking case');
                    
            if(casePrefix == prefix){
                system.debug('*** Case prefix matches');
                try{
                    Case myCase= [SELECT Id FROM Case WHERE Id= :objectToUse];
                    if(myCase.Id != '')
                        ret = 'valid';                      
                }
                catch(QueryException e){
                    return 'QueryException ' + e; 
                }
            }
        }
        else if(prefix == taskPrefix){
                system.debug('*** Task prefix matches');
                try{
                    Task myTask= [SELECT Id FROM Task WHERE Id= :objectToUse];
                    if(myTask.Id != '')
                        ret = 'valid';                      
                }
                catch(QueryException e){
                    return 'QueryException ' + e; 
                }           
        }
        return ret;
    }
*/    
}