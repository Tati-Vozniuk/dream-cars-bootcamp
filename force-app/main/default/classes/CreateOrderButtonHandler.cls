public with sharing class CreateOrderButtonHandler {
    @AuraEnabled
    public static Id createOrderFromOpp(Id oppId){
            Opportunity opp = [SELECT Id, AccountId, CloseDate, Pricebook2Id FROM Opportunity WHERE Id = :oppId];
            Contract newContract = new Contract();
            newContract.AccountId = opp.AccountId;
            newContract.Status = 'Draft';
            newContract.StartDate = Date.today();
            newContract.ContractTerm = 12;
            insert newContract;

            // newContract.Status = 'Activated';
            // update newContract;

            Order newOrder = new Order();
            newOrder.ContractId = newContract.Id;
            newOrder.AccountId = opp.AccountId;
            newOrder.EffectiveDate = Date.today();
            newOrder.Status = 'Draft';
            newOrder.Pricebook2Id = opp.Pricebook2Id;
            insert newOrder;

            List<OpportunityLineItem> oppLineIt = [SELECT Product2Id, Quantity, UnitPrice, PricebookEntryId FROM OpportunityLineItem WHERE OpportunityId = :oppId];

            List<OrderItem> orderItems = new List<OrderItem>();
            for (OpportunityLineItem oli : oppLineIt) {
                OrderItem oi = new OrderItem();
                oi.OrderId = newOrder.Id;
                oi.Product2Id = oli.Product2Id;
                oi.Quantity = oli.Quantity;
                oi.UnitPrice = oli.UnitPrice;
                oi.PricebookEntryId = oli.PricebookEntryId;
                orderItems.add(oi);
            }
            if (!orderItems.isEmpty()) {
                insert orderItems;
            }

            PageReference pdfPage = Page.GenOrderPDF;
            pdfPage.getParameters().put('id', oppId);
            Blob pdfBlob;
            
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test PDF content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Order_' + newOrder.OrderNumber + '.pdf';
            cv.PathOnClient = 'Order_' + newOrder.OrderNumber + '.pdf';
            cv.VersionData = pdfBlob;
            insert cv;

            ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = insertedCv.ContentDocumentId;
            cdl.LinkedEntityId = newOrder.Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
            return newOrder.Id;
    }
}