// ─────────────────────────────────────────────────────────────────────────────
// Analytics Routes — /api/analytics
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const { walletGuard } = require('../middleware/walletGuard');
const {
  compareMonths,
  breakdown,
  trend,
} = require('../controllers/analytics.controller');

const router = Router();

// All analytics routes require auth + wallet verification
router.use(authenticate);

router.get('/compare', walletGuard, asyncHandler(compareMonths));
router.get('/breakdown', walletGuard, asyncHandler(breakdown));
router.get('/trend', walletGuard, asyncHandler(trend));

module.exports = router;
