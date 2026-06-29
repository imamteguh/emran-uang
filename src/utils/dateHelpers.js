// ─────────────────────────────────────────────────────────────────────────────
// Date Range Helpers — Timeframe Calculators
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Get the start and end dates for a given timeframe.
 *
 * @param {'daily' | 'monthly' | 'yearly'} timeframe
 * @param {string | Date} [referenceDate] — defaults to today
 * @returns {{ start: Date, end: Date }}
 */
function getDateRange(timeframe, referenceDate) {
  const ref = referenceDate ? new Date(referenceDate) : new Date();

  switch (timeframe) {
    case 'daily':
      return {
        start: startOfDay(ref),
        end: endOfDay(ref),
      };
    case 'monthly':
      return {
        start: startOfMonth(ref),
        end: endOfMonth(ref),
      };
    case 'yearly':
      return {
        start: startOfYear(ref),
        end: endOfYear(ref),
      };
    default:
      // Default to monthly if unrecognized
      return {
        start: startOfMonth(ref),
        end: endOfMonth(ref),
      };
  }
}

/** @param {Date} date */
function startOfDay(date) {
  const d = new Date(date);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

/** @param {Date} date */
function endOfDay(date) {
  const d = new Date(date);
  d.setUTCHours(23, 59, 59, 999);
  return d;
}

/** @param {Date} date */
function startOfMonth(date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));
}

/** @param {Date} date */
function endOfMonth(date) {
  return new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 0, 23, 59, 59, 999)
  );
}

/** @param {Date} date */
function startOfYear(date) {
  return new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
}

/** @param {Date} date */
function endOfYear(date) {
  return new Date(Date.UTC(date.getUTCFullYear(), 11, 31, 23, 59, 59, 999));
}

/**
 * Get the previous month's date range relative to a reference date.
 * @param {string | Date} [referenceDate]
 * @returns {{ start: Date, end: Date }}
 */
function getPreviousMonthRange(referenceDate) {
  const ref = referenceDate ? new Date(referenceDate) : new Date();
  const prev = new Date(Date.UTC(ref.getUTCFullYear(), ref.getUTCMonth() - 1, 1));
  return {
    start: startOfMonth(prev),
    end: endOfMonth(prev),
  };
}

/**
 * Parse pagination params from query string with safe defaults.
 * @param {{ page?: string, limit?: string }} query
 * @returns {{ page: number, limit: number, skip: number }}
 */
function parsePagination(query) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 20));
  return { page, limit, skip: (page - 1) * limit };
}

module.exports = {
  getDateRange,
  startOfDay,
  endOfDay,
  startOfMonth,
  endOfMonth,
  startOfYear,
  endOfYear,
  getPreviousMonthRange,
  parsePagination,
};
