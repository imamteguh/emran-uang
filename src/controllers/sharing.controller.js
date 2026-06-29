// ─────────────────────────────────────────────────────────────────────────────
// Sharing Controller — Invite, Accept, Reject, Archive, Leave
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success, created, error } = require('../utils/apiResponse');

// ─── Send Sharing Invite ────────────────────────────────────────────────────

async function sendInvite(req, res) {
  const { email, groupName } = req.body;
  const senderId = req.user.id;

  if (!email || !email.trim()) {
    return error(res, 'Email tujuan wajib diisi', 400);
  }

  const targetEmail = email.toLowerCase().trim();

  // Can't invite yourself
  if (targetEmail === req.user.email) {
    return error(res, "Tidak bisa mengundang diri sendiri", 400);
  }

  // Check if there's already a pending invite from this user to this email
  const pendingInvite = await prisma.sharedGroupInvite.findFirst({
    where: {
      senderId,
      receiverEmail: targetEmail,
      status: 'PENDING',
    },
  });
  if (pendingInvite) {
    return error(
      res,
      'Anda sudah memiliki undangan pending ke email ini. Batalkan dulu sebelum mengirim yang baru.',
      409
    );
  }

  // Check if target user exists in the system
  const targetUser = await prisma.user.findUnique({
    where: { email: targetEmail },
  });

  // Create the shared group + invite in a transaction
  const result = await prisma.$transaction(async (tx) => {
    // Create shared group container
    const group = await tx.sharedGroup.create({
      data: {
        name: groupName || null,
        status: 'PENDING',
      },
    });

    // Add initiator as owner/first member
    await tx.sharedGroupMember.create({
      data: {
        userId: senderId,
        groupId: group.id,
        role: 'OWNER',
      },
    });

    // Create invite
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7-day expiry

    const invite = await tx.sharedGroupInvite.create({
      data: {
        senderId,
        receiverId: targetUser?.id || null,
        receiverEmail: targetEmail,
        groupId: group.id,
        expiresAt,
      },
    });

    return { group, invite };
  });

  return created(
    res,
    {
      invite: result.invite,
      group: result.group,
      targetUserFound: !!targetUser,
    },
    targetUser
      ? 'Undangan terkirim ke user yang sudah terdaftar'
      : 'Undangan dibuat — user akan melihatnya saat mereka mendaftar'
  );
}

// ─── Accept Sharing Invite ──────────────────────────────────────────────────

async function acceptInvite(req, res) {
  const { id } = req.params;
  const userId = req.user.id;

  const invite = await prisma.sharedGroupInvite.findUnique({
    where: { id },
    include: { group: true },
  });

  if (!invite) {
    return error(res, 'Undangan tidak ditemukan', 404);
  }
  if (invite.status !== 'PENDING') {
    return error(res, `Undangan sudah ${invite.status.toLowerCase()}`, 400);
  }
  if (new Date() > invite.expiresAt) {
    await prisma.sharedGroupInvite.update({
      where: { id },
      data: { status: 'EXPIRED' },
    });
    return error(res, 'Undangan sudah kedaluwarsa', 410);
  }

  // Verify this user is the intended receiver
  if (invite.receiverId && invite.receiverId !== userId) {
    return error(res, 'Undangan ini bukan untuk Anda', 403);
  }
  if (!invite.receiverId && invite.receiverEmail !== req.user.email) {
    return error(res, 'Undangan ini bukan untuk Anda', 403);
  }

  // Can't accept your own invite
  if (invite.senderId === userId) {
    return error(res, "Tidak bisa menerima undangan sendiri", 400);
  }

  // Check if user is already a member of this group
  const existingMember = await prisma.sharedGroupMember.findUnique({
    where: {
      groupId_userId: {
        groupId: invite.groupId,
        userId,
      },
    },
  });
  if (existingMember) {
    return error(res, 'Anda sudah menjadi anggota grup ini', 409);
  }

  // Accept: add member, activate group if needed, create shared wallet if first accept
  const result = await prisma.$transaction(async (tx) => {
    // Add user as member
    await tx.sharedGroupMember.create({
      data: {
        userId,
        groupId: invite.groupId,
        role: 'MEMBER',
      },
    });

    // Activate group if it was pending
    let group = invite.group;
    if (group.status === 'PENDING') {
      group = await tx.sharedGroup.update({
        where: { id: invite.groupId },
        data: { status: 'ACTIVE' },
      });
    }

    // Create shared wallet if one doesn't exist yet
    const existingWallet = await tx.wallet.findFirst({
      where: { groupId: group.id, type: 'SHARED' },
    });

    let sharedWallet = existingWallet;
    if (!existingWallet) {
      sharedWallet = await tx.wallet.create({
        data: {
          name: group.name ? `${group.name}` : 'Wallet Bersama',
          type: 'SHARED',
          currency: 'IDR',
          groupId: group.id,
        },
      });
    }

    // Update invite
    await tx.sharedGroupInvite.update({
      where: { id },
      data: {
        status: 'ACCEPTED',
        receiverId: userId,
      },
    });

    return { group, sharedWallet };
  });

  return success(res, result, 'Undangan diterima — data bersama aktif!');
}

