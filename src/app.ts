import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth';
import parcelRoutes from './routes/parcels';

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/parcels', parcelRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'Axoo-Track API' });
});

export default app;