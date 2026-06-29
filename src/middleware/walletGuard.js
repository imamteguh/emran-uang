// ─────────────────────────────────────────────────────────────────────────────
// Wallet Guard Middleware — Ownership & Shared Group Membership Verification
// ─────────────────────────────────────────────────────────────────────────────
// Every expense / reminder / analytics endpoint requires a walletId.
// This middleware verifies the authenticated user has access to that wallet
// and attaches `req.wallet` for downstream controllers.
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { error } = require('../utils/apiResponse');

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
    const walletId =
      req.body?.walletId || req.query?.walletId || req.params?.walletId;

    if (!walletId) {
      return error(res, 'walletId is required', 400);
    }

    const wallet = await prisma.wallet.findUnique({
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
