public class SmartCarVehicleWrapper {
    @AuraEnabled public String vehicleId;
    @AuraEnabled public String make;
    @AuraEnabled public String model;
    @AuraEnabled public Integer year;
    @AuraEnabled public Double latitude;
    @AuraEnabled public Double longitude;
    @AuraEnabled public Boolean isSuccess;
    @AuraEnabled public String errorMessage;

    public SmartCarVehicleWrapper() {
        this.isSuccess = true;
    }

    public static SmartCarVehicleWrapper createError(String message) {
        SmartCarVehicleWrapper wrapper = new SmartCarVehicleWrapper();
        wrapper.isSuccess = false;
        wrapper.errorMessage = message;
        return wrapper;
    }
}