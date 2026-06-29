// ─────────────────────────────────────────────────────────────────────────────
// Sharing Routes — /api/sharing
// ─────────────────────────────────────────────────────────────────────────────

const { Router } = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticate } = require('../middleware/auth');
const {
  sendInvite,
  acceptInvite,
  rejectInvite,
  getMyGroups,
  archiveGroup,
  leaveGroup,
} = require('../controllers/sharing.controller');

const router = Router();

router.use(authenticate);

router.get('/groups', asyncHandler(getMyGroups));
router.post('/invite', asyncHandler(sendInvite));
router.post('/invite/:id/accept', asyncHandler(acceptInvite));
router.post('/invite/:id/reject', asyncHandler(rejectInvite));
router.post('/groups/:id/archive', asyncHandler(archiveGroup));
router.post('/groups/:id/leave', asyncHandler(leaveGroup));

module.exports = router;
