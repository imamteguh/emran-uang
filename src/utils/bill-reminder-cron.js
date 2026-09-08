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
 * Menghitung tanggal jatuh tempo efektif untuk periode berjalan
 * berdasarkan periodicity (MONTHLY atau YEARLY).
 *
 * @param {object} reminder
 * @param {Date} now
 * @returns {Date}
 */
function getEffectiveDueDate(reminder, now = new Date()) {
  const baseDueDate = new Date(reminder.dueDate);
  const periodicity = (reminder.periodicity || 'MONTHLY').toUpperCase();

  if (periodicity === 'YEARLY') {
    const targetMonth = baseDueDate.getMonth();
    const targetDay = baseDueDate.getDate();
    const candidateThisYear = new Date(now.getFullYear(), targetMonth, targetDay, 23, 59, 59, 999);
    if (baseDueDate > candidateThisYear) {
      return baseDueDate;
    }
    return candidateThisYear;
  }

  // MONTHLY (default)
  const targetDay = baseDueDate.getDate();
  const lastDayOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  const clampedDay = Math.min(targetDay, lastDayOfMonth);
  const candidateThisMonth = new Date(now.getFullYear(), now.getMonth(), clampedDay, 23, 59, 59, 999);

  if (baseDueDate > candidateThisMonth) {
    return baseDueDate;
  }
  return candidateThisMonth;
}

/**
 * Memeriksa apakah tagihan sudah dibayar pada periode berjalan.
 *
 * @param {object} reminder
 * @param {Date} effectiveDueDate
 * @returns {Promise<boolean>}
 */
async function isReminderPaidForCurrentPeriod(reminder, effectiveDueDate) {
  const periodicity = (reminder.periodicity || 'MONTHLY').toUpperCase();
  let startDate, endDate;

  if (periodicity === 'YEARLY') {
    startDate = new Date(effectiveDueDate.getFullYear(), 0, 1);
    endDate = new Date(effectiveDueDate.getFullYear(), 11, 31, 23, 59, 59, 999);
  } else {
    // MONTHLY
    startDate = new Date(effectiveDueDate.getFullYear(), effectiveDueDate.getMonth(), 1);
    endDate = new Date(effectiveDueDate.getFullYear(), effectiveDueDate.getMonth() + 1, 0, 23, 59, 59, 999);
  }

  const existingExpense = await prisma.expense.findFirst({
    where: {
      billReminderId: reminder.id,
      date: {
        gte: startDate,
        lte: endDate,
      },
    },
  });

  return !!existingExpense;
}

/**
 * Cek bill reminder milik satu user dan buat notifikasi jika diperlukan.
 * Dipanggil secara lazy ketika user aktif di aplikasi.
 *
 * @param {string} userId
 */
