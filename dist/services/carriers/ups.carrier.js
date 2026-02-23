"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpsCarrierService = void 0;
class UpsCarrierService {
    id = 'ups';
    async track(trackingNumber) {
        // Simulation de l'appel à l'API UPS
        console.log(`[UPS] Tracking parcel ${trackingNumber}...`);
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 500));
        return {
            trackingNumber,
            status: 'IN_TRANSIT',
            events: [
                {
                    status: 'IN_TRANSIT',
                    location: 'Paris, FR',
                    message: 'Package departed facility',
                    date: new Date()
                },
                {
                    status: 'PENDING',
                    location: 'Lyon, FR',
                    message: 'Package arrived at facility',
                    date: new Date(Date.now() - 86400000) // Yesterday
                }
            ]
        };
    }
}
exports.UpsCarrierService = UpsCarrierService;
