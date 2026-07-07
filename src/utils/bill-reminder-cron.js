// ─────────────────────────────────────────────────────────────────────────────
// Bill Reminder Helper — Check for upcoming due dates and create notifications
//
// Pendekatan: Event-Driven (Push-on-Access)
// Pengecekan dilakukan saat user aktif (bukan via cron/timer) sehingga
// kompatibel dengan Vercel Hobby Plan (serverless / stateless).
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { createNotification } = require('./notification.helper');

/**
 * Cek bill reminder milik satu user dan buat notifikasi jika diperlukan.
 * Dipanggil secara lazy ketika user melakukan request ke API (e.g. GET /notifications).
 *
 * @param {string} userId
 */
async function checkBillRemindersForUser(userId) {
  try {
    const now = new Date();

    const reminders = await prisma.billReminder.findMany({
      where: {
        userId,
        status: 'ACTIVE',
      },
    });

    for (const reminder of reminders) {
      const dueDate = new Date(reminder.dueDate);
      const notifyDate = new Date(dueDate);
      notifyDate.setDate(notifyDate.getDate() - reminder.notifyDaysBefore);

      // Terlalu dini untuk dinotifikasi
      if (now < notifyDate) continue;

      // Sudah lewat jatuh tempo — skip
      if (now > dueDate) continue;

      // Sudah dinotifikasi hari ini — skip
      if (reminder.lastNotifiedAt) {
        const lastNotified = new Date(reminder.lastNotifiedAt);
        const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        if (lastNotified >= todayStart) continue;
      }

      // Hitung hari tersisa
      const msUntilDue = dueDate.getTime() - now.getTime();
      const daysUntilDue = Math.ceil(msUntilDue / (1000 * 60 * 60 * 24));

      const dueText =
        daysUntilDue <= 0
          ? 'today'
          : daysUntilDue === 1
          ? 'tomorrow'
          : `in ${daysUntilDue} days`;

      await createNotification(prisma, {
        userId: reminder.userId,
        type: 'BILL_REMINDER',
        title: 'Bill Reminder',
        body: `"${reminder.title}" is due ${dueText}. Amount: Rp ${Number(reminder.amount).toLocaleString('id-ID')}`,
        metadata: {
          reminderId: reminder.id,
          walletId: reminder.walletId,
          dueDate: reminder.dueDate,
          amount: Number(reminder.amount),
        },
      });

      await prisma.billReminder.update({
        where: { id: reminder.id },
        data: { lastNotifiedAt: now },
      });

      console.log(`[BillReminder] Notified user ${userId} for reminder "${reminder.title}"`);
    }
  } catch (err) {
    console.error('[BillReminder] Error checking reminders for user:', err.message);
  }
}

/**
 * Cek semua reminder aktif (seluruh user).
 * Berguna untuk manual trigger via endpoint /cron/bill-reminders
 * atau integrasi dengan external scheduler (e.g. cron-job.org) di masa depan.
 */
async function checkBillReminders() {
  try {
    const now = new Date();

    const reminders = await prisma.billReminder.findMany({
      where: {
        status: 'ACTIVE',
      },
      include: {
        wallet: {
          select: {
            id: true,
            name: true,
            type: true,
            groupId: true,
          },
        },
      },
    });

    let notifiedCount = 0;

    for (const reminder of reminders) {
      const dueDate = new Date(reminder.dueDate);
      const notifyDate = new Date(dueDate);
      notifyDate.setDate(notifyDate.getDate() - reminder.notifyDaysBefore);

      if (now < notifyDate) continue;
      if (now > dueDate) continue;

      if (reminder.lastNotifiedAt) {
        const lastNotified = new Date(reminder.lastNotifiedAt);
        const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        if (lastNotified >= todayStart) continue;
      }

      const msUntilDue = dueDate.getTime() - now.getTime();
      const daysUntilDue = Math.ceil(msUntilDue / (1000 * 60 * 60 * 24));

      const dueText =
        daysUntilDue <= 0
          ? 'today'
          : daysUntilDue === 1
          ? 'tomorrow'
          : `in ${daysUntilDue} days`;

      await createNotification(prisma, {
        userId: reminder.userId,
        type: 'BILL_REMINDER',
        title: 'Bill Reminder',
        body: `"${reminder.title}" is due ${dueText}. Amount: Rp ${Number(reminder.amount).toLocaleString('id-ID')}`,
        metadata: {
          reminderId: reminder.id,
          walletId: reminder.walletId,
          dueDate: reminder.dueDate,
          amount: Number(reminder.amount),
        },
      });

      await prisma.billReminder.update({
        where: { id: reminder.id },
        data: { lastNotifiedAt: now },
      });

      notifiedCount++;
    }

    if (notifiedCount > 0) {
      console.log(`[BillReminder] Created ${notifiedCount} bill reminder notification(s)`);
    }

    return notifiedCount;
  } catch (err) {
    console.error('[BillReminder] Error:', err.message);
    throw err;
  }
}

module.exports = {
  checkBillRemindersForUser,
  checkBillReminders,
};
