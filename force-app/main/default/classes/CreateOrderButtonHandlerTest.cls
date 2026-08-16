@IsTest
private class CreateOrderButtonHandlerTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = 'Test Street',
            BillingCity = 'Rivne',
            BillingCountry = 'Ukraine'
        );
        insert acc;

        Contact contact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            AccountId = acc.Id
        );
        insert contact;

        Id standardPricebookId = Test.getStandardPricebookId();

        Product2 product = new Product2(Name = 'Test Car', IsActive = true,  Brand__c = 'Audi', Model__c = 'Modellll', VIN_Number__c = 'QWERTY1KZAW123459', Mileage__c = 12.0);
        insert product;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product.Id,
            UnitPrice = 10000,
            IsActive = true
        );
        insert pbe;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = standardPricebookId
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 10000
        );
        insert oli;

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = contact.Id,
            Role = 'Decision Maker',
            IsPrimary = true
        );
        insert ocr;
    }

    @IsTest
    static void testCreateOrderFromOpp() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();

        Id orderId = CreateOrderButtonHandler.createOrderFromOpp(opp.Id);

        Test.stopTest();

        System.assertNotEquals(null, orderId);

        Order createdOrder = [SELECT Id, OrderNumber, AccountId, ContractId, Pricebook2Id, Status, EffectiveDate FROM Order WHERE Id = :orderId];

        System.assertEquals('Draft', createdOrder.Status);

        System.assertNotEquals(null, createdOrder.ContractId);

        Contract createdContract = [SELECT Id, AccountId, Status, StartDate, ContractTerm FROM Contract WHERE Id = :createdOrder.ContractId];

        System.assertEquals(createdOrder.AccountId, createdContract.AccountId);

        System.assertEquals('Draft', createdContract.Status);

        System.assertEquals(12, createdContract.ContractTerm);

        List<OrderItem> orderItems = [SELECT Id, OrderId, Product2Id, Quantity, UnitPrice, PricebookEntryId FROM OrderItem WHERE OrderId = :orderId];

        System.assertEquals(1, orderItems.size());

        System.assertEquals(1, orderItems[0].Quantity);

        System.assertEquals(10000, orderItems[0].UnitPrice);

        List<ContentDocumentLink> fileLinks = [SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility FROM ContentDocumentLink
        WHERE LinkedEntityId = :orderId];

        System.assertEquals(1, fileLinks.size());

        System.assertEquals(orderId, fileLinks[0].LinkedEntityId);

        System.assertEquals('V', fileLinks[0].ShareType);

        ContentVersion pdfFile = [SELECT Id, Title, PathOnClient, ContentDocumentId FROM ContentVersion
         WHERE ContentDocumentId = :fileLinks[0].ContentDocumentId LIMIT 1];

        System.assertEquals('Order_' + createdOrder.OrderNumber + '.pdf', pdfFile.Title);

        System.assertEquals('Order_' + createdOrder.OrderNumber + '.pdf', pdfFile.PathOnClient);
    }

    @IsTest
    static void testCreateOrderWithoutPrimaryContactRole() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        delete [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];

        Test.startTest();

        Id orderId = CreateOrderButtonHandler.createOrderFromOpp(opp.Id);

        Test.stopTest();

        System.assertNotEquals(null, orderId);

        Order createdOrder = [SELECT Id FROM Order WHERE Id = :orderId];

        System.assertEquals(orderId, createdOrder.Id);
    }
}