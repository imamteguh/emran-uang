// ─────────────────────────────────────────────────────────────────────────────
// Reminder Controller — Bill Reminder Management
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success, created, error, paginated } = require('../utils/apiResponse');
const { parsePagination } = require('../utils/dateHelpers');
const { notifyGroupMembers } = require('../utils/notification.helper');

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

  // Validate periodicity: only MONTHLY or YEARLY
  const validPeriodicities = ['MONTHLY', 'YEARLY'];
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
      expenses: { select: { id: true, amount: true, date: true } },
    },
  });

  // ── Notify group members if this is a shared wallet reminder ──
  if (req.wallet.type === 'SHARED' && req.wallet.groupId) {
    const group = await prisma.sharedGroup.findUnique({
      where: { id: req.wallet.groupId },
      select: { name: true },
    });
    await notifyGroupMembers(prisma, req.wallet.groupId, [req.user.id], {
      type: 'GROUP_BILL_ADDED',
      title: 'New Bill Reminder',
      body: `${req.user.displayName} added a bill "${title}" of Rp ${Number(amount).toLocaleString('id-ID')} in "${group?.name || 'shared group'}"`,
      metadata: {
        groupId: req.wallet.groupId,
        reminderId: reminder.id,
        amount: Number(amount),
      },
    });
  }

  return created(res, reminder, 'Bill reminder created');
}

// ─── List Reminders ─────────────────────────────────────────────────────────

async function getReminders(req, res) {
  const { status, upcoming } = req.query;
  const { page, limit, skip } = parsePagination(req.query);

  const where = {
    walletId: req.wallet.id,
  };

  // Status filter: default to excluding CANCELLED if status is not specified
  if (status) {
    const validStatuses = ['ACTIVE', 'SNOOZED', 'COMPLETED', 'CANCELLED'];
    if (validStatuses.includes(status.toUpperCase())) {
      where.status = status.toUpperCase();
    }
  } else {
    where.status = { not: 'CANCELLED' };
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
        expenses: { select: { id: true, amount: true, date: true } },
      },
      orderBy: { dueDate: 'asc' },
      skip,
      take: limit,
    }),
    prisma.billReminder.count({ where }),
  ]);

  return paginated(res, reminders, { page, limit, total });
}

const {
  getEffectiveDueDate,
  isReminderPaidForCurrentPeriod,
} = require('../utils/bill-reminder-cron');

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

  // Validate periodicity if provided
  const validPeriodicities = ['MONTHLY', 'YEARLY'];
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
      expenses: { select: { id: true, amount: true, date: true } },
    },
  });

  return success(res, reminder, 'Reminder updated');
}

// ─── Delete Reminder ────────────────────────────────────────────────────────

async function deleteReminder(req, res) {
  const { id } = req.params;

  const existing = await prisma.billReminder.findUnique({ where: { id } });
  if (!existing) {
    return error(res, 'Reminder not found', 404);
  }
  if (existing.walletId !== req.wallet.id) {
    return error(res, 'Access denied', 403);
  }

  // Delete the reminder cleanly (foreign key on expense has onDelete: SetNull)
  await prisma.billReminder.delete({
    where: { id },
  });

  return success(res, { id }, 'Reminder deleted');
}

// ─── Pay Reminder ───────────────────────────────────────────────────────────

async function payReminder(req, res) {
  const { id } = req.params;
  const { walletId, categoryId, date, amount } = req.body || {};

  const reminder = await prisma.billReminder.findUnique({
    where: { id },
    include: {
      category: true,
      wallet: true,
    },
  });

  if (!reminder) {
    return error(res, 'Reminder not found', 404);
  }

  const effectiveWalletId = walletId || reminder.walletId;
  if (req.wallet && req.wallet.id !== effectiveWalletId) {
    return error(res, 'Wallet mismatch', 403);
  }

  // Calculate effective due date for the current period
  const effectiveDueDate = getEffectiveDueDate(reminder, new Date());

  // Check if already paid for current period
  const isPaid = await isReminderPaidForCurrentPeriod(reminder, effectiveDueDate);
  if (isPaid) {
    return error(res, 'Tagihan sudah dibayar untuk periode ini', 400);
  }

  // Resolve category
  let finalCategoryId = categoryId || reminder.categoryId;
  if (finalCategoryId) {
    const cat = await prisma.category.findUnique({ where: { id: finalCategoryId } });
    if (!cat) finalCategoryId = null;
  }

  if (!finalCategoryId) {
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
    finalCategoryId = fallbackCategory ? fallbackCategory.id : (await prisma.category.findFirst())?.id;
  }

  if (!finalCategoryId) {
    return error(res, 'No category available to record this payment', 400);
  }

  const expenseAmount = amount ? Number(amount) : Number(reminder.amount);
  const expenseDate = date ? new Date(date) : new Date();

  // Create expense linked to this bill reminder
  const expense = await prisma.expense.create({
    data: {
      amount: expenseAmount,
      description: `Pembayaran: ${reminder.title}`,
      date: expenseDate,
      type: 'ROUTINE',
      userId: req.user.id,
      walletId: effectiveWalletId,
      categoryId: finalCategoryId,
      billReminderId: reminder.id,
    },
    include: {
      category: { select: { id: true, name: true, icon: true, color: true } },
      user: { select: { id: true, displayName: true, avatarUrl: true } },
    },
  });

  // Fetch updated reminder with expenses
  const updatedReminder = await prisma.billReminder.findUnique({
    where: { id },
    include: {
      category: { select: { id: true, name: true, icon: true, color: true } },
      wallet: { select: { id: true, name: true, type: true } },
      expenses: { select: { id: true, amount: true, date: true } },
    },
  });

  // Notify group members if this is a shared wallet
  if (req.wallet?.type === 'SHARED' && req.wallet.groupId) {
    const group = await prisma.sharedGroup.findUnique({
      where: { id: req.wallet.groupId },
      select: { name: true },
    });
    await notifyGroupMembers(prisma, req.wallet.groupId, [req.user.id], {
      type: 'GROUP_EXPENSE_ADDED',
      title: 'Bill Paid',
      body: `${req.user.displayName} paid bill "${reminder.title}" (Rp ${expenseAmount.toLocaleString('id-ID')}) in "${group?.name || 'shared group'}"`,
      metadata: {
        groupId: req.wallet.groupId,
        expenseId: expense.id,
        reminderId: reminder.id,
        amount: expenseAmount,
      },
    });
  }

  return success(res, { expense, reminder: updatedReminder }, 'Tagihan berhasil dibayar');
}

module.exports = {
  createReminder,
  getReminders,
  updateReminder,
  deleteReminder,
  payReminder,
};