async function checkBillRemindersForUser(userId) {
  try {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    const reminders = await prisma.billReminder.findMany({
      where: {
        userId,
        status: 'ACTIVE',
      },
    });

    for (const reminder of reminders) {
      const effectiveDueDate = getEffectiveDueDate(reminder, now);
      const isPaid = await isReminderPaidForCurrentPeriod(reminder, effectiveDueDate);

      // Jika sudah dibayar untuk siklus ini, tidak perlu kirim pengingat
      if (isPaid) continue;

      const notifyDays = reminder.notifyDaysBefore ?? 3;
      const notifyStartDate = new Date(effectiveDueDate);
      notifyStartDate.setDate(notifyStartDate.getDate() - notifyDays);
      notifyStartDate.setHours(0, 0, 0, 0);

      // Terlalu dini untuk dinotifikasi
      if (now < notifyStartDate) continue;

      // Sudah dinotifikasi hari ini — skip agar tidak spam
      if (reminder.lastNotifiedAt) {
        const lastNotified = new Date(reminder.lastNotifiedAt);
        if (lastNotified >= todayStart) continue;
      }

      // Hitung selisih hari
      const effectiveDueStart = new Date(
        effectiveDueDate.getFullYear(),
        effectiveDueDate.getMonth(),
        effectiveDueDate.getDate()
      );
      const diffMs = effectiveDueStart.getTime() - todayStart.getTime();
      const daysUntilDue = Math.round(diffMs / (1000 * 60 * 60 * 24));

      let title = 'Pengingat Tagihan';
      let dueText = '';

      if (daysUntilDue < 0) {
        title = 'Tagihan Lewat Jatuh Tempo';
        dueText = `telah lewat jatuh tempo sejak ${Math.abs(daysUntilDue)} hari lalu`;
      } else if (daysUntilDue === 0) {
        title = 'Tagihan Jatuh Tempo Hari Ini';
        dueText = 'jatuh tempo HARI INI';
      } else if (daysUntilDue === 1) {
        title = 'Pengingat Tagihan (Besok)';
        dueText = 'jatuh tempo besok';
      } else {
        dueText = `jatuh tempo dalam ${daysUntilDue} hari (${effectiveDueDate.getDate()}/${effectiveDueDate.getMonth() + 1}/${effectiveDueDate.getFullYear()})`;
      }

      await createNotification(prisma, {
        userId: reminder.userId,
        type: 'BILL_REMINDER',
        title,
        body: `Tagihan "${reminder.title}" sebesar Rp ${Number(reminder.amount).toLocaleString('id-ID')} ${dueText}.`,
        metadata: {
          reminderId: reminder.id,
          walletId: reminder.walletId,
          dueDate: effectiveDueDate,
          amount: Number(reminder.amount),
        },
      });

      await prisma.billReminder.update({
        where: { id: reminder.id },
        data: { lastNotifiedAt: now },
      });

      // Otomatis catat pengeluaran jika autoLogExpense aktif dan sudah mencapai tanggal jatuh tempo
      if (reminder.autoLogExpense && daysUntilDue <= 0 && reminder.categoryId) {
        try {
          await prisma.expense.create({
            data: {
              amount: reminder.amount,
              description: `Pembayaran Otomatis: ${reminder.title}`,
              date: effectiveDueDate,
              type: 'ROUTINE',
              userId: reminder.userId,
              walletId: reminder.walletId,
              categoryId: reminder.categoryId,
              billReminderId: reminder.id,
            },
          });

          await createNotification(prisma, {
            userId: reminder.userId,
            type: 'BILL_REMINDER',
            title: 'Pembayaran Tagihan Otomatis',
            body: `Tagihan "${reminder.title}" sebesar Rp ${Number(reminder.amount).toLocaleString('id-ID')} telah otomatis dicatat sebagai pengeluaran rutin.`,
            metadata: {
              reminderId: reminder.id,
              walletId: reminder.walletId,
              amount: Number(reminder.amount),
            },
          });
        } catch (autoLogErr) {
          console.error(`[BillReminder] Auto-log expense failed for "${reminder.title}":`, autoLogErr.message);
        }
      }

      console.log(`[BillReminder] Notified user ${userId} for reminder "${reminder.title}" (${daysUntilDue} days)`);
    }
  } catch (err) {
    console.error('[BillReminder] Error checking reminders for user:', err.message);
  }
}

/**
 * Cek semua reminder aktif (seluruh user).
 * Berguna untuk manual trigger via endpoint /cron/bill-reminders
 * atau scheduler eksternal.
 */
async function checkBillReminders() {
  try {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());

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
      const effectiveDueDate = getEffectiveDueDate(reminder, now);
      const isPaid = await isReminderPaidForCurrentPeriod(reminder, effectiveDueDate);

      if (isPaid) continue;

      const notifyDays = reminder.notifyDaysBefore ?? 3;
      const notifyStartDate = new Date(effectiveDueDate);
      notifyStartDate.setDate(notifyStartDate.getDate() - notifyDays);
      notifyStartDate.setHours(0, 0, 0, 0);

      if (now < notifyStartDate) continue;

      if (reminder.lastNotifiedAt) {
        const lastNotified = new Date(reminder.lastNotifiedAt);
        if (lastNotified >= todayStart) continue;
      }

      const effectiveDueStart = new Date(
        effectiveDueDate.getFullYear(),
        effectiveDueDate.getMonth(),
        effectiveDueDate.getDate()
      );
      const diffMs = effectiveDueStart.getTime() - todayStart.getTime();
      const daysUntilDue = Math.round(diffMs / (1000 * 60 * 60 * 24));

      let title = 'Pengingat Tagihan';
      let dueText = '';

      if (daysUntilDue < 0) {
        title = 'Tagihan Lewat Jatuh Tempo';
        dueText = `telah lewat jatuh tempo sejak ${Math.abs(daysUntilDue)} hari lalu`;
      } else if (daysUntilDue === 0) {
        title = 'Tagihan Jatuh Tempo Hari Ini';
        dueText = 'jatuh tempo HARI INI';
      } else if (daysUntilDue === 1) {
        title = 'Pengingat Tagihan (Besok)';
        dueText = 'jatuh tempo besok';
      } else {
        dueText = `jatuh tempo dalam ${daysUntilDue} hari (${effectiveDueDate.getDate()}/${effectiveDueDate.getMonth() + 1}/${effectiveDueDate.getFullYear()})`;
      }

      await createNotification(prisma, {
        userId: reminder.userId,
        type: 'BILL_REMINDER',
        title,
        body: `Tagihan "${reminder.title}" sebesar Rp ${Number(reminder.amount).toLocaleString('id-ID')} ${dueText}.`,
        metadata: {
          reminderId: reminder.id,
          walletId: reminder.walletId,
          dueDate: effectiveDueDate,
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
  getEffectiveDueDate,
  isReminderPaidForCurrentPeriod,
  checkBillRemindersForUser,
  checkBillReminders,
};
