import { CarrierService } from './carrier.interface';
import { UpsCarrierService } from './ups.carrier';
import { ColissimoCarrierService } from './colissimo.carrier';

export class CarrierFactory {
  private static carriers: Map<string, CarrierService> = new Map();

  static {
    // Register available carriers
    this.registerCarrier(new UpsCarrierService());
    this.registerCarrier(new ColissimoCarrierService());
  }

  static registerCarrier(carrier: CarrierService): void {
    this.carriers.set(carrier.id.toLowerCase(), carrier);
  }

  static getCarrier(id: string): CarrierService {
    const carrier = this.carriers.get(id.toLowerCase());
    
    if (!carrier) {
      throw new Error(`Carrier '${id}' is not supported`);
    }
    
    return carrier;
  }

  static getSupportedCarriers(): string[] {
    return Array.from(this.carriers.keys());
  }
}