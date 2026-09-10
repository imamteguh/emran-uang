// ─────────────────────────────────────────────────────────────────────────────
// Wallet Routes — /api/wallets
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const {
  getWallets,
  updateWallet,
  getCategoryBudgets,
  setCategoryBudget,
  deleteCategoryBudget,
} = require('../controllers/wallet.controller');

const router = Router();

router.use(authenticate);

router.get('/', asyncHandler(getWallets));
router.patch('/:id', asyncHandler(updateWallet));
router.get('/:id/category-budgets', asyncHandler(getCategoryBudgets));
router.put('/:id/category-budgets', asyncHandler(setCategoryBudget));
router.delete('/:id/category-budgets/:categoryId', asyncHandler(deleteCategoryBudget));

module.exports = router;
