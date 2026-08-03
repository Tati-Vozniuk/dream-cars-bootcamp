public with sharing class calculatePlannedSalesData {
    
    public static String createKey(Decimal year, Decimal month, String carType){
        return year + '-' + month + '-' + carType; 
    }

    public static void calculatePlannedSalesData(List<Id> plannedSalesIds){
        List<Planned_Sales__c> plannedSalesList = [SELECT Id, Year__c, Month__c, Car_Type__c, Count_of_Cars_Sold__c, Total_Amount_Earned__c 
                                                FROM Planned_Sales__c WHERE Id IN :plannedSalesIds WITH USER_MODE];

        if(!plannedSalesList.isEmpty()){
            Map<String, Planned_Sales__c> salesPlanMap = new Map<String, Planned_Sales__c>();
            Date minDate;
            Date maxDate;
            for (Planned_Sales__c ps : plannedSalesList) {
                ps.Count_of_Cars_Sold__c = 0;
                ps.Total_Amount_Earned__c = 0;
                String key = createKey(ps.Year__c, ps.Month__c, ps.Car_Type__c);
                salesPlanMap.put(key, ps);

                Date startDate = Date.newInstance(Integer.valueOf(ps.Year__c), Integer.valueOf(ps.Month__c), 1);
                Date endDate = startDate.addMonths(1).addDays(-1);

                if((minDate == null) || (minDate > startDate)){
                    minDate = startDate;
                }

                if((maxDate == null) || (maxDate < endDate)){
                    maxDate = endDate;
                }
            }

            List<OpportunityLineItem> opportunityProducts = [SELECT Quantity, TotalPrice, Opportunity.CloseDate, Product2.Condition__c 
                                                            FROM OpportunityLineItem WHERE Opportunity.StageName = 'Closed Won'
                                                            AND Opportunity.CloseDate >= :minDate AND Opportunity.CloseDate <= :maxDate WITH USER_MODE];
            
            for (OpportunityLineItem opportProduct : opportunityProducts) {
                if(opportProduct.Product2 == null || opportProduct.Product2.Condition__c == null){
                    continue;
                }

                Date closeDate = opportProduct.Opportunity.CloseDate;
                String checkKey = createKey(closeDate.year(), closeDate.month(), opportProduct.Product2.Condition__c);

                Planned_Sales__c ps = salesPlanMap.get(checkKey);

                if(ps != null){
                    ps.Count_of_Cars_Sold__c += opportProduct.Quantity;
                    ps.Total_Amount_Earned__c += opportProduct.TotalPrice;
                }
            }

            try {
                update plannedSalesList;
            } catch (DmlException e) {
                throw e;
            }
        }
    }
}