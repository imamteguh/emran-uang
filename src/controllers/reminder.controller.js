// ─────────────────────────────────────────────────────────────────────────────
// Reminder Controller — Bill Reminder Management
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success, created, error, paginated } = require('../utils/apiResponse');
const { parsePagination } = require('../utils/dateHelpers');

// ─── Create Reminder ────────────────────────────────────────────────────────

async function createReminder(req, res) {
  const {
    title,
    amount,
    dueDate,
    periodicity,
    categoryId,
    walletId,
    notifyDaysBefore,
    autoLogExpense,
  } = req.body;

  // Validation
  if (!title || !title.trim()) {
    return error(res, 'title is required', 400);
  }
  if (!amount || amount <= 0) {
    return error(res, 'amount is required and must be positive', 400);
  }
  if (!dueDate) {
    return error(res, 'dueDate is required', 400);
  }

  // Validate periodicity
  const validPeriodicities = ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'];
  if (periodicity && !validPeriodicities.includes(periodicity.toUpperCase())) {
    return error(
      res,
      `periodicity must be one of: ${validPeriodicities.join(', ')}`,
      400
    );
  }

  // Validate categoryId if provided
  if (categoryId) {
    const category = await prisma.category.findUnique({ where: { id: categoryId } });
    if (!category) {
      return error(res, 'Category not found', 404);
    }
  }

  const reminder = await prisma.billReminder.create({
    data: {
      title: title.trim(),
      amount,
      dueDate: new Date(dueDate),
      periodicity: periodicity?.toUpperCase() || 'MONTHLY',
      status: 'ACTIVE',
      userId: req.user.id,
      walletId: req.wallet.id,
      categoryId: categoryId || null,
      notifyDaysBefore: notifyDaysBefore ?? 3,
      autoLogExpense: autoLogExpense ?? false,
    },
    include: {
      category: { select: { id: true, name: true, icon: true, color: true } },
      wallet: { select: { id: true, name: true, type: true } },
    },
  });

  return created(res, reminder, 'Bill reminder created');
}

// ─── List Reminders ─────────────────────────────────────────────────────────

async function getReminders(req, res) {
  const { status, upcoming } = req.query;
  const { page, limit, skip } = parsePagination(req.query);

  const where = {
    walletId: req.wallet.id,
  };

  // Status filter
  if (status) {
    const validStatuses = ['ACTIVE', 'SNOOZED', 'COMPLETED', 'CANCELLED'];
    if (validStatuses.includes(status.toUpperCase())) {
      where.status = status.toUpperCase();
    }
  }

  // Upcoming filter — only reminders due within X days
  if (upcoming) {
    const days = parseInt(upcoming, 10) || 7;
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + days);
    where.dueDate = {
      gte: new Date(),
      lte: futureDate,
    };
    where.status = 'ACTIVE';
  }

  const [reminders, total] = await Promise.all([
    prisma.billReminder.findMany({
      where,
      include: {
        category: { select: { id: true, name: true, icon: true, color: true } },
        wallet: { select: { id: true, name: true, type: true } },
      },
      orderBy: { dueDate: 'asc' },
      skip,
      take: limit,
    }),
    prisma.billReminder.count({ where }),
  ]);

  return paginated(res, reminders, { page, limit, total });
}

// ─── Update Reminder ────────────────────────────────────────────────────────

async function updateReminder(req, res) {
  const { id } = req.params;
  const {
    title,
    amount,
    dueDate,
    periodicity,
    status,
    categoryId,
    notifyDaysBefore,
    autoLogExpense,
  } = req.body;

  // Verify reminder exists and belongs to this wallet
  const existing = await prisma.billReminder.findUnique({ where: { id } });
  if (!existing) {
    return error(res, 'Reminder not found', 404);
  }
  if (existing.walletId !== req.wallet.id) {
    return error(res, 'Access denied', 403);
  }
  if (existing.userId !== req.user.id) {
    return error(res, 'Only the creator can edit this reminder', 403);
  }

  // Validate categoryId if provided
  if (categoryId) {
    const category = await prisma.category.findUnique({ where: { id: categoryId } });
    if (!category) {
      return error(res, 'Category not found', 404);
    }
  }

  const reminder = await prisma.billReminder.update({
    where: { id },
    data: {
      ...(title && { title: title.trim() }),
      ...(amount !== undefined && { amount }),
      ...(dueDate && { dueDate: new Date(dueDate) }),
      ...(periodicity && { periodicity: periodicity.toUpperCase() }),
      ...(status && { status: status.toUpperCase() }),
      ...(categoryId !== undefined && { categoryId }),
      ...(notifyDaysBefore !== undefined && { notifyDaysBefore }),
      ...(autoLogExpense !== undefined && { autoLogExpense }),
    },
    include: {
      category: { select: { id: true, name: true, icon: true, color: true } },
      wallet: { select: { id: true, name: true, type: true } },
    },
  });

  return success(res, reminder, 'Reminder updated');
}

// ─── Delete (Cancel) Reminder ───────────────────────────────────────────────

async function deleteReminder(req, res) {
  const { id } = req.params;

  const existing = await prisma.billReminder.findUnique({ where: { id } });
  if (!existing) {
    return error(res, 'Reminder not found', 404);
  }
  if (existing.walletId !== req.wallet.id) {
    return error(res, 'Access denied', 403);
  }
  if (existing.userId !== req.user.id) {
    return error(res, 'Only the creator can cancel this reminder', 403);
  }

  // Soft cancel — keep the record for history
  const reminder = await prisma.billReminder.update({
    where: { id },
    data: { status: 'CANCELLED' },
  });

  return success(res, reminder, 'Reminder cancelled');
}

module.exports = {
  createReminder,
  getReminders,
  updateReminder,
  deleteReminder,
};
