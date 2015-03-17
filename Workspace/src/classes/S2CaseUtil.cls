// **************************************************************************************************************
// Name:            S2CaseUtility Class
// Description:     Trigger for the Case object
// Author(s):       Rahul Badal
// ************************Version Updates***********************************************************************
//
// Updated Date(Y/M/D)	Updated By      Update Comments 
// 2014/12/03			Thomas Su		Modified logic to take into consideration (1) when attempting to close 
// 										case with open tasks, and (2) valid attempt to close case
//
// **************************************************************************************************************
public class S2CaseUtil {
    
    public static void checkforOpenTask(List<Case> listCase) {
        Map<Id, Task> notClosedTaskMap = new Map<Id, Task>();
        List<Task> taskForCase = new List<Task>();
        List<id> listCaseID = new List<id>();
        
        // retrieve Case record types
        RecordType objRecTypeOpenCase = [Select Id from RecordType where sObjectType = 'Case' and isActive = true and DeveloperName = 'Open_Case' limit 1]; 
        RecordType objRecTypeClosedCase = [Select Id from RecordType where sObjectType = 'Case' and isActive = true and DeveloperName = 'Closed_Case' limit 1]; 
        
        // compile the list of case IDs from the list of cases
        for (Case c :listCase) {
            listCaseID.add(c.id);
        }
        
        // retrieve list of not closed tasks that belong to the list of cases
        taskForCase = [SELECT Id, WhatId FROM Task WHERE WhatId IN :listCaseID AND IsClosed=false];
        
        // create map of the list of not closed tasks, indexed by the task WhatId
        for (Task t : taskForCase) {
            notClosedTaskMap.put(t.WhatId, t);
            system.debug('===== S2CaseUtil.checkforOpenTask(): Open Task' + t);
        }
                    
        for (Case c : listCase) {
            if (notClosedTaskMap.containsKey(c.Id) && c.Auto_Close__c == true) {
                // set case status to open if attempting to close case but there are open tasks
                system.debug('===== S2CaseUtil.checkforOpenTask(): open case in pending close status');
                c.Status = 'Open';
                c.Auto_Close__c = false;
                c.RecordTypeId = objRecTypeOpenCase.Id;
            } else if (notClosedTaskMap.containsKey(c.Id) && c.status == 'Pending Close') {
                // throw error if attempting to set case status to pending close when there are open tasks
                system.debug('===== S2CaseUtil.checkforOpenTask(): atempting to close case with open tasks');
                c.addError('Please complete all the associated Tasks before closing case.');
            } else if (c.Auto_Close__c == true && !notClosedTaskMap.containsKey(c.Id)) {
                // close case if attempting to close case and there are no open tasks
                system.debug('===== S2CaseUtil.checkforOpenTask(): close case');
                c.Status = 'Closed';
                c.RecordTypeId = objRecTypeClosedCase.Id;
                c.Date_Time_Closed__c = System.now();
            }
        } 
    }
}