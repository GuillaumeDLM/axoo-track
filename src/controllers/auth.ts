import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import prisma from '../config/db';

export const generateToken = async (req: Request, res: Response): Promise<void> => {
  const { email, password } = req.body;

  if (!email || !password) {
    res.status(400).json({ error: 'Email and password are required' });
    return;
  }

  try {
    // In a real app, you would hash the password and compare it.
    // Here we find or create the user for demonstration purposes.
    let user = await prisma.user.findUnique({ where: { email } });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email,
          password: password, // Should be hashed!
        }
      });
    } else {
      // Check password (simplified)
      if (user.password !== password) {
        res.status(401).json({ error: 'Invalid credentials' });
        return;
      }
    }

    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: '1d' }
    );

    res.json({ token, user: { id: user.id, email: user.email } });
  } catch (error) {
    console.error('Error generating token:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};