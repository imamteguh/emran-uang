// ─────────────────────────────────────────────────────────────────────────────
// Wallet Guard Middleware — Ownership & Shared Group Membership Verification
// ─────────────────────────────────────────────────────────────────────────────
// Every expense / reminder / analytics endpoint requires a walletId.
// This middleware verifies the authenticated user has access to that wallet
// and attaches `req.wallet` for downstream controllers.
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { error } = require('../utils/apiResponse');

// In-memory cache for wallet lookup to optimize parallel requests
const walletCache = new Map();
const CACHE_TTL = 30 * 1000; // 30 seconds

// Cleanup expired entries periodically
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of walletCache.entries()) {
    if (now > value.expiresAt) {
      walletCache.delete(key);
    }
  }
}, 60000).unref(); // Use unref so it doesn't keep the process alive

/**
 * Extracts `walletId` from req.body, req.query, or req.params and verifies
 * the authenticated user has access.
 *
 * - PERSONAL wallets → `wallet.userId === req.user.id`
 * - SHARED wallets   → user is a SharedGroupMember of `wallet.groupId`
 *
 * On success, attaches `req.wallet` to the request.
 */
async function walletGuard(req, res, next) {
  try {
    let walletId =
      req.body?.walletId || req.query?.walletId || req.params?.walletId;

    // Auto-resolve walletId if resource ID is provided in params
    if (!walletId && req.params?.id) {
      const reminder = await prisma.billReminder.findUnique({
        where: { id: req.params.id },
        select: { walletId: true },
      });
      if (reminder) {
        walletId = reminder.walletId;
      } else {
        const expense = await prisma.expense.findUnique({
          where: { id: req.params.id },
          select: { walletId: true },
        });
        if (expense) {
          walletId = expense.walletId;
        }
      }
    }

    if (!walletId) {
      return error(res, 'walletId is required', 400);
    }

    const now = Date.now();
    let wallet;

    if (walletCache.has(walletId)) {
      const cached = walletCache.get(walletId);
      if (now <= cached.expiresAt) {
        wallet = cached.wallet;
      }
    }

    if (!wallet) {
      wallet = await prisma.wallet.findUnique({
        where: { id: walletId },
        include: {
          group: {
            include: {
              members: {
                select: { userId: true },
              },
            },
          },
        },
      });

      if (wallet) {
        walletCache.set(walletId, {
          wallet,
          expiresAt: now + CACHE_TTL,
        });
      }
    }

    if (!wallet) {
      return error(res, 'Wallet not found', 404);
    }

    const userId = req.user.id;

    // ── PERSONAL wallet ──────────────────────────────────────────────────
    if (wallet.type === 'PERSONAL') {
      if (wallet.userId !== userId) {
        return error(res, 'Access denied to this wallet', 403);
      }
      req.wallet = wallet;
      return next();
    }

    // ── SHARED wallet ────────────────────────────────────────────────────
    if (wallet.type === 'SHARED') {
      if (!wallet.group) {
        return error(res, 'Shared wallet has no associated group', 500);
      }

      if (wallet.group.status !== 'ACTIVE') {
        return error(res, 'This shared group is no longer active', 403);
      }

      const isMember = wallet.group.members.some((m) => m.userId === userId);
      if (!isMember) {
        return error(res, 'Access denied to this shared wallet', 403);
      }

      req.wallet = wallet;
      return next();
    }

    return error(res, 'Unknown wallet type', 400);
  } catch (err) {
    next(err);
  }
}

module.exports = { walletGuard };
