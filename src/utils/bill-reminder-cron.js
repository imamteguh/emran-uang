// ─────────────────────────────────────────────────────────────────────────────
// Bill Reminder Cron — Check for upcoming due dates and create notifications
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { createNotification } = require('./notification.helper');

const ONE_HOUR = 60 * 60 * 1000;

/**
 * Check all active bill reminders and create BILL_REMINDER notifications
 * for users whose bills are due within `notifyDaysBefore` days.
 */
async function checkBillReminders() {
  try {
    const now = new Date();

    // Find all active reminders
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

      // Check if we're within the notification window
      if (now < notifyDate) continue; // Too early
      if (now > dueDate) continue; // Past due — skip (could add overdue logic later)

      // Check if we already notified today
      if (reminder.lastNotifiedAt) {
        const lastNotified = new Date(reminder.lastNotifiedAt);
        const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        if (lastNotified >= todayStart) continue; // Already notified today
      }

      // Calculate days until due
      const msUntilDue = dueDate.getTime() - now.getTime();
      const daysUntilDue = Math.ceil(msUntilDue / (1000 * 60 * 60 * 24));

      const dueText =
        daysUntilDue <= 0
          ? 'today'
          : daysUntilDue === 1
          ? 'tomorrow'
          : `in ${daysUntilDue} days`;

      // Create notification for the reminder owner
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

      // Update lastNotifiedAt
      await prisma.billReminder.update({
        where: { id: reminder.id },
        data: { lastNotifiedAt: now },
      });

      notifiedCount++;
    }

    if (notifiedCount > 0) {
      console.log(`[BillReminderCron] Created ${notifiedCount} bill reminder notification(s)`);
    }
  } catch (err) {
    console.error('[BillReminderCron] Error:', err.message);
  }
}

/**
 * Start the bill reminder cron job.
 * Runs immediately on startup, then every hour.
 */
function startBillReminderCron() {
  console.log('[BillReminderCron] Started — checking every hour');
  // Run once on startup (after a short delay to let DB connect)
  setTimeout(() => checkBillReminders(), 5000);
  // Then run every hour
  setInterval(() => checkBillReminders(), ONE_HOUR);
}

module.exports = {
  checkBillReminders,
  startBillReminderCron,
};
