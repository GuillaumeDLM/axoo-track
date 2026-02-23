"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateToken = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const db_1 = __importDefault(require("../config/db"));
const generateToken = async (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) {
        res.status(400).json({ error: 'Email and password are required' });
        return;
    }
    try {
        // In a real app, you would hash the password and compare it.
        // Here we find or create the user for demonstration purposes.
        let user = await db_1.default.user.findUnique({ where: { email } });
        if (!user) {
            user = await db_1.default.user.create({
                data: {
                    email,
                    password: password, // Should be hashed!
                }
            });
        }
        else {
            // Check password (simplified)
            if (user.password !== password) {
                res.status(401).json({ error: 'Invalid credentials' });
                return;
            }
        }
        const token = jsonwebtoken_1.default.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET || 'secret', { expiresIn: '1d' });
        res.json({ token, user: { id: user.id, email: user.email } });
    }
    catch (error) {
        console.error('Error generating token:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
exports.generateToken = generateToken;
