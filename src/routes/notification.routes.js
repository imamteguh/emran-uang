// ─────────────────────────────────────────────────────────────────────────────
// Notification Routes — /api/notifications
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const { billReminderCheck } = require('../middleware/billReminderCheck.middleware');
const {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAllNotifications,
  triggerBillReminderCron,
} = require('../controllers/notification.controller');

const router = Router();

// Public / Manual trigger endpoint (auth via CRON_SECRET)
// Berguna untuk debug atau integrasi external scheduler (e.g. cron-job.org)
router.get('/cron/bill-reminders', asyncHandler(triggerBillReminderCron));

router.use(authenticate);

// billReminderCheck: cek reminder aktif user secara non-blocking setiap kali
// user mengambil notifikasi (pendekatan event-driven, tanpa cron)
router.get('/', billReminderCheck, asyncHandler(getNotifications));
router.get('/unread-count', asyncHandler(getUnreadCount));
router.post('/read-all', asyncHandler(markAllAsRead));
router.post('/:id/read', asyncHandler(markAsRead));
router.delete('/clear', asyncHandler(clearAllNotifications));
router.delete('/:id', asyncHandler(deleteNotification));

module.exports = router;

