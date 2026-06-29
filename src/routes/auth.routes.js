// ─────────────────────────────────────────────────────────────────────────────
// Auth Routes — /api/auth
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const {
  register,
  login,
  googleAuth,
  getMe,
  refresh,
  getAuthConfig,
  updateProfile,
  changePassword,
} = require('../controllers/auth.controller');

const router = Router();

// Public routes
router.get('/config', asyncHandler(getAuthConfig));
router.post('/register', asyncHandler(register));
router.post('/login', asyncHandler(login));
router.post('/google', asyncHandler(googleAuth));
router.post('/refresh', asyncHandler(refresh));

// Protected routes
router.get('/me', authenticate, asyncHandler(getMe));
router.put('/profile', authenticate, asyncHandler(updateProfile));
router.put('/change-password', authenticate, asyncHandler(changePassword));

module.exports = router;
