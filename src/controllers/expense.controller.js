// ─────────────────────────────────────────────────────────────────────────────
// Expense Controller — CRUD with Filtering
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success, created, error, paginated } = require('../utils/apiResponse');
const { getDateRange, parsePagination } = require('../utils/dateHelpers');
const { notifyGroupMembers } = require('../utils/notification.helper');

// ─── Create Expense ─────────────────────────────────────────────────────────

async function createExpense(req, res) {
  let { amount, description, date, type, categoryId, walletId, billReminderId } =
    req.body;

  // Validation
  if (!amount || amount <= 0) {
    return error(res, 'amount is required and must be positive', 400);
  }

  // If categoryId is missing, attempt to resolve from bill reminder
  if (!categoryId && billReminderId) {
    const reminder = await prisma.billReminder.findUnique({
      where: { id: billReminderId },
      select: { categoryId: true },
    });
    if (reminder?.categoryId) {
      categoryId = reminder.categoryId;
    }
  }

  // If still missing, fall back to a default system category
  if (!categoryId) {
    const fallbackCategory = await prisma.category.findFirst({
      where: {
        OR: [
          { name: { contains: 'Utilities', mode: 'insensitive' } },
          { name: { contains: 'Subscriptions', mode: 'insensitive' } },
          { name: { contains: 'Other', mode: 'insensitive' } },
          { isDefault: true },
        ],
      },
    });
    if (fallbackCategory) {
      categoryId = fallbackCategory.id;
    }
  }

  if (!categoryId) {
    return error(res, 'categoryId is required', 400);
  }

  // Verify category exists
  let category = await prisma.category.findUnique({
    where: { id: categoryId },
  });
  if (!category) {
    // If the provided category wasn't found, fall back to any available category
    const anyCat = await prisma.category.findFirst();
    if (anyCat) {
      categoryId = anyCat.id;
      category = anyCat;
    } else {
      return error(res, 'Category not found', 404);
    }
  }

  const expense = await prisma.expense.create({
    data: {
      amount,
      description: description || null,
      date: date ? new Date(date) : new Date(),
      type: type || 'NON_ROUTINE',
      userId: req.user.id,
      walletId: req.wallet.id,
      categoryId,
      billReminderId: billReminderId || null,
    },
    include: {
      category: { select: { id: true, name: true, icon: true, color: true } },
      user: { select: { id: true, displayName: true, avatarUrl: true } },
    },
  });

  // ── Notify group members if this is a shared wallet expense ──
  if (req.wallet.type === 'SHARED' && req.wallet.groupId) {
    const group = await prisma.sharedGroup.findUnique({
      where: { id: req.wallet.groupId },
      select: { name: true },
    });
    await notifyGroupMembers(prisma, req.wallet.groupId, [req.user.id], {
      type: 'GROUP_EXPENSE_ADDED',
      title: 'New Expense',
      body: `${req.user.displayName} added an expense of Rp ${Number(amount).toLocaleString('id-ID')}${description ? ' — ' + description : ''} in "${group?.name || 'shared group'}"`,
      metadata: {
        groupId: req.wallet.groupId,
        expenseId: expense.id,
        amount: Number(amount),
      },
    });
  }

  return created(res, expense, 'Expense created');
}

// ─── List Expenses (with filters) ───────────────────────────────────────────

