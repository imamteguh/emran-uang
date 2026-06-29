// ─────────────────────────────────────────────────────────────────────────────
// Wallet Routes — /api/wallets
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const { getWallets, updateWallet } = require('../controllers/wallet.controller');

const router = Router();

router.use(authenticate);

router.get('/', asyncHandler(getWallets));
router.patch('/:id', asyncHandler(updateWallet));

module.exports = router;
