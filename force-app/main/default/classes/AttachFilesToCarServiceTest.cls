@IsTest
public with sharing class AttachFilesToCarServiceTest {
    @TestSetup
    static void makeData(){
        Case caseToTest = new Case(Status = 'New', Origin = 'Email', Subject = 'testing VIN-QWERTY1KZAW123459 testing');
        insert caseToTest;
        Product2 product = new Product2(Name = 'Test car', Brand__c = 'Audi', Model__c = 'Modellll', VIN_Number__c = 'QWERTY1KZAW123459', Mileage__c = 12.0);
        insert product;
        EmailMessage email = new EmailMessage(ParentId = caseToTest.Id, Subject = 'testing VIN-QWERTY1KZAW123459 testing', FromAddress = 'customer@test.com',
        ToAddress = 'voznuktetana0@gmail.com', TextBody = 'Test email body', Incoming = true);
        insert email;
        Attachment attachment = new Attachment(Name = 'test.pdf', Body = Blob.valueOf('Test PDF content'), ContentType = 'application/pdf', ParentId = email.Id);
        insert attachment;

        Car_Service__c carService = new Car_Service__c(Name = 'Test Car Serv', Date__c = Date.today(), Case__c = caseToTest.Id, Car__c = product.Id);
        insert carService;
    }

    @IsTest
    static void testAttachFilesToCarService(){
        Case caseBef = [SELECT Id FROM Case LIMIT 1];
        Car_Service__c carServ = [SELECT Id FROM Car_Service__c LIMIT 1];

        AttachFilesToCarService.RequestWrapper request = new AttachFilesToCarService.RequestWrapper();
        request.sourceRecordId = caseBef.Id;
        request.targetRecordId = carServ.Id;
        List<AttachFilesToCarService.RequestWrapper> requests = new List<AttachFilesToCarService.RequestWrapper>();
        requests.add(request);

        Test.startTest();
        AttachFilesToCarService.copyFiles(requests);
        Test.stopTest();

        List<Attachment> attachments = [SELECT Id, ParentId FROM Attachment WHERE ParentId = :carServ.Id];
        System.assertEquals(1, attachments.size());
    }
}