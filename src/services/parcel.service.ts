import { CarrierFactory } from './carriers/factory';
import prisma from '../config/db';

export class ParcelService {
  /**
   * Synchronise les informations de suivi d'un colis avec le transporteur
   * et met à jour la base de données.
   */
  async syncTracking(trackingNumber: string, userId: string) {
    const parcel = await prisma.parcel.findUnique({
      where: { 
        trackingNumber,
      }
    });

    if (!parcel) {
      throw new Error('Parcel not found');
    }

    if (parcel.userId !== userId) {
      throw new Error('Unauthorized access to this parcel');
    }

    const carrierService = CarrierFactory.getCarrier(parcel.carrier);
    
    // Appel à l'API du transporteur (simulé)
    const trackingData = await carrierService.track(parcel.trackingNumber);

    // Mise à jour en transaction : on update le colis et on ajoute/met à jour les événements
    await prisma.$transaction(async (tx) => {
      // 1. Mise à jour du statut global du colis
      if (parcel.status !== trackingData.status) {
        await tx.parcel.update({
          where: { id: parcel.id },
          data: { status: trackingData.status }
        });
      }

      // 2. Gestion des événements
      // Pour faire simple dans cet exemple, on insère les événements qui n'existent pas encore
      // Dans la vraie vie, il faudrait peut-être nettoyer ou comparer avec un ID externe
      for (const event of trackingData.events) {
        // On vérifie si un événement similaire existe déjà (même date et status)
        const existingEvent = await tx.trackingEvent.findFirst({
          where: {
            parcelId: parcel.id,
            status: event.status,
            date: event.date
          }
        });

        if (!existingEvent) {
          await tx.trackingEvent.create({
            data: {
              parcelId: parcel.id,
              status: event.status,
              location: event.location,
              message: event.message,
              date: event.date
            }
          });
        }
      }
    });

    // Retourne le colis mis à jour avec ses événements
    return prisma.parcel.findUnique({
      where: { id: parcel.id },
      include: {
        events: {
          orderBy: { date: 'desc' }
        }
      }
    });
  }
}