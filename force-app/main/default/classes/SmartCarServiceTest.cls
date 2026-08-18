@isTest
private class SmartCarServiceTest {

    @isTest
    static void testGetVehicleInfo_Success() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleInfo('test-vehicle-id');
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Expected successful response');
        System.assertEquals('test-vehicle-id', result.vehicleId);
        System.assertEquals('Tesla', result.make);
        System.assertEquals('Model 3', result.model);
        System.assertEquals(2024, result.year);
    }

    @isTest
    static void testGetVehicleInfo_ApiError() {
        Test.setMock(HttpCalloutMock.class, new MockError());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleInfo('invalid-id');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Expected failure response');
        System.assert(result.errorMessage.contains('404'), 'Error message should mention status code');
    }

    @isTest
    static void testGetVehicleInfo_MalformedResponse() {
        Test.setMock(HttpCalloutMock.class, new MockMalformed());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleInfo('test-vehicle-id');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Malformed JSON should be treated as failure');
        System.assert(result.errorMessage.contains('Failed to parse response'));
    }

    @isTest
    static void testGetVehicleInfo_MissingData() {
        Test.setMock(HttpCalloutMock.class, new MockMissingData());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleInfo('test-vehicle-id');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Missing data should be treated as failure');
    }

    @isTest
    static void testGetVehicleInfo_MissingAttributes() {
        Test.setMock(HttpCalloutMock.class, new MockMissingAttributes());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleInfo('test-vehicle-id');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Missing attributes should be treated as failure');
    }

    @isTest
    static void testGetVehicleLocation_Success() {
        Test.setMock(HttpCalloutMock.class, new MockLocationSuccess());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleLocation('test-vehicle-id', 'test-user-id');
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Expected successful response');
        System.assertEquals(37.4292, result.latitude);
        System.assertEquals(-122.1381, result.longitude);
    }

    @isTest
    static void testGetVehicleLocation_ApiError() {
        Test.setMock(HttpCalloutMock.class, new MockError());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleLocation('invalid-id', 'test-user-id');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Expected failure response');
        System.assert(result.errorMessage.contains('404'), 'Error message should mention status code');
    }

    @isTest
    static void testGetVehicleLocation_MalformedResponse() {
        Test.setMock(HttpCalloutMock.class, new MockMalformed());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleLocation('test-vehicle-id', 'test-user-id');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Malformed JSON should be treated as failure');
        System.assert(result.errorMessage.contains('Failed to parse location'));
    }

    @isTest
    static void testGetVehicleLocation_MissingBody() {
        Test.setMock(HttpCalloutMock.class, new MockLocationMissingBody());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleLocation('test-vehicle-id', 'test-user-id');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Missing body should be treated as failure');
    }

    @isTest
    static void testGetVehicleLocation_MissingAttributes() {
        Test.setMock(HttpCalloutMock.class, new MockLocationMissingAttributes());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleLocation('test-vehicle-id', 'test-user-id');
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Missing attributes should be treated as failure');
    }


    private class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data":{"id":"test-vehicle-id","type":"vehicle","attributes":{"make":"Tesla","model":"Model 3","year":2024}}}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"errors":[{"status":"404","title":"Invalid Path"}]}');
            res.setStatusCode(404);
            return res;
        }
    }

    private class MockLocationSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data":{"attributes":{"body":{"latitude":37.4292,"longitude":-122.1381}}}}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockMalformed implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"not_valid_json_structure": true}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockMissingData implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"something":"else"}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockMissingAttributes implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data":{"id":"test-vehicle-id","type":"vehicle"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockLocationMissingBody implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data":{"attributes":{}}}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockLocationMissingAttributes implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data":{}}');
            res.setStatusCode(200);
            return res;
        }
    }
}