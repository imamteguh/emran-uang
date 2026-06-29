// ─────────────────────────────────────────────────────────────────────────────
// Wallet Controller — List user's wallets
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success } = require('../utils/apiResponse');

/**
 * List all wallets the authenticated user has access to:
 * - Personal wallets (direct ownership)
 * - Shared wallets (via shared group membership)
 */
async function getWallets(req, res) {
  const userId = req.user.id;

  // Personal wallets
  const personalWallets = await prisma.wallet.findMany({
    where: { userId, type: 'PERSONAL' },
    select: {
      id: true,
      name: true,
      type: true,
      currency: true,
      dailyBudget: true,
      createdAt: true,
      _count: { select: { expenses: true, billReminders: true } },
    },
  });

  // Shared wallets via shared group membership
  const groupMembers = await prisma.sharedGroupMember.findMany({
    where: { userId },
    include: {
      group: {
        include: {
          sharedWallets: {
            select: {
              id: true,
              name: true,
              type: true,
              currency: true,
              dailyBudget: true,
              createdAt: true,
              _count: { select: { expenses: true, billReminders: true } },
            },
          },
          members: {
            include: {
              user: {
                select: { id: true, displayName: true, avatarUrl: true },
              },
            },
          },
        },
      },
    },
  });

  const sharedWallets = groupMembers
    .filter((gm) => gm.group.status === 'ACTIVE')
    .flatMap((gm) =>
      gm.group.sharedWallets.map((w) => ({
        ...w,
        group: {
          id: gm.group.id,
          name: gm.group.name,
          members: gm.group.members
            .map((m) => m.user)
            .filter((u) => u.id !== userId),
        },
      }))
    );

  return success(res, {
    personal: personalWallets,
    shared: sharedWallets,
  });
}

/**
 * Update a wallet's details, such as name, currency, or dailyBudget.
 */
async function updateWallet(req, res) {
  const { id } = req.params;
  const userId = req.user.id;
  const { name, currency, dailyBudget } = req.body;
  const { error } = require('../utils/apiResponse');

  // Find the wallet and ensure the user owns it or is part of the group that owns it
  const wallet = await prisma.wallet.findUnique({
    where: { id },
    include: {
      group: {
        include: {
          members: true,
        },
      },
    },
  });

  if (!wallet) {
    return error(res, 'Wallet not found', 404);
  }

  // Access check: Personal wallet must be owned by the user
  if (wallet.type === 'PERSONAL' && wallet.userId !== userId) {
    return error(res, 'Unauthorized to update this wallet', 403);
  }

  // Access check: Shared wallet group status must be active and user must be a member
  if (wallet.type === 'SHARED') {
    const isMember = wallet.group?.members.some((m) => m.userId === userId);
    if (!isMember) {
      return error(res, 'Unauthorized to update this shared wallet', 403);
    }
  }

  const updatedWallet = await prisma.wallet.update({
    where: { id },
    data: {
      name: name !== undefined ? name : undefined,
      currency: currency !== undefined ? currency : undefined,
      dailyBudget: dailyBudget !== undefined ? (dailyBudget === null ? null : parseFloat(dailyBudget)) : undefined,
    },
  });

  return success(res, updatedWallet);
}

module.exports = { getWallets, updateWallet };
