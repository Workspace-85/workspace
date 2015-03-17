@isTest
private class RetrieveNextUtils_Test {
    public static Group createTestGroup() {
        Group g = new Group(Type='Queue',Name='testRetrieveNextCase');
        insert g;
        
        //Make this queue assignable to leads and cases
        List<QueueSobject> qs = new List<QueueSobject>();
        qs.add(new QueueSobject(QueueId=g.Id,SObjectType='Case'));
        insert qs;
        
        return g;
    }
    
    static User createTestUser() {
        User user = new User();
        user.Username = 'please_ignore'+System.currentTimeMillis()+'@test.telus.com';
        user.LastName = 'LastTestName';
        user.Email = 'test@RetrieveNextUtils.com';
        user.alias = 'testAl';
        user.TimeZoneSidKey = 'America/New_York';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = [select id from Profile where Name='System Administrator'].Id;
        user.LanguageLocaleKey = 'en_US';
        insert user;
        //setUser(user);
        
        return user;
    }
    
    public static testMethod void testRetrieveNextCase() {   
        User u = createTestUser();
        Group g = createTestGroup();
        GroupMember gm = new GroupMember(UserOrGroupId=u.Id,GroupId=g.Id);
        insert gm;
        
        Test.startTest(); 
        //We have to runAs so that we don't get a MIXED_DML_EXCEPTION
        System.runAs(u) {
            Case c = new Case(Subject='Test',OwnerId=g.Id);
            c.Notification__c = 'please_ignore@test.telus.com';
            insert c;
            
            Id caseId = RetrieveNextUtils.retrieveNextCase(u.Id);
            System.assertEquals(caseId,c.Id);
            
            Case ownedCase = [select OwnerId from Case where Id=:c.Id];
            System.assertEquals(ownedCase.OwnerId,u.Id);
        }
    }
    
    public static testMethod void testNegativeRetrieveNextCase() {   
        User u = createTestUser();
        Group g = createTestGroup();
        
        Test.startTest(); 
        
        //We have to runAs so that we don't get a MIXED_DML_EXCEPTION
        System.runAs(u) {    
            //Do not insert this user in the queue -- he should not get the case
            Case c = new Case(Subject='Test',OwnerId=g.Id);
            c.Notification__c = 'please_ignore@test.telus.com';
            insert c;
            
            Id caseId = RetrieveNextUtils.retrieveNextCase(u.Id);
            System.assertEquals(caseId,null);
            
            Case ownedCase = [select OwnerId from Case where Id=:c.Id];
            System.assertNotEquals(ownedCase.OwnerId,u.Id);
        }
    }
}