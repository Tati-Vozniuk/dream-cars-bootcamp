public with sharing class TriggerSettingsService {
    public static Boolean isTriggerActive(String triggerName) {
        Trigger_Setting__mdt setting = Trigger_Setting__mdt.getInstance(triggerName);
        return setting != null && setting.Is_Active__c;
    }
}