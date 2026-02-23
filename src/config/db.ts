import { PrismaClient } from '@prisma/client';
import "dotenv/config";

const prisma = new PrismaClient({
  datasourceUrl: process.env.DATABASE_URL
});

export default prisma;