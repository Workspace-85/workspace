// **************************************************************************************************************
// Name:            No Task Deletion
// Description:     Trigger for the Task object
// Author(s):       Thomas Su
// Description:     Trigger logic to prevent deletion of task object
// ************************Version Updates***********************************************************************
//
// Updated Date     Updated By      Update Comments 
//
// **************************************************************************************************************

trigger NoTaskDeletion on Task (before delete) {
    for (Task a : Trigger.old)     
        a.addError('Tasks are not allowed to be deleted.');
}