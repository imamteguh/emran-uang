// ─────────────────────────────────────────────────────────────────────────────
// Chat Routes — /api/chat
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const { chatTransaction } = require('../controllers/chat.controller');

const router = Router();

// All chat routes require authentication
router.use(authenticate);

// POST /api/chat/transaction — Parse message and save expense via AI
router.post('/transaction', asyncHandler(chatTransaction));

module.exports = router;
