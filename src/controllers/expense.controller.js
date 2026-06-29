// ─────────────────────────────────────────────────────────────────────────────
// Expense Controller — CRUD with Filtering
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success, created, error, paginated } = require('../utils/apiResponse');
const { getDateRange, parsePagination } = require('../utils/dateHelpers');

// ─── Create Expense ─────────────────────────────────────────────────────────

async function createExpense(req, res) {
  const { amount, description, date, type, categoryId, walletId, billReminderId } =
    req.body;

  // Validation
  if (!amount || amount <= 0) {
    return error(res, 'amount is required and must be positive', 400);
  }
  if (!categoryId) {
    return error(res, 'categoryId is required', 400);
  }

  // Verify category exists
  const category = await prisma.category.findUnique({
    where: { id: categoryId },
  });
  if (!category) {
    return error(res, 'Category not found', 404);
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

  return created(res, expense, 'Expense created');
}

// ─── List Expenses (with filters) ───────────────────────────────────────────

async function getExpenses(req, res) {
  const { timeframe, date, type, categoryId } = req.query;
  const { page, limit, skip } = parsePagination(req.query);

  // Build the where clause
  const where = {
    walletId: req.wallet.id,
  };

  // Timeframe filter (daily / monthly / yearly)
  if (timeframe) {
    const range = getDateRange(timeframe, date);
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
