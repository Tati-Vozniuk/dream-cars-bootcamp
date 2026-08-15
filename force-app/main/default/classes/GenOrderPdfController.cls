public with sharing class GenOrderPdfController {
    public Opportunity opp {get; set; }
    public List<Product2> productsSold {get; set;}
    public Account acc {get; set;}
    public List<OpportunityLineItem> oppLineIt {get; set;}
    public Map<Id, OpportunityLineItem> lineItemByProductId { get; set; }
    public Decimal countTotalMoney {get; set;}

    public GenOrderPdfController() {
        Id oppId = ApexPages.currentPage().getParameters().get('id');

        opp = GetDataForGenOrderButt.getOppForGenButt(oppId);
        productsSold = GetDataForGenOrderButt.getSoldProductsForGennButt(oppId);
        acc = GetDataForGenOrderButt.getOppAccountForGenButt(oppId);
        oppLineIt = GetDataForGenOrderButt.getOppLineItForGenButt(oppId);

        lineItemByProductId = new Map<Id, OpportunityLineItem>();

        for (OpportunityLineItem lineItem : oppLineIt) {
            lineItemByProductId.put(lineItem.Product2Id, lineItem);
        }

        countTotalMoney = GetDataForGenOrderButt.countTotalMoneyToPay(oppLineIt);
    }
}