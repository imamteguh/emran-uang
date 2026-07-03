// ─────────────────────────────────────────────────────────────────────────────
// Notification Helper — Create in-app notifications
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const firebaseAdmin = require('../config/firebase');
const { getMessaging } = require('firebase-admin/messaging');

/**
 * Send FCM push notification asynchronously.
 */
async function sendFcmPush(token, title, body, metadata = {}, type) {
  if (!firebaseAdmin) return;

  const stringifiedMetadata = {
    type: type || 'NOTIFICATION',
  };

  if (metadata) {
    Object.keys(metadata).forEach((key) => {
      stringifiedMetadata[key] = typeof metadata[key] === 'object'
        ? JSON.stringify(metadata[key])
        : String(metadata[key]);
    });
  }

  const message = {
    notification: {
      title,
      body,
    },
    data: stringifiedMetadata,
    token: token,
  };

  try {
    const messaging = getMessaging();
    await messaging.send(message);
    console.log('[FCM] Successfully sent push notification.');
  } catch (error) {
    console.error('[FCM] Error sending push notification:', error.message);
    if (error.code === 'messaging/registration-token-not-registered') {
      // Clear token in database
      await prisma.user.updateMany({
        where: { fcmToken: token },
        data: { fcmToken: null },
      });
      console.log('[FCM] Stale FCM token cleared from database.');
    }
  }
}

/**
 * Create a single notification for a user.
 * Can accept either the global prisma client or a transaction client.
 */
async function createNotification(client, { userId, type, title, body, metadata }) {
  const dbNotif = await client.notification.create({
    data: {
      userId,
      type,
      title,
      body,
      metadata: metadata || undefined,
    },
  });

  // Query FCM token and trigger push in background
  client.user.findUnique({
    where: { id: userId },
    select: { fcmToken: true },
  }).then((user) => {
    if (user?.fcmToken) {
      sendFcmPush(user.fcmToken, title, body, metadata, type);
    }
  }).catch((err) => {
    console.error('[FCM] Error fetching user FCM token:', err.message);
  });

  return dbNotif;
}

/**
 * Create notifications for multiple users at once.
 */
async function createBulkNotifications(client, notifications) {
  if (!notifications.length) return;

  const result = await client.notification.createMany({
    data: notifications.map((n) => ({
      userId: n.userId,
      type: n.type,
      title: n.title,
      body: n.body,
      metadata: n.metadata || undefined,
    })),
  });

  // Query FCM tokens and trigger push in background
  const userIds = [...new Set(notifications.map((n) => n.userId))];
  client.user.findMany({
    where: { id: { in: userIds } },
    select: { id: true, fcmToken: true },
  }).then((users) => {
    const tokenMap = new Map(users.map((u) => [u.id, u.fcmToken]));
    notifications.forEach((n) => {
      const token = tokenMap.get(n.userId);
      if (token) {
        sendFcmPush(token, n.title, n.body, n.metadata, n.type);
      }
    });
  }).catch((err) => {
    console.error('[FCM] Error fetching bulk FCM tokens:', err.message);
  });

  return result;
}

/**
 * Get all member user IDs for a group, optionally excluding some users.
 *
 * @param {object} client - Prisma client or transaction ($tx)
 * @param {string} groupId
 * @param {string[]} [excludeUserIds=[]] - User IDs to exclude
 * @returns {Promise<string[]>}
 */
async function getGroupMemberIds(client, groupId, excludeUserIds = []) {
  const members = await client.sharedGroupMember.findMany({
    where: {
      groupId,
      userId: { notIn: excludeUserIds },
    },
    select: { userId: true },
  });
  return members.map((m) => m.userId);
}

/**
 * Notify all group members (except excluded ones) about an event.
 *
 * @param {object} client - Prisma client or transaction ($tx)
 * @param {string} groupId
 * @param {string[]} excludeUserIds - Users to exclude (e.g., the actor)
 * @param {object} notification - { type, title, body, metadata }
 */
async function notifyGroupMembers(client, groupId, excludeUserIds, notification) {
  const memberIds = await getGroupMemberIds(client, groupId, excludeUserIds);

  if (!memberIds.length) return;

  const notifications = memberIds.map((userId) => ({
    userId,
    type: notification.type,
    title: notification.title,
    body: notification.body,
    metadata: notification.metadata,
  }));

  return createBulkNotifications(client, notifications);
}

module.exports = {
  createNotification,
  createBulkNotifications,
  getGroupMemberIds,
  notifyGroupMembers,
};
