// ─────────────────────────────────────────────────────────────────────────────
// Category Routes — /api/categories
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const {
  getCategories,
  createCategory,
  updateCategory,
  deleteCategory,
} = require('../controllers/category.controller');

const router = Router();

router.use(authenticate);

router.get('/', asyncHandler(getCategories));
router.post('/', asyncHandler(createCategory));
router.put('/:id', asyncHandler(updateCategory));
router.delete('/:id', asyncHandler(deleteCategory));

module.exports = router;
