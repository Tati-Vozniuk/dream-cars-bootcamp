public with sharing class OpportunityTriggerHandler {
    
    public static List<Id> plannedSalesToRecalc = new List<Id>();

    public static void handleAfterUpdateOpp(List<Opportunity> newList, Map<Id, Opportunity> oldMap){

        List<String> plannedSalesKeyToFind = new List<String>();

        for (Opportunity opp : newList) {

            Opportunity oldOpp = oldMap.get(opp.Id);
            Boolean stageChangedRelevantly = (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') || 
                                             (oldOpp.StageName == 'Closed Won' && opp.StageName != 'Closed Won');
            if(!stageChangedRelevantly){
                continue;
            }
            Date closeDate = opp.CloseDate;
            Integer year = closeDate.year();
            Integer month = closeDate.month();
            plannedSalesKeyToFind.add(calculatePlannedSalesData.createKey(year, month, 'Used'));
            plannedSalesKeyToFind.add(calculatePlannedSalesData.createKey(year, month, 'New'));
        }

        List<Id> plannedSalesToRecalc = new List<Id>();
        if(!plannedSalesKeyToFind.isEmpty()){
            for (Planned_Sales__c ps : [SELECT Id FROM Planned_Sales__c WHERE Unique_Key__c IN :plannedSalesKeyToFind WITH USER_MODE]) {
                plannedSalesToRecalc.add(ps.Id);
            }
        }
        if(!plannedSalesToRecalc.isEmpty()){
            calculatePlannedSalesData.calculatePlannedSalesData(plannedSalesToRecalc);
        }
    }

    public static void handleBeforeDeleteOpp(List<Opportunity> oppToDelete){

        List<String> plannedSalesKeyToFind = new List<String>();

        for (Opportunity opp : oppToDelete) {
            if(opp.StageName == 'Closed Won'){
                Date closeDate = opp.CloseDate;
                Integer year = closeDate.year();
                Integer month = closeDate.month();
                plannedSalesKeyToFind.add(calculatePlannedSalesData.createKey(year, month, 'Used'));
                plannedSalesKeyToFind.add(calculatePlannedSalesData.createKey(year, month, 'New'));
            }
        }

        if(!plannedSalesKeyToFind.isEmpty()){
            for (Planned_Sales__c ps : [SELECT Id FROM Planned_Sales__c WHERE Unique_Key__c IN :plannedSalesKeyToFind WITH USER_MODE]) {
                plannedSalesToRecalc.add(ps.Id);
            }
        }
    }

    public static void handleAfterDeleteOpp(){
        if (!plannedSalesToRecalc.isEmpty()) {
            calculatePlannedSalesData.calculatePlannedSalesData(plannedSalesToRecalc);
        }
    }

    public static void handleAfterUpdateOppCarStage(List<Opportunity> newList, Map<Id, Opportunity> oldMap){

        Map<Id, String> opportunityStatus = new Map<Id, String>();

        Id soldRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sold').getRecordTypeId();

        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(opp.StageName != oldOpp.StageName){
                String status;
                switch on opp.StageName {
                    when 'Contract Sent' {
                        status = 'Reserved';
                    }
                    when 'Closed Won' {
                        status = 'Sold';
                    }
                    when 'Closed Lost' {
                        status = 'Available';
                    }
                    when else {
                        if (oldOpp.StageName == 'Contract Sent') {
                            status = 'Available';
                        }
                    }
                }
                opportunityStatus.put(opp.Id, status);
            }
        }

        if(!opportunityStatus.isEmpty()){
            List<OpportunityLineItem> oppProducts = [SELECT OpportunityId, Product2Id FROM OpportunityLineItem WHERE OpportunityId IN :opportunityStatus.keySet()];

            Map<Id, String> carsToUpdate = new Map<Id, String>();
            for (OpportunityLineItem oppProduct : oppProducts) {
                String status = opportunityStatus.get(oppProduct.OpportunityId);
                if(status != null){
                    carsToUpdate.put(oppProduct.Product2Id, status); 
                }
            }

            if(!carsToUpdate.isEmpty()){
                List<Product2> carsToUpd = [SELECT Id, Car_Status__c, RecordTypeId FROM Product2 WHERE Id IN :carsToUpdate.keySet()];
                List<Id> idsToUpdBookEntry = new List<Id>();
                List<Id> idsToActivateBookEntry = new List<Id>();
                for (Product2 prod : carsToUpd) {
                    prod.Car_Status__c = carsToUpdate.get(prod.Id);
                    if(prod.Car_Status__c == 'Sold'){
                        prod.RecordTypeId = soldRecordTypeId;
                        idsToUpdBookEntry.add(prod.Id);
                    }
                    if(prod.Car_Status__c == 'Available'){
                        idsToActivateBookEntry.add(prod.Id);
                    }
                }
                update carsToUpd;
                if(!idsToUpdBookEntry.isEmpty()){
                    List<PricebookEntry> priceBookEntryToUpd = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2Id IN :idsToUpdBookEntry];
                    if(!priceBookEntryToUpd.isEmpty()){
                        for (PricebookEntry pe : priceBookEntryToUpd) {
                            pe.IsActive = false;
                        }
                        Database.update(priceBookEntryToUpd, AccessLevel.SYSTEM_MODE);
                    }
                }
                if(!idsToActivateBookEntry.isEmpty()){
                    List<PricebookEntry> priceBookEntryToActivate = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2Id IN :idsToActivateBookEntry];
                    for (PricebookEntry pe : priceBookEntryToActivate) {
                        pe.IsActive = true;
                    }
                    Database.update(priceBookEntryToActivate, AccessLevel.SYSTEM_MODE);
                }
            }
        }
    }

    public static void handleBeforeUpdateCheckCarStatus(List<Opportunity> newList, Map<Id, Opportunity> oldMap){
        List<Id> oppToUpdate = new List<Id>();
        for (Opportunity opp : newList) {
            if(opp.StageName != oldMap.get(opp.Id).StageName){
                oppToUpdate.add(opp.Id);
            }
        }

        if(!oppToUpdate.isEmpty()){
            List<OpportunityLineItem> oppLineIt = [SELECT Product2Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId IN :oppToUpdate];

            Map<Id, Set<Id>> carToCheckWithOpp = new Map<Id, Set<Id>>();
            Set<Id> allCarIds = new Set<Id>();

            for (OpportunityLineItem oppProduct : oppLineIt) {
                if(!carToCheckWithOpp.containsKey(oppProduct.OpportunityId)){
                    carToCheckWithOpp.put(oppProduct.OpportunityId, new Set<Id>());
                }
                carToCheckWithOpp.get(oppProduct.OpportunityId).add(oppProduct.Product2Id);
                allCarIds.add(oppProduct.Product2Id);
            }

            if(!allCarIds.isEmpty()){
                List<OpportunityLineItem> owningLineItems = [SELECT Product2Id, OpportunityId, Product2.Car_Status__c
                    FROM OpportunityLineItem WHERE Product2Id IN :allCarIds AND Opportunity.StageName IN ('Contract Sent', 'Closed Won')
                    AND Product2.Car_Status__c IN ('Reserved', 'Sold')];

                Map<Id, Id> carToOwningOpp = new Map<Id, Id>();
                for (OpportunityLineItem li : owningLineItems) {
                    carToOwningOpp.put(li.Product2Id, li.OpportunityId);
                }

                for (Opportunity opp : newList) {
                    if(!oppToUpdate.contains(opp.Id)) continue;

                    Set<Id> carsOnThisOpp = carToCheckWithOpp.get(opp.Id);
                    if(carsOnThisOpp == null) continue;

                    for (Id carId : carsOnThisOpp) {
                        Id owningOppId = carToOwningOpp.get(carId);
                        if(owningOppId != null && owningOppId != opp.Id){
                            opp.StageName.addError(
                                'Warning! This Opportunity has reserved or sold cars. ' +
                                'You are not able to move forward with it, until you remove those cars, or they are back available.'
                            );
                            break;
                        }
                    }
                }
            }
        }
    }
}