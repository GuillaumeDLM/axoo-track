import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth';
import prisma from '../config/db';
import { ParcelService } from '../services/parcel.service';

const parcelService = new ParcelService();

export const createParcel = async (req: AuthRequest, res: Response): Promise<void> => {
  const { trackingNumber, carrier } = req.body;
  const userId = req.user?.id;

  if (!userId) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  if (!trackingNumber || !carrier) {
    res.status(400).json({ error: 'trackingNumber and carrier are required' });
    return;
  }

  try {
    const parcel = await prisma.parcel.create({
      data: {
        trackingNumber,
        carrier,
        userId,
      }
    });

    res.status(201).json(parcel);
  } catch (error: any) {
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'Parcel with this tracking number already exists' });
    } else {
      console.error('Error creating parcel:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
};

export const getParcels = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user?.id;

  if (!userId) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    const parcels = await prisma.parcel.findMany({
      where: { userId },
      include: {
        events: {
          orderBy: { date: 'desc' }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json(parcels);
  } catch (error) {
    console.error('Error fetching parcels:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getParcel = async (req: AuthRequest, res: Response): Promise<void> => {
  const userId = req.user?.id;
  const { trackingNumber } = req.params;

  if (!userId) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    const updatedParcel = await parcelService.syncTracking(trackingNumber as string, userId);
    res.json(updatedParcel);
  } catch (error: any) {
    console.error(`Error tracking parcel ${trackingNumber}:`, error);
    if (error.message === 'Parcel not found' || error.message === 'Unauthorized access to this parcel') {
       res.status(404).json({ error: 'Parcel not found' });
       return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
};