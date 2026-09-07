// ─────────────────────────────────────────────────────────────────────────────
// OCR Routes — /api/ocr
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const { scanReceipt } = require('../controllers/ocr.controller');

const router = Router();

// All OCR routes require authentication
router.use(authenticate);

router.post('/scan-receipt', asyncHandler(scanReceipt));

module.exports = router;
