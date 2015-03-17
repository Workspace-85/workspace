@isTest
private class NoTaskDeletion_Test {
    static Task createTestTask() {
        Task task = new Task();
        task.Subject = 'Follow Up';
        task.Status = 'Not Started';
        task.Priority = 'Medium';
        insert task;
        
        return task;
    }
    
    public static testMethod void testNoTaskDeletionCase() {   
        // Create test task
        Task t = createTestTask();
        
        try {
            // Attempt to delete task
            delete t;
            
            // Fail test if attempt to delete task succeeds
            System.assert(FALSE);
        } catch (Exception e) {
            // Test successful if attempt to delete task fails
            System.assert(TRUE);
        }   
    }
}