// ─────────────────────────────────────────────────────────────────────────────
// Notification Controller — List, Read, Mark All Read
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success, error, paginated } = require('../utils/apiResponse');
const { parsePagination } = require('../utils/dateHelpers');

// ─── Get Notifications ──────────────────────────────────────────────────────

async function getNotifications(req, res) {
  const userId = req.user.id;
  const { filter } = req.query; // 'all' | 'unread' | 'read'
  const { page, limit, skip } = parsePagination(req.query);

  const where = { userId };

  if (filter === 'unread') {
    where.isRead = false;
  } else if (filter === 'read') {
    where.isRead = true;
  }

  const [notifications, total] = await Promise.all([
    prisma.notification.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
    prisma.notification.count({ where }),
  ]);

  return paginated(res, notifications, { page, limit, total });
}

// ─── Get Unread Count ───────────────────────────────────────────────────────

async function getUnreadCount(req, res) {
  const userId = req.user.id;

  const count = await prisma.notification.count({
    where: { userId, isRead: false },
  });

  return success(res, { unreadCount: count });
}

// ─── Mark Single Notification as Read ───────────────────────────────────────

async function markAsRead(req, res) {
  const { id } = req.params;
  const userId = req.user.id;

  const notification = await prisma.notification.findUnique({ where: { id } });

  if (!notification) {
    return error(res, 'Notification not found', 404);
  }
  if (notification.userId !== userId) {
    return error(res, 'Access denied', 403);
  }

  const updated = await prisma.notification.update({
    where: { id },
    data: { isRead: true },
  });

  return success(res, updated, 'Notification marked as read');
}

// ─── Mark All Notifications as Read ─────────────────────────────────────────

async function markAllAsRead(req, res) {
  const userId = req.user.id;

  const result = await prisma.notification.updateMany({
    where: { userId, isRead: false },
    data: { isRead: true },
  });

  return success(res, { markedCount: result.count }, 'All notifications marked as read');
}

async function deleteNotification(req, res) {
  const { id } = req.params;
  const userId = req.user.id;

  const notification = await prisma.notification.findUnique({ where: { id } });

  if (!notification) {
    return error(res, 'Notification not found', 404);
  }
  if (notification.userId !== userId) {
    return error(res, 'Access denied', 403);
  }

  await prisma.notification.delete({ where: { id } });

  return success(res, null, 'Notification deleted successfully');
}

async function clearAllNotifications(req, res) {
  const userId = req.user.id;

  const result = await prisma.notification.deleteMany({
    where: { userId },
  });

  return success(res, { deletedCount: result.count }, 'All notifications cleared successfully');
}

async function triggerBillReminderCron(req, res) {
  const authHeader = req.headers.authorization;
  const cronSecret = process.env.CRON_SECRET;

  // Verify auth header if in production
  if (process.env.NODE_ENV === 'production') {
    if (!cronSecret || authHeader !== `Bearer ${cronSecret}`) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }
  }

  try {
    const { checkBillReminders } = require('../utils/bill-reminder-cron');
    await checkBillReminders();
    return res.json({ success: true, message: 'Bill reminders checked successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAllNotifications,
  triggerBillReminderCron,
};
