// ─────────────────────────────────────────────────────────────────────────────
// Reminder Routes — /api/reminders
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const { walletGuard } = require('../middleware/walletGuard');
const { billReminderCheck } = require('../middleware/billReminderCheck.middleware');
const {
  createReminder,
  getReminders,
  updateReminder,
  deleteReminder,
  payReminder,
} = require('../controllers/reminder.controller');

const router = Router();

// All reminder routes require auth + wallet verification
router.use(authenticate);

router.get('/', walletGuard, billReminderCheck, asyncHandler(getReminders));
router.post('/', walletGuard, asyncHandler(createReminder));
router.post('/:id/pay', walletGuard, asyncHandler(payReminder));
router.put('/:id', walletGuard, asyncHandler(updateReminder));
router.delete('/:id', walletGuard, asyncHandler(deleteReminder));

module.exports = router;
