public with sharing class GetDataForGenOrderButt {
    public static Opportunity getOppForGenButt(Id oppId){
        return [SELECT Name, CloseDate, AccountId, StageName FROM Opportunity WHERE Id = :oppId];
    }

    public static List<OpportunityLineItem> getOppLineItForGenButt(Id oppId){
        return [SELECT Id, Quantity, TotalPrice, Product2Id FROM OpportunityLineItem WHERE OpportunityId = :oppId];
    }

    public static Decimal countTotalMoneyToPay(List<OpportunityLineItem> oppLineIts){
        Decimal totalMoneyToPay = 0;
        for (OpportunityLineItem oplit : oppLineIts) {
            totalMoneyToPay += oplit.TotalPrice;
        }
        return totalMoneyToPay;
    }

    public static List<Product2> getSoldProductsForGennButt(Id oppId){
        List<OpportunityLineItem> oppLineIt = [SELECT Id, Product2Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId = :oppId];
        List<Id> productsIds = new LIst<Id>();
        for (OpportunityLineItem opl : oppLineIt) {
            productsIds.add(opl.Product2Id);
        }
        return [SELECT Brand__c, Model__c, VIN_Number__c, Final_Sale_Price__c, Sale_Date__c FROM Product2 WHERE Id IN :productsIds];
    }

    public static Account getOppAccountForGenButt(Id oppId){
        Id accId = [SELECT AccountId FROM Opportunity WHERE Id = :oppId LIMIT  1].AccountId;
        return [SELECT Name, BillingStreet, BillingCity, BillingPostalCode, BillingCountry FROM Account WHERE Id = :accId];
    }
}