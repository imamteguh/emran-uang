// ─────────────────────────────────────────────────────────────────────────────
// Bill Reminder Check Middleware
//
// Secara otomatis mengecek bill reminder milik user yang sedang aktif
// setiap kali mereka mengakses endpoint notifikasi.
//
// Pendekatan event-driven ini menggantikan Vercel Cron (Pro Plan only)
// dan `setInterval` (tidak efektif di serverless environment).
// ─────────────────────────────────────────────────────────────────────────────

const { checkBillRemindersForUser } = require('../utils/bill-reminder-cron');

/**
 * Middleware: cek dan buat notifikasi bill reminder untuk user aktif.
 *
 * - Non-blocking: error di sini TIDAK menggagalkan response
 * - Idempoten: skip jika sudah dinotifikasi hari ini (via lastNotifiedAt)
 */
async function billReminderCheck(req, res, next) {
  // Jalankan pengecekan di background — tidak tunggu hasilnya
  // agar latency GET /notifications tidak terpengaruh
  checkBillRemindersForUser(req.user.id).catch((err) => {
    console.error('[BillReminderCheck] Background check failed:', err.message);
  });

  next();
}

module.exports = { billReminderCheck };
