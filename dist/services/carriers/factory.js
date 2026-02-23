"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CarrierFactory = void 0;
const ups_carrier_1 = require("./ups.carrier");
const colissimo_carrier_1 = require("./colissimo.carrier");
class CarrierFactory {
    static carriers = new Map();
    static {
        // Register available carriers
        this.registerCarrier(new ups_carrier_1.UpsCarrierService());
        this.registerCarrier(new colissimo_carrier_1.ColissimoCarrierService());
    }
    static registerCarrier(carrier) {
        this.carriers.set(carrier.id.toLowerCase(), carrier);
    }
    static getCarrier(id) {
        const carrier = this.carriers.get(id.toLowerCase());
        if (!carrier) {
            throw new Error(`Carrier '${id}' is not supported`);
        }
        return carrier;
    }
    static getSupportedCarriers() {
        return Array.from(this.carriers.keys());
    }
}
exports.CarrierFactory = CarrierFactory;
