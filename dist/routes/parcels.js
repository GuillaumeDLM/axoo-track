"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const parcels_1 = require("../controllers/parcels");
const auth_1 = require("../middlewares/auth");
const router = (0, express_1.Router)();
// All parcel routes require authentication
router.use(auth_1.authenticate);
router.post('/', parcels_1.createParcel);
router.get('/', parcels_1.getParcels);
router.get('/:trackingNumber', parcels_1.getParcel);
exports.default = router;
