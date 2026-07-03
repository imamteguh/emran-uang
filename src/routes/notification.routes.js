// ─────────────────────────────────────────────────────────────────────────────
// Notification Routes — /api/notifications
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAllNotifications,
} = require('../controllers/notification.controller');

const router = Router();

router.use(authenticate);

router.get('/', asyncHandler(getNotifications));
router.get('/unread-count', asyncHandler(getUnreadCount));
router.post('/read-all', asyncHandler(markAllAsRead));
router.post('/:id/read', asyncHandler(markAsRead));
router.delete('/clear', asyncHandler(clearAllNotifications));
router.delete('/:id', asyncHandler(deleteNotification));

module.exports = router;
