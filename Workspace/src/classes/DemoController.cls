public with sharing class DemoController {

   
   public Contact Obj ;
   
    public DemoController(ApexPages.StandardSetController stdSetController) {
             
    }   


    
     public Contact getRecordDetails(){
              Obj= [SELECT FirstName FROM Contact WHERE HomePhone = '(647) 983-3130'];
              return Obj;
       }
    
}