export interface TrackingEvent {
  status: string;
  location?: string;
  message?: string;
  date: Date;
}

export interface TrackingResult {
  trackingNumber: string;
  status: string;
  events: TrackingEvent[];
}

export interface CarrierService {
  /**
   * Identifiant unique du transporteur (ex: 'ups', 'colissimo')
   */
  readonly id: string;

  /**
   * Récupère le statut de suivi d'un colis depuis l'API du transporteur
   * @param trackingNumber Numéro de suivi du colis
   */
  track(trackingNumber: string): Promise<TrackingResult>;
}