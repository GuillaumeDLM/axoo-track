"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getParcel = exports.getParcels = exports.createParcel = void 0;
const db_1 = __importDefault(require("../config/db"));
const parcel_service_1 = require("../services/parcel.service");
const parcelService = new parcel_service_1.ParcelService();
const createParcel = async (req, res) => {
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
        const parcel = await db_1.default.parcel.create({
            data: {
                trackingNumber,
                carrier,
                userId,
            }
        });
        res.status(201).json(parcel);
    }
    catch (error) {
        if (error.code === 'P2002') {
            res.status(409).json({ error: 'Parcel with this tracking number already exists' });
        }
        else {
            console.error('Error creating parcel:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
};
exports.createParcel = createParcel;
const getParcels = async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    try {
        const parcels = await db_1.default.parcel.findMany({
            where: { userId },
            include: {
                events: {
                    orderBy: { date: 'desc' }
                }
            },
            orderBy: { createdAt: 'desc' }
        });
        res.json(parcels);
    }
    catch (error) {
        console.error('Error fetching parcels:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
exports.getParcels = getParcels;
const getParcel = async (req, res) => {
    const userId = req.user?.id;
    const { trackingNumber } = req.params;
    if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    try {
        const updatedParcel = await parcelService.syncTracking(trackingNumber, userId);
        res.json(updatedParcel);
    }
    catch (error) {
        console.error(`Error tracking parcel ${trackingNumber}:`, error);
        if (error.message === 'Parcel not found' || error.message === 'Unauthorized access to this parcel') {
            res.status(404).json({ error: 'Parcel not found' });
            return;
        }
        res.status(500).json({ error: 'Internal server error' });
    }
};
exports.getParcel = getParcel;
