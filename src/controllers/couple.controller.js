// ─────────────────────────────────────────────────────────────────────────────
// Couple Controller — Invite, Accept, Reject, Dissolve
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success, created, error } = require('../utils/apiResponse');

// ─── Send Couple Invite ─────────────────────────────────────────────────────

async function sendInvite(req, res) {
  const { email, coupleName } = req.body;
  const senderId = req.user.id;

  if (!email || !email.trim()) {
    return error(res, 'Partner email is required', 400);
  }

  const partnerEmail = email.toLowerCase().trim();

  // Can't invite yourself
  if (partnerEmail === req.user.email) {
    return error(res, "You can't invite yourself", 400);
  }

  // Check if user already has an active couple
  const existingCouple = await prisma.coupleMember.findFirst({
    where: {
      userId: senderId,
      couple: { status: 'ACTIVE' },
    },
  });
  if (existingCouple) {
    return error(res, 'You are already in an active couple', 409);
  }

  // Check if there's already a pending invite from this user
  const pendingInvite = await prisma.coupleInvite.findFirst({
    where: {
      senderId,
      status: 'PENDING',
    },
  });
  if (pendingInvite) {
    return error(
      res,
      'You already have a pending invite. Cancel it first before sending a new one.',
      409
    );
  }

  // Check if partner exists in the system
  const partner = await prisma.user.findUnique({
    where: { email: partnerEmail },
  });

  // Create the couple + invite in a transaction
  const result = await prisma.$transaction(async (tx) => {
    // Create couple container
    const couple = await tx.couple.create({
      data: {
        name: coupleName || null,
        status: 'PENDING',
      },
    });

    // Add initiator as first member
    await tx.coupleMember.create({
      data: {
        userId: senderId,
        coupleId: couple.id,
        role: 'INITIATOR',
      },
    });

    // Create invite
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7-day expiry

    const invite = await tx.coupleInvite.create({
      data: {
        senderId,
        receiverId: partner?.id || null,
        receiverEmail: partnerEmail,
        coupleId: couple.id,
        expiresAt,
      },
    });

    return { couple, invite };
  });

  return created(
    res,
    {
      invite: result.invite,
      couple: result.couple,
      partnerFound: !!partner,
    },
    partner
      ? 'Invite sent to existing user'
      : 'Invite created — partner will see it when they sign up'
  );
}

// ─── Accept Couple Invite ───────────────────────────────────────────────────

async function acceptInvite(req, res) {
  const { id } = req.params;
  const userId = req.user.id;

  const invite = await prisma.coupleInvite.findUnique({
    where: { id },
    include: { couple: true },
  });

  if (!invite) {
    return error(res, 'Invite not found', 404);
  }
  if (invite.status !== 'PENDING') {
    return error(res, `Invite is already ${invite.status.toLowerCase()}`, 400);
  }
  if (new Date() > invite.expiresAt) {
    await prisma.coupleInvite.update({
      where: { id },
      data: { status: 'EXPIRED' },
    });
    return error(res, 'Invite has expired', 410);
  }

  // Verify this user is the intended receiver
  if (invite.receiverId && invite.receiverId !== userId) {
    return error(res, 'This invite is not for you', 403);
  }
  if (!invite.receiverId && invite.receiverEmail !== req.user.email) {
    return error(res, 'This invite is not for you', 403);
  }

  // Can't accept your own invite
  if (invite.senderId === userId) {
    return error(res, "You can't accept your own invite", 400);
  }

  // Check if user already has an active couple
  const existingCouple = await prisma.coupleMember.findFirst({
    where: { userId, couple: { status: 'ACTIVE' } },
  });
  if (existingCouple) {
    return error(res, 'You are already in an active couple', 409);
  }

  // Accept: add partner, activate couple, create shared wallet
  const result = await prisma.$transaction(async (tx) => {
    // Add partner as second member
    await tx.coupleMember.create({
      data: {
        userId,
        coupleId: invite.coupleId,
        role: 'PARTNER',
      },
    });

    // Activate couple
    const couple = await tx.couple.update({
      where: { id: invite.coupleId },
      data: { status: 'ACTIVE' },
    });

    // Create shared wallet
    const sharedWallet = await tx.wallet.create({
      data: {
        name: couple.name ? `${couple.name}'s Wallet` : 'Shared Wallet',
        type: 'SHARED',
        currency: 'IDR',
        coupleId: couple.id,
      },
    });

    // Update invite
    await tx.coupleInvite.update({
      where: { id },
      data: {
        status: 'ACCEPTED',
        receiverId: userId,
      },
    });

    return { couple, sharedWallet };
  });

  return success(res, result, 'Invite accepted — shared wallet created!');
}

// ─── Reject Couple Invite ───────────────────────────────────────────────────

async function rejectInvite(req, res) {
  const { id } = req.params;
  const userId = req.user.id;

  const invite = await prisma.coupleInvite.findUnique({ where: { id } });

  if (!invite) {
    return error(res, 'Invite not found', 404);
  }
  if (invite.status !== 'PENDING') {
    return error(res, `Invite is already ${invite.status.toLowerCase()}`, 400);
  }

  // Verify receiver
  if (invite.receiverId && invite.receiverId !== userId) {
    return error(res, 'This invite is not for you', 403);
  }
  if (!invite.receiverId && invite.receiverEmail !== req.user.email) {
    return error(res, 'This invite is not for you', 403);
  }

  await prisma.$transaction(async (tx) => {
    await tx.coupleInvite.update({
      where: { id },
      data: { status: 'REJECTED', receiverId: userId },
    });

    // Clean up the pending couple and orphaned member
    await tx.coupleMember.deleteMany({ where: { coupleId: invite.coupleId } });
    await tx.couple.delete({ where: { id: invite.coupleId } });
  });

  return success(res, null, 'Invite rejected');
}

// ─── Get Current Couple ─────────────────────────────────────────────────────

async function getMyCouple(req, res) {
  const userId = req.user.id;

  const membership = await prisma.coupleMember.findFirst({
    where: {
      userId,
      couple: { status: 'ACTIVE' },
    },
    include: {
      couple: {
        include: {
          members: {
            include: {
              user: {
                select: {
                  id: true,
                  displayName: true,
                  avatarUrl: true,
                  email: true,
                },
              },
            },
          },
          sharedWallets: {
            select: { id: true, name: true, currency: true },
          },
        },
      },
    },
  });

  if (!membership) {
    // Also check for pending invites
    const pendingInvites = await prisma.coupleInvite.findMany({
      where: {
        OR: [{ senderId: userId }, { receiverId: userId }],
        status: 'PENDING',
      },
      include: {
        sender: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
      },
    });

    return success(res, {
      couple: null,
      pendingInvites,
    });
  }

  return success(res, {
    couple: membership.couple,
    myRole: membership.role,
    pendingInvites: [],
  });
}

// ─── Dissolve Couple ────────────────────────────────────────────────────────

async function dissolveCouple(req, res) {
  const userId = req.user.id;

  const membership = await prisma.coupleMember.findFirst({
    where: {
      userId,
      couple: { status: 'ACTIVE' },
    },
  });

  if (!membership) {
    return error(res, 'You are not in an active couple', 404);
  }

  await prisma.couple.update({
    where: { id: membership.coupleId },
    data: {
      status: 'DISSOLVED',
      dissolvedAt: new Date(),
    },
  });

  return success(res, null, 'Couple dissolved. Shared wallet history is preserved.');
}

module.exports = {
  sendInvite,
  acceptInvite,
  rejectInvite,
  getMyCouple,
  dissolveCouple,
};
