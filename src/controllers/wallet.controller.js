// ─────────────────────────────────────────────────────────────────────────────
// Wallet Controller — List user's wallets
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success, error } = require('../utils/apiResponse');

/**
 * Helper to find a wallet and verify user ownership/membership.
 */
async function findAndAuthorizeWallet(walletId, userId) {
  const wallet = await prisma.wallet.findUnique({
    where: { id: walletId },
    include: {
      group: {
        include: {
          members: true,
        },
      },
    },
  });

  if (!wallet) {
    return { wallet: null, errorStatus: 404, errorMessage: 'Wallet not found' };
  }

  if (wallet.type === 'PERSONAL' && wallet.userId !== userId) {
    return { wallet: null, errorStatus: 403, errorMessage: 'Unauthorized to access this wallet' };
  }

  if (wallet.type === 'SHARED') {
    const isMember = wallet.group?.members.some((m) => m.userId === userId);
    if (!isMember) {
      return { wallet: null, errorStatus: 403, errorMessage: 'Unauthorized to access this shared wallet' };
    }
  }

  return { wallet, errorStatus: null, errorMessage: null };
}

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
      monthlyBudget: true,
      createdAt: true,
      _count: { select: { expenses: true, billReminders: true } },
      categoryBudgets: {
        select: {
          id: true,
          categoryId: true,
          amount: true,
        },
      },
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
              monthlyBudget: true,
              createdAt: true,
              _count: { select: { expenses: true, billReminders: true } },
              categoryBudgets: {
                select: {
                  id: true,
                  categoryId: true,
                  amount: true,
                },
              },
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
  const { name, currency, dailyBudget, monthlyBudget } = req.body;

  const { wallet, errorStatus, errorMessage } = await findAndAuthorizeWallet(id, userId);
  if (!wallet) {
    return error(res, errorMessage, errorStatus);
  }

  const updatedWallet = await prisma.wallet.update({
    where: { id },
    data: {
      name: name !== undefined ? name : undefined,
      currency: currency !== undefined ? currency : undefined,
      dailyBudget: dailyBudget !== undefined ? (dailyBudget === null ? null : parseFloat(dailyBudget)) : undefined,
      monthlyBudget: monthlyBudget !== undefined ? (monthlyBudget === null ? null : parseFloat(monthlyBudget)) : undefined,
    },
  });

  return success(res, updatedWallet);
}

/**
 * Get all category budgets for a wallet.
 */
async function getCategoryBudgets(req, res) {
  const { id } = req.params;
  const userId = req.user.id;

  const { wallet, errorStatus, errorMessage } = await findAndAuthorizeWallet(id, userId);
  if (!wallet) {
    return error(res, errorMessage, errorStatus);
  }

  const budgets = await prisma.categoryBudget.findMany({
    where: { walletId: id },
    include: {
      category: {
        select: {
          id: true,
          name: true,
          icon: true,
          color: true,
          isDefault: true,
        },
      },
    },
    orderBy: { createdAt: 'asc' },
  });

  return success(res, budgets);
}

/**
 * Set or update a category budget for a wallet.
 * If amount <= 0, the budget record is removed.
 */
async function setCategoryBudget(req, res) {
  const { id } = req.params;
  const userId = req.user.id;
  const { categoryId, amount } = req.body;

  const { wallet, errorStatus, errorMessage } = await findAndAuthorizeWallet(id, userId);
  if (!wallet) {
    return error(res, errorMessage, errorStatus);
  }

  if (!categoryId) {
    return error(res, 'categoryId is required', 400);
  }

  const parsedAmount = parseFloat(amount);
  if (isNaN(parsedAmount) || parsedAmount < 0) {
    return error(res, 'amount must be a non-negative number', 400);
  }

  const category = await prisma.category.findFirst({
    where: {
      id: categoryId,
      OR: [{ userId: null, isDefault: true }, { userId }],
      isActive: true,
    },
  });
  if (!category) {
    return error(res, 'Category not found or inactive', 404);
  }

  if (parsedAmount === 0) {
    await prisma.categoryBudget.deleteMany({
      where: { walletId: id, categoryId },
    });
    return success(res, { categoryId, amount: 0, walletId: id }, 'Category budget removed');
  }

  const budget = await prisma.categoryBudget.upsert({
    where: {
      walletId_categoryId: {
        walletId: id,
        categoryId,
      },
    },
    create: {
      walletId: id,
      categoryId,
      amount: parsedAmount,
    },
    update: {
      amount: parsedAmount,
    },
    include: {
      category: {
        select: {
          id: true,
          name: true,
          icon: true,
          color: true,
          isDefault: true,
        },
      },
    },
  });

  return success(res, budget, 'Category budget saved');
}

/**
 * Delete a category budget for a wallet.
 */
async function deleteCategoryBudget(req, res) {
  const { id, categoryId } = req.params;
  const userId = req.user.id;

  const { wallet, errorStatus, errorMessage } = await findAndAuthorizeWallet(id, userId);
  if (!wallet) {
    return error(res, errorMessage, errorStatus);
  }

  await prisma.categoryBudget.deleteMany({
    where: { walletId: id, categoryId },
  });

  return success(res, { categoryId, amount: 0, walletId: id }, 'Category budget deleted');
}

module.exports = {
  getWallets,
  updateWallet,
  getCategoryBudgets,
  setCategoryBudget,
  deleteCategoryBudget,
};
