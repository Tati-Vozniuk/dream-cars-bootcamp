import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import createOrderWithPdf from '@salesforce/apex/CreateOrderButtonHandler.createOrderFromOpp';

export default class OrderPreviewModal extends LightningModal {
    @api recordId;

    get pdfUrl() {
        return `/apex/GenOrderPDF?id=${this.recordId}`;
    }

    handleCancel() {
        this.close('cancelled');
    }

    async handleCreateOrder() {
        this.isLoading = true;
        try {
            const orderId = await createOrderWithPdf({ oppId: this.recordId });
            this.close({ status: 'success', orderId: orderId });
        } catch (error) {
            console.error('Error creating order:', error);
        } finally {
            this.isLoading = false;
        }
    }
}