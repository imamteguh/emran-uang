// ─────────────────────────────────────────────────────────────────────────────
// Prisma Client — Serverless-safe Singleton
// ─────────────────────────────────────────────────────────────────────────────
// In serverless environments (Vercel), each invocation may reuse a warm
// container. Without a global singleton, every warm invocation would create
// a NEW PrismaClient → new connection pool → Neon connection exhaustion.
//
// This pattern caches the client on `globalThis` so warm containers reuse
// the same pool. In production Vercel, the global trick isn't needed (each
// function instance gets one client), but it doesn't hurt.
// ─────────────────────────────────────────────────────────────────────────────

const { PrismaClient } = require('@prisma/client');

const globalForPrisma = globalThis;

/** @type {PrismaClient} */
const prisma =
  globalForPrisma.__prisma ??
  new PrismaClient({
    log:
      process.env.NODE_ENV === 'development'
        ? ['query', 'warn', 'error']
        : ['error'],
    datasources: {
      db: { url: process.env.DATABASE_URL },
    },
  });

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.__prisma = prisma;
}

module.exports = prisma;
