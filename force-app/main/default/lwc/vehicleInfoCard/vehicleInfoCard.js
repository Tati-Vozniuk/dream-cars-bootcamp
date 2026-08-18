import { LightningElement } from 'lwc';
import getVehicleInfo from '@salesforce/apex/SmartCarService.getVehicleInfo';
import getVehicleLocation from '@salesforce/apex/SmartCarService.getVehicleLocation';

export default class VehicleInfoCard extends LightningElement {
    vehicleId = '';
    userId = '';
    vehicleData;
    errorMessage;
    isLoading = false;

    handleVehicleIdChange(event) {
        this.vehicleId = event.target.value;
    }

    handleUserIdChange(event) {
        this.userId = event.target.value;
    }

    get isLocationDisabled() {
        return !this.vehicleId || !this.userId;
    }

    get hasLocation() {
        return this.vehicleData && this.vehicleData.latitude != null && this.vehicleData.longitude != null;
    }

    async handleGetVehicleInfo() {
        if (!this.vehicleId) {
            this.errorMessage = 'Enter Vehicle ID';
            return;
        }
        this.errorMessage = null;

        try {
            const result = await getVehicleInfo({ vehicleId: this.vehicleId });
            this.processResult(result);
        } catch (error) {
            this.handleApexError(error);
        }
    }

    async handleGetVehicleLocation() {
        this.errorMessage = null;

        try {
            const result = await getVehicleLocation({
                vehicleId: this.vehicleId,
                userId: this.userId
            });
            this.processResult(result);
        } catch (error) {
            this.handleApexError(error);
        }
    }

    processResult(result) {
        if (result.isSuccess) {
            this.vehicleData = { ...this.vehicleData, ...result };
            this.errorMessage = null;
        } else {
            this.errorMessage = result.errorMessage;
        }
    }

    handleApexError(error) {
        this.errorMessage = error?.body?.message
            || 'Failed connection to server';
    }
}