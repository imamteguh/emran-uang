// ─────────────────────────────────────────────────────────────────────────────
// Expense Routes — /api/expenses
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const { walletGuard } = require('../middleware/walletGuard');
const {
  createExpense,
  getExpenses,
  getExpenseById,
  updateExpense,
  deleteExpense,
} = require('../controllers/expense.controller');

const router = Router();

// All expense routes require auth + wallet verification
router.use(authenticate);

router.get('/', walletGuard, asyncHandler(getExpenses));
router.get('/:id', walletGuard, asyncHandler(getExpenseById));
router.post('/', walletGuard, asyncHandler(createExpense));
router.put('/:id', walletGuard, asyncHandler(updateExpense));
router.delete('/:id', walletGuard, asyncHandler(deleteExpense));

module.exports = router;
