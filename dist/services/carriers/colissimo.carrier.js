"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ColissimoCarrierService = void 0;
class ColissimoCarrierService {
    id = 'colissimo';
    async track(trackingNumber) {
        // Simulation de l'appel à l'API Colissimo
        console.log(`[Colissimo] Tracking parcel ${trackingNumber}...`);
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 800));
        return {
            trackingNumber,
            status: 'DELIVERED',
            events: [
                {
                    status: 'DELIVERED',
                    location: 'Boîte aux lettres',
                    message: 'Votre colis a été livré',
                    date: new Date()
                },
                {
                    status: 'OUT_FOR_DELIVERY',
                    location: 'Centre de tri local',
                    message: 'Votre colis est en cours de livraison',
                    date: new Date(Date.now() - 3600000) // 1 hour ago
                }
            ]
        };
    }
}
exports.ColissimoCarrierService = ColissimoCarrierService;
