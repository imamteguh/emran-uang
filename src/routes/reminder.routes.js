// ─────────────────────────────────────────────────────────────────────────────
// Reminder Routes — /api/reminders
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const { walletGuard } = require('../middleware/walletGuard');
const {
  createReminder,
  getReminders,
  updateReminder,
  deleteReminder,
} = require('../controllers/reminder.controller');

const router = Router();

// All reminder routes require auth + wallet verification
router.use(authenticate);

router.get('/', walletGuard, asyncHandler(getReminders));
router.post('/', walletGuard, asyncHandler(createReminder));
router.put('/:id', walletGuard, asyncHandler(updateReminder));
router.delete('/:id', walletGuard, asyncHandler(deleteReminder));

module.exports = router;
