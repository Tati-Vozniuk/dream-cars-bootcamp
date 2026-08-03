@IsTest
public with sharing class OpportunityTriggerHandlerTest {
    @TestSetup
    static void makeData(){

        Id standardPricebookId = Test.getStandardPricebookId();

        RecordType forSaleRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2'AND DeveloperName = 'For_Sale' LIMIT 1];

        List<Product2> product2ToAdd = new List<Product2>();
        product2ToAdd.add(new Product2(Name = 'Product 1 Used', IsActive = true, Condition__c = 'Used', RecordTypeId = forSaleRt.Id,
                        Brand__c = 'Brand', Model__c = 'Model', VIN_Number__c = '5FNRL6H50NB123461', Mileage__c = 1000));
        product2ToAdd.add(new Product2(Name = 'Product 2 Used', IsActive = true, Condition__c = 'Used', RecordTypeId = forSaleRt.Id,
                        Brand__c = 'Brand', Model__c = 'Model', VIN_Number__c = '5FNRL6H50NB123462', Mileage__c = 1000));
        product2ToAdd.add(new Product2(Name = 'Product 3 Used', IsActive = true, Condition__c = 'Used', RecordTypeId = forSaleRt.Id,
                        Brand__c = 'Brand', Model__c = 'Model', VIN_Number__c = '5FNRL6H50NB123422', Mileage__c = 1000));
        product2ToAdd.add(new Product2(Name = 'Product 2 New', IsActive = true, Condition__c = 'New', RecordTypeId = forSaleRt.Id,
                        Brand__c = 'Brand', Model__c = 'Model', VIN_Number__c = '5FNRL6H50NB123262', Mileage__c = 1000));

        insert product2ToAdd;

        List<PricebookEntry> priceBookEntryToAdd = new List<PricebookEntry>();

        for (Product2 product : product2ToAdd) {
            PricebookEntry prToAdd = new PricebookEntry( Pricebook2Id = standardPricebookId, Product2Id = product.Id, UnitPrice = 50000, IsActive = true);
            priceBookEntryToAdd.add(prToAdd);
        }

        insert priceBookEntryToAdd;

        Account acc = new Account(Name='Test Account', BillingCity='Lviv');
        insert acc;

        Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acc.Id, StageName='Qualification', CloseDate=Date.newInstance(2026,7,15), Pricebook2Id = standardPricebookId);
        insert opp;

        List<OpportunityLineItem> oli = new List<OpportunityLineItem>();
        for (Integer i = 0; i < 4; i++) {
            PricebookEntry priceBookEnt = priceBookEntryToAdd.get(i);
            oli.add(new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = priceBookEnt.Id, 
            Quantity = 1, UnitPrice = priceBookEnt.UnitPrice));
        }
        insert oli;

        List<Planned_Sales__c> plannedSalesToAdd = new List<Planned_Sales__c>();
        plannedSalesToAdd.add(new Planned_Sales__c(Year__c = 2026, Month__c = 7, Car_Type__c = 'Used', Count_of_Cars_Sold__c = 999,
        Total_Amount_Earned__c = 999999, Unique_Key__c = calculatePlannedSalesData.createKey(2026,7,'Used')));
        plannedSalesToAdd.add(new Planned_Sales__c(Year__c = 2026, Month__c = 7, Car_Type__c = 'New', Count_of_Cars_Sold__c = 999,
        Total_Amount_Earned__c = 999999, Unique_Key__c = calculatePlannedSalesData.createKey(2026,7,'New')));
        insert plannedSalesToAdd;
    }


    @IsTest
    static void testAfterUpdateToClosedWon(){
        Opportunity oppToUpdate = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        Test.startTest();
        oppToUpdate.StageName = 'Closed Won';
        update oppToUpdate;
        Test.stopTest();

        Planned_Sales__c resultNew = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Car_Type__c = 'New' LIMIT 1];
        Planned_Sales__c resultUsed = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Car_Type__c = 'Used' LIMIT 1];

        System.assertEquals(1, resultNew.Count_of_Cars_Sold__c);
        System.assertEquals(50000, resultNew.Total_Amount_Earned__c);
        System.assertEquals(3, resultUsed.Count_of_Cars_Sold__c);
        System.assertEquals(150000, resultUsed.Total_Amount_Earned__c);
    }

    @IsTest
    static void testAfterUpdateToQualification(){
        Opportunity oppToUpdate = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        oppToUpdate.StageName = 'Closed Won';
        update oppToUpdate;
        Test.startTest();
        oppToUpdate.StageName = 'Qualification';
        update oppToUpdate;
        Test.stopTest();

        Planned_Sales__c resultNew = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Car_Type__c = 'New' LIMIT 1];
        Planned_Sales__c resultUsed = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Car_Type__c = 'Used' LIMIT 1];

        System.assertEquals(0, resultNew.Count_of_Cars_Sold__c);
        System.assertEquals(0, resultNew.Total_Amount_Earned__c);
        System.assertEquals(0, resultUsed.Count_of_Cars_Sold__c);
        System.assertEquals(0, resultUsed.Total_Amount_Earned__c);
    }

    @IsTest
    static void testDeleteOpp(){
        Opportunity oppToDelete = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        oppToDelete.StageName = 'Closed Won';
        update oppToDelete;
        
        Test.startTest();
        delete oppToDelete;
        Test.stopTest();

        Planned_Sales__c resultNew = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Car_Type__c = 'New' LIMIT 1];
        Planned_Sales__c resultUsed = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Car_Type__c = 'Used' LIMIT 1];

        System.assertEquals(0, resultNew.Count_of_Cars_Sold__c);
        System.assertEquals(0, resultNew.Total_Amount_Earned__c);
        System.assertEquals(0, resultUsed.Count_of_Cars_Sold__c);
        System.assertEquals(0, resultUsed.Total_Amount_Earned__c);
    }

    @IsTest
    static void testHandleAfterUpdateOppCarStage(){
        Opportunity oppForTest = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        oppForTest.StageName = 'Contract Sent';


        Test.startTest();
        update oppForTest;
        Test.stopTest();


        Integer productStatusReserved = [SELECT COUNT() FROM Product2 WHERE Car_Status__c = 'Reserved'];
        System.assertEquals(4, productStatusReserved);
    }


}