async function getExpenses(req, res) {
  const { timeframe, date, type, categoryId, startDate, endDate } = req.query;
  const { page, limit, skip } = parsePagination(req.query);

  // Build the where clause
  const where = {
    walletId: req.wallet.id,
  };

  // Date range filter (custom date range with max 31 days check, like MyBCA)
  if (startDate || endDate) {
    where.date = {};
    if (startDate) {
      where.date.gte = startOfDay(startDate);
    }
    if (endDate) {
      where.date.lte = endOfDay(endDate);
    }
    if (startDate && endDate) {
      const s = new Date(startDate);
      const e = new Date(endDate);
      const diffDays = Math.ceil((e.getTime() - s.getTime()) / (1000 * 60 * 60 * 24));
      if (diffDays > 31) {
        return error(res, 'Rentang tanggal maksimal 31 hari', 400);
      }
    }
  } else if (timeframe === 'all') {
    // Return all transactions for this wallet without date constraints
  } else {
    const targetTimeframe = timeframe || (date ? null : 'monthly');
    if (targetTimeframe) {
      const range = getDateRange(targetTimeframe, date);
      where.date = {
        gte: range.start,
        lte: range.end,
      };
    } else if (date) {
      // Specific date without timeframe defaults to that day
      const range = getDateRange('daily', date);
      where.date = {
        gte: range.start,
        lte: range.end,
      };
    }
  }

  // Expense type filter (ROUTINE / NON_ROUTINE)
  if (type && ['ROUTINE', 'NON_ROUTINE'].includes(type.toUpperCase())) {
    where.type = type.toUpperCase();
  }

  // Category filter
  if (categoryId) {
    where.categoryId = categoryId;
  }

  const [expenses, total] = await Promise.all([
    prisma.expense.findMany({
      where,
      include: {
        category: { select: { id: true, name: true, icon: true, color: true } },
        user: { select: { id: true, displayName: true, avatarUrl: true } },
      },
      orderBy: { date: 'desc' },
      skip,
      take: limit,
    }),
    prisma.expense.count({ where }),
  ]);

  return paginated(res, expenses, { page, limit, total });
}

// ─── Get Single Expense ─────────────────────────────────────────────────────

async function getExpenseById(req, res) {
  const { id } = req.params;

  const expense = await prisma.expense.findUnique({
    where: { id },
    include: {
      category: { select: { id: true, name: true, icon: true, color: true } },
      user: { select: { id: true, displayName: true, avatarUrl: true } },
      wallet: { select: { id: true, name: true, type: true } },
      billReminder: { select: { id: true, title: true } },
    },
  });

  if (!expense) {
    return error(res, 'Expense not found', 404);
  }

  // Verify user has access to this expense's wallet
  if (expense.walletId !== req.wallet.id) {
    return error(res, 'Access denied', 403);
  }

  return success(res, expense);
}

// ─── Update Expense ─────────────────────────────────────────────────────────

async function updateExpense(req, res) {
  const { id } = req.params;
  const { amount, description, date, type, categoryId } = req.body;

  // Verify expense exists and belongs to this wallet
  const existing = await prisma.expense.findUnique({ where: { id } });
  if (!existing) {
    return error(res, 'Expense not found', 404);
  }
  if (existing.walletId !== req.wallet.id) {
    return error(res, 'Access denied', 403);
  }

  // Only the creator can edit (in shared wallets, partner can't edit your expenses)
  if (existing.userId !== req.user.id) {
    return error(res, 'Only the creator can edit this expense', 403);
  }

  // Validate categoryId if provided
  if (categoryId) {
    const category = await prisma.category.findUnique({ where: { id: categoryId } });
    if (!category) {
      return error(res, 'Category not found', 404);
    }
  }

  const expense = await prisma.expense.update({
    where: { id },
    data: {
      ...(amount !== undefined && { amount }),
      ...(description !== undefined && { description }),
      ...(date && { date: new Date(date) }),
      ...(type && { type }),
      ...(categoryId && { categoryId }),
    },
    include: {
      category: { select: { id: true, name: true, icon: true, color: true } },
      user: { select: { id: true, displayName: true, avatarUrl: true } },
    },
  });

  return success(res, expense, 'Expense updated');
}

// ─── Delete Expense ─────────────────────────────────────────────────────────

async function deleteExpense(req, res) {
  const { id } = req.params;

  const existing = await prisma.expense.findUnique({ where: { id } });
  if (!existing) {
    return error(res, 'Expense not found', 404);
  }
  if (existing.walletId !== req.wallet.id) {
    return error(res, 'Access denied', 403);
  }
  if (existing.userId !== req.user.id) {
    return error(res, 'Only the creator can delete this expense', 403);
  }

  await prisma.expense.delete({ where: { id } });

  return success(res, null, 'Expense deleted');
}

module.exports = {
  createExpense,
  getExpenses,
  getExpenseById,
  updateExpense,
  deleteExpense,
};
