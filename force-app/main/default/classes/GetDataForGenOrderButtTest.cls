@IsTest
private class GetDataForGenOrderButtTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account', BillingStreet = 'Test Street', BillingCity = 'Rivne', BillingPostalCode = '33000', BillingCountry = 'Ukraine');
        insert acc;

        Id standardPricebookId = Test.getStandardPricebookId();

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = acc.Id, StageName = 'Closed Won', CloseDate = Date.today(), Pricebook2Id = standardPricebookId);
        insert opp;

        Product2 product1 = new Product2(Name = 'Test Car 1', IsActive = true, Brand__c = 'BMW', Model__c = 'X5', VIN_Number__c = 'TESTVIN001', Final_Sale_Price__c = 50000, Mileage__c = 12.0);
        Product2 product2 = new Product2(Name = 'Test Car 2', IsActive = true, Brand__c = 'Audi', Model__c = 'A6', VIN_Number__c = 'TESTVIN002', Final_Sale_Price__c = 40000, Mileage__c = 12.0);
        insert new List<Product2>{ product1, product2 };

        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = standardPricebookId, Product2Id = product1.Id, UnitPrice = 50000, IsActive = true);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = standardPricebookId, Product2Id = product2.Id, UnitPrice = 40000, IsActive = true);
        insert new List<PricebookEntry>{ pbe1, pbe2 };

        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe1.Id, Quantity = 1, UnitPrice = 50000);
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe2.Id, Quantity = 1, UnitPrice = 40000);
        insert new List<OpportunityLineItem>{ oli1, oli2 };
    }

    @IsTest
    static void testGetOppForGenButt() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();

        Opportunity result = GetDataForGenOrderButt.getOppForGenButt(testOpp.Id);

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(testOpp.Id, result.Id);
        System.assertEquals('Test Opportunity', result.Name);
        System.assertEquals('Closed Won', result.StageName);
    }

    @IsTest
    static void testGetOppLineItForGenButt() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();

        List<OpportunityLineItem> result = GetDataForGenOrderButt.getOppLineItForGenButt(testOpp.Id);

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(2, result.size());

        Decimal totalPrice = 0;

        for (OpportunityLineItem oli : result) {
            totalPrice += oli.TotalPrice;
        }

        System.assertEquals(90000, totalPrice);
    }

    @IsTest
    static void testCountTotalMoneyToPay() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityLineItem> lineItems = GetDataForGenOrderButt.getOppLineItForGenButt(testOpp.Id);

        Decimal expectedTotal = 0;
        for (OpportunityLineItem oli : lineItems) {
            expectedTotal += oli.TotalPrice;
        }

        Test.startTest();

        Decimal result = GetDataForGenOrderButt.countTotalMoneyToPay(lineItems);

        Test.stopTest();

        System.assertEquals(expectedTotal, result);
        System.assertEquals(90000, result);
    }

    @IsTest
    static void testGetSoldProductsForGennButt() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();

        List<Product2> result = GetDataForGenOrderButt.getSoldProductsForGennButt(testOpp.Id);

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(2, result.size());

        Set<String> vins = new Set<String>();

        for (Product2 product : result) {
            vins.add(product.VIN_Number__c);
        }

        System.assert(vins.contains('TESTVIN001'));
        System.assert(vins.contains('TESTVIN002'));
    }

    @IsTest
    static void testGetOppAccountForGenButt() {
        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Test.startTest();

        Account result = GetDataForGenOrderButt.getOppAccountForGenButt(testOpp.Id);

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(testOpp.AccountId, result.Id);
        System.assertEquals('Test Account', result.Name);
        System.assertEquals('Test Street', result.BillingStreet);
        System.assertEquals('Rivne', result.BillingCity);
    }
}