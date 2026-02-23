import { Router } from 'express';
import { createParcel, getParcels, getParcel } from '../controllers/parcels';
import { authenticate } from '../middlewares/auth';

const router = Router();

// All parcel routes require authentication
router.use(authenticate);

router.post('/', createParcel);
router.get('/', getParcels);
router.get('/:trackingNumber', getParcel);

export default router;