// ─── Reject Sharing Invite ──────────────────────────────────────────────────

async function rejectInvite(req, res) {
  const { id } = req.params;
  const userId = req.user.id;

  const invite = await prisma.sharedGroupInvite.findUnique({ where: { id } });

  if (!invite) {
    return error(res, 'Undangan tidak ditemukan', 404);
  }
  if (invite.status !== 'PENDING') {
    return error(res, `Undangan sudah ${invite.status.toLowerCase()}`, 400);
  }

  // Verify receiver
  if (invite.receiverId && invite.receiverId !== userId) {
    return error(res, 'Undangan ini bukan untuk Anda', 403);
  }
  if (!invite.receiverId && invite.receiverEmail !== req.user.email) {
    return error(res, 'Undangan ini bukan untuk Anda', 403);
  }

  await prisma.$transaction(async (tx) => {
    await tx.sharedGroupInvite.update({
      where: { id },
      data: { status: 'REJECTED', receiverId: userId },
    });

    // If the group is still pending (no one else joined), clean it up
    const memberCount = await tx.sharedGroupMember.count({
      where: { groupId: invite.groupId },
    });
    const acceptedInvites = await tx.sharedGroupInvite.count({
      where: { groupId: invite.groupId, status: 'ACCEPTED' },
    });

    if (memberCount <= 1 && acceptedInvites === 0) {
      // Only the owner is in the group, no one accepted — clean up
      await tx.sharedGroupMember.deleteMany({ where: { groupId: invite.groupId } });
      await tx.sharedGroup.delete({ where: { id: invite.groupId } });
    }
  });

  return success(res, null, 'Undangan ditolak');
}

// ─── Get My Shared Groups ───────────────────────────────────────────────────

async function getMyGroups(req, res) {
  const userId = req.user.id;

  const memberships = await prisma.sharedGroupMember.findMany({
    where: {
      userId,
      group: { status: 'ACTIVE' },
    },
    include: {
      group: {
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

  // Also check for pending invites
  const pendingInvites = await prisma.sharedGroupInvite.findMany({
    where: {
      OR: [{ senderId: userId }, { receiverId: userId }],
      status: 'PENDING',
    },
    include: {
      sender: {
        select: { id: true, displayName: true, avatarUrl: true },
      },
      group: {
        select: { id: true, name: true },
      },
    },
  });

  const groups = memberships.map((m) => ({
    group: m.group,
    myRole: m.role,
  }));

  return success(res, {
    groups,
    pendingInvites,
  });
}

// ─── Archive Shared Group ───────────────────────────────────────────────────

async function archiveGroup(req, res) {
  const { id } = req.params;
  const userId = req.user.id;

  const membership = await prisma.sharedGroupMember.findFirst({
    where: {
      userId,
      groupId: id,
      group: { status: 'ACTIVE' },
    },
  });

  if (!membership) {
    return error(res, 'Anda bukan anggota grup ini atau grup tidak aktif', 404);
  }

  // Only the owner can archive the group
  if (membership.role !== 'OWNER') {
    return error(res, 'Hanya pemilik grup yang bisa mengarsipkan', 403);
  }

  await prisma.sharedGroup.update({
    where: { id },
    data: {
      status: 'ARCHIVED',
      archivedAt: new Date(),
    },
  });

  return success(res, null, 'Grup diarsipkan. Riwayat data bersama tetap tersimpan.');
}

// ─── Leave Shared Group ─────────────────────────────────────────────────────

async function leaveGroup(req, res) {
  const { id } = req.params;
  const userId = req.user.id;

  const membership = await prisma.sharedGroupMember.findFirst({
    where: {
      userId,
      groupId: id,
      group: { status: 'ACTIVE' },
    },
  });

  if (!membership) {
    return error(res, 'Anda bukan anggota grup ini', 404);
  }

  // If user is the owner, they can't leave — they must archive or transfer ownership
  if (membership.role === 'OWNER') {
    // Check if there are other members
    const otherMembers = await prisma.sharedGroupMember.findMany({
      where: { groupId: id, userId: { not: userId } },
    });

    if (otherMembers.length > 0) {
      // Transfer ownership to the next member
      await prisma.$transaction(async (tx) => {
        await tx.sharedGroupMember.update({
          where: { id: otherMembers[0].id },
          data: { role: 'OWNER' },
        });
        await tx.sharedGroupMember.delete({
          where: { id: membership.id },
        });
      });
    } else {
      // Last member leaving — archive the group
      await prisma.$transaction(async (tx) => {
        await tx.sharedGroupMember.delete({
          where: { id: membership.id },
        });
        await tx.sharedGroup.update({
          where: { id },
          data: { status: 'ARCHIVED', archivedAt: new Date() },
        });
      });
    }
  } else {
    await prisma.sharedGroupMember.delete({
      where: { id: membership.id },
    });
  }

  return success(res, null, 'Anda telah keluar dari grup.');
}

module.exports = {
  sendInvite,
  acceptInvite,
  rejectInvite,
  getMyGroups,
  archiveGroup,
  leaveGroup,
};
