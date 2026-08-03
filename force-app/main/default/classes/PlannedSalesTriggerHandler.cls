public with sharing class PlannedSalesTriggerHandler {
    
    public static void handleAfterInsert(Map<Id, Planned_Sales__c> newMap) {
        calculatePlannedSalesData.calculatePlannedSalesData(new List<Id>(newMap.keySet()));
    }

    public static void handleAfterUpdate(List<Planned_Sales__c> newList, Map<Id, Planned_Sales__c> oldMap) {
        List<Id> idsToRecalc = new List<Id>();
        for (Planned_Sales__c ps : newList) {
            Planned_Sales__c oldPs = oldMap.get(ps.Id);
            if (ps.Year__c != oldPs.Year__c || ps.Month__c != oldPs.Month__c || ps.Car_Type__c != oldPs.Car_Type__c) {
                idsToRecalc.add(ps.Id);
            }
        }
        if (!idsToRecalc.isEmpty()) {
            calculatePlannedSalesData.calculatePlannedSalesData(idsToRecalc);
        }
    }
}