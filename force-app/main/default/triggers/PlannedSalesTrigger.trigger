trigger PlannedSalesTrigger on Planned_Sales__c (after insert, after update) {

    if (!TriggerSettingsService.isTriggerActive('PlannedSalesTrigger')) {
        return;
    }

    if (Trigger.isInsert) {
        PlannedSalesTriggerHandler.handleAfterInsert(Trigger.newMap);
    }
    
    if (Trigger.isUpdate) {
        PlannedSalesTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}