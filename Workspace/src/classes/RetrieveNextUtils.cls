// **************************************************************************************************************
// Name:            RetrieveNextUtils Class
// Description:     Get next case from queue
//                  Used to address case assignment race scenarios, where multiple case representatives are assigned the same case
// Author(s):       Thomas Su
// ************************Version Updates***********************************************************************
//
// Updated Date     Updated By      Update Comments 
//
// **************************************************************************************************************

global with sharing class RetrieveNextUtils {
    webService static Id retrieveNextCase(String userId) {
        //Really we're only specifying the user ID for the sake of the test methods
        if (userId=='') {
            //Use the currently running user
            userId = UserInfo.getUserId();
            
            System.debug('>>>>> retrieveNextCase.userId: '+userId);
        }
        
        //First find out which queues this user is a member of
        List<Id> listGroupIds = getQueuesForUser(userId);
        
        System.debug('>>>>> retrieveNextCase.listGroupIds: ' + listGroupIds);
        
        if(listGroupIds.size()>0) {
            //Find an open case that is assigned to one of those queues
            Case caseObj = null;
            Integer count = 0;
            // Atempt to retrieve one single case and lock the record 5 times
            while (caseObj == null && count < 5) {
	            try {
                    caseObj = [select c.Id,c.OwnerId from Case c where
                               c.IsClosed=false and c.OwnerId in :listGroupIds
                               limit 1 
                               for update];
                } catch (Exception e) {
                    //do nothing
                }
                count++;
            }
            if (caseObj!=null) {       
                System.debug('retrieveNextCase.caseObj: ' + caseObj);
                //If we found one, assign it to the current user
                caseObj.OwnerId = userId;
                update caseObj;
                
                return caseObj.Id;
            }
        }
        return null;
    }
       
    //Returns a list of ids of queues that this user is a member of
    public static List<Id> getQueuesForUser(String userId) {
        List<Id> listGroupIds = new List<Id>();
        List<GroupMember> listGroupMembers = [Select g.GroupId From GroupMember g
                                              where g.Group.Type='Queue'
                                              and g.UserOrGroupId=:userId];
        
        if (listGroupMembers!=null && listGroupMembers.size()>0) {     
            for (GroupMember gm:listGroupMembers) {
                System.debug('getQueuesForUser.gm.GroupId: ' + gm.GroupId);
                listGroupIds.add(gm.GroupId);
            }
        }
        return listGroupIds;
    }
}