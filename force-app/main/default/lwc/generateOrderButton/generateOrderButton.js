import { LightningElement, api } from 'lwc';
import OrderPreviewModal from 'c/orderPreviewModal';

export default class GenerateOrderButton extends LightningElement {
    @api recordId;

    async handleOpenModal() {
        const result = await OrderPreviewModal.open({
            size: 'large',
            recordId: this.recordId
        });

        if (result === 'cancelled') {
            console.log('Modal was cancelled');
        }
        // створення Order
    }
}