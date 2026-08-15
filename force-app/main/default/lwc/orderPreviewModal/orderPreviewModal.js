import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class OrderPreviewModal extends LightningModal {
    @api recordId;

    get pdfUrl() {
        return `/apex/GenOrderPDF?id=${this.recordId}`;
    }

    handleCancel() {
        this.close('cancelled');
    }

    handleCreateOrder() {
        // логіка створення Order буде тут пізніше (завтрашня частина)
        console.log('Create Order clicked, Opportunity Id:', this.recordId);
    }
}