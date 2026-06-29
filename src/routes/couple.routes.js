// ─────────────────────────────────────────────────────────────────────────────
// Couple Routes — /api/couples
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const {
  sendInvite,
  acceptInvite,
  rejectInvite,
  getMyCouple,
  dissolveCouple,
} = require('../controllers/couple.controller');

const router = Router();

router.use(authenticate);

router.get('/me', asyncHandler(getMyCouple));
router.post('/invite', asyncHandler(sendInvite));
router.post('/invite/:id/accept', asyncHandler(acceptInvite));
router.post('/invite/:id/reject', asyncHandler(rejectInvite));
router.post('/dissolve', asyncHandler(dissolveCouple));

module.exports = router;
