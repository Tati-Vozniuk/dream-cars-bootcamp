public with sharing class SmartCarService {

    private static final String NAMED_CREDENTIAL = 'callout:SmartCar_API';

    @AuraEnabled
    public static SmartCarVehicleWrapper getVehicleInfo(String vehicleId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/v3/vehicles/' + vehicleId);
        req.setMethod('GET');

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                return parseVehicleInfo(res.getBody());
            } else {
                System.debug(LoggingLevel.ERROR, 'SmartCar API error: ' + res.getStatusCode() + ' - ' + res.getBody());
                return SmartCarVehicleWrapper.createError('SmartCar API returned status ' + res.getStatusCode());
            }
        } catch (CalloutException ex) {
            System.debug(LoggingLevel.ERROR, 'Callout exception: ' + ex.getMessage());
            return SmartCarVehicleWrapper.createError('Connection error: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static SmartCarVehicleWrapper getVehicleLocation(String vehicleId, String userId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/v3/vehicles/' + vehicleId + '/signals/location-preciselocation');
        req.setMethod('GET');
        req.setHeader('sc-user-id', userId);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                return parseLocationInfo(res.getBody());
            } else {
                System.debug(LoggingLevel.ERROR, 'SmartCar API error: ' + res.getStatusCode() + ' - ' + res.getBody());
                return SmartCarVehicleWrapper.createError('SmartCar API returned status ' + res.getStatusCode());
            }
        } catch (CalloutException ex) {
            System.debug(LoggingLevel.ERROR, 'Callout exception: ' + ex.getMessage());
            return SmartCarVehicleWrapper.createError('Connection error: ' + ex.getMessage());
        }
    }

    private static SmartCarVehicleWrapper parseVehicleInfo(String jsonBody) {
        SmartCarVehicleWrapper wrapper = new SmartCarVehicleWrapper();
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            Map<String, Object> data = (Map<String, Object>) root.get('data');
            wrapper.vehicleId = (String) data.get('id');

            Map<String, Object> attributes = (Map<String, Object>) data.get('attributes');
            wrapper.make = (String) attributes.get('make');
            wrapper.model = (String) attributes.get('model');
            wrapper.year = (Integer) attributes.get('year');
        } catch (Exception ex) {
            return SmartCarVehicleWrapper.createError('Failed to parse response: ' + ex.getMessage());
        }
        return wrapper;
    }

    private static SmartCarVehicleWrapper parseLocationInfo(String jsonBody) {
        SmartCarVehicleWrapper wrapper = new SmartCarVehicleWrapper();
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            Map<String, Object> data = (Map<String, Object>) root.get('data');
            Map<String, Object> attributes = (Map<String, Object>) data.get('attributes');
            Map<String, Object> body = (Map<String, Object>) attributes.get('body');

            wrapper.latitude = (Double) body.get('latitude');
            wrapper.longitude = (Double) body.get('longitude');
        } catch (Exception ex) {
            return SmartCarVehicleWrapper.createError('Failed to parse location: ' + ex.getMessage());
        }
        return wrapper;
    }
}