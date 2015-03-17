@isTest
private class S2CaseUtil_Test {

    static testMethod void testPendingCloseCaseAutoCloseTrueWithOpenTask() {
        Case testCase = new case();
        testCase.Notification_ID__c = 'test@testmailpleaseignoreTELUS.com';
        testCase.Status = 'Open';
        insert testCase;
        list<case> caseList = new list<case>();
        caseList.add(testCase);
        task testTask1 = new task();
        testTask1.whatid = testCase.id;
        testTask1.Status = 'Open';
        task testTask2 = new task();
        testTask2.whatid = testCase.id;
        testTask2.Status = 'Open';
        list<task> taskList = new list<task>();
        taskList.add(testTask1);
        taskList.add(testTask2);
        insert taskList;
        testTask1.Status = 'Open';
        testTask2.status = 'Completed';
        update taskList;   
        testCase.Status = 'Pending Close';
        testCase.Auto_Close__c = true;
        update testCase;
        S2CaseUtil.checkforOpenTask(caseList);
        System.assertEquals('Open', testCase.Status);
    }

    static testMethod void testUpdatePendingCloseCaseWithOpenTask() {
        Case testCase = new case();
        testcase.Notification_ID__c = 'test@testmailpleaseignoreTELUS.com';
        insert testCase;
        list<case> caselist = new list<case>();
        caselist.add(testCase);
        task testtask1 = new task();
        testtask1.whatid = testcase.id;
        testtask1.Status = 'Open';
        task testtask2 = new task();
        testtask2.whatid = testcase.id;
        testtask2.Status = 'Open';
        list<task> TaskList = new list<task>();
        Tasklist.add(testtask1);
        Tasklist.add(testtask2);
        insert Tasklist;
        testtask1.Status = 'Open';
        testtask2.status = 'Completed';
        update Tasklist;   
        S2CaseUtil.checkforOpenTask(caselist); 
        System.assertEquals(null, testCase.status);
    }

    static testMethod void testCloseCase() {
        Case testCase = new case();
        testCase.Notification_ID__c = 'test@testmailpleaseignoreTELUS.com';
        testCase.Status = 'Open';
        insert testCase;
        list<case> caseList = new list<case>();
        caseList.add(testCase);
        task testTask1 = new task();
        testTask1.whatid = testCase.id;
        testTask1.Status = 'Open';
        task testTask2 = new task();
        testTask2.whatid = testCase.id;
        testTask2.Status = 'Open';
        list<task> taskList = new list<task>();
        taskList.add(testTask1);
        taskList.add(testTask2);
        insert taskList;
        testTask1.Status = 'Completed';
        testTask2.status = 'Completed';
        update taskList;   
        testCase.Status = 'Pending Close';
        testCase.Auto_Close__c = true;
        update testCase;
        S2CaseUtil.checkforOpenTask(caseList);
        System.assertEquals('Closed', testCase.Status);
    }
}