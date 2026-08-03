trigger OpportunityTrigger on Opportunity (after update, before update, before delete, after delete) {

    if (!TriggerSettingsService.isTriggerActive('OpportunityTrigger')) {
        return;
    }

    if (Trigger.isUpdate && Trigger.isAfter) {
        OpportunityTriggerHandler.handleAfterUpdateOpp(Trigger.new, Trigger.oldMap);
        OpportunityTriggerHandler.handleAfterUpdateOppCarStage(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isBefore && Trigger.isUpdate){
        OpportunityTriggerHandler.handleBeforeUpdateCheckCarStatus(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isBefore && Trigger.isDelete){
        OpportunityTriggerHandler.handleBeforeDeleteOpp(Trigger.old);
    }

    if (Trigger.isAfter && Trigger.isDelete) {
        OpportunityTriggerHandler.handleAfterDeleteOpp();
    }
}