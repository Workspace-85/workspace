// **************************************************************************************************************
// Name:            S2CaseTrigger
// Description:     Trigger for the Case object
// Author(s):       Rahul Badal
// Description:     All trigger logic for Case object
// ************************Version Updates***********************************************************************
//
// Updated Date     Updated By      Update Comments 
//
// **************************************************************************************************************

trigger S2CaseTrigger on Case (after insert, after update, before delete,before insert, before update) 
{
    if(Trigger.isBefore && Trigger.isUpdate)
            {
                // Check for Open Tasks for the cloased Cases
                S2CaseUtil.checkforOpenTask(Trigger.New);
            }
    

}