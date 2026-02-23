import { Router } from 'express';
import { generateToken } from '../controllers/auth';

const router = Router();

router.post('/token', generateToken);

export default router;