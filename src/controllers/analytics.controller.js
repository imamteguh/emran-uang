// ─────────────────────────────────────────────────────────────────────────────
// Analytics Controller — Monthly Comparison, Breakdown & Trend
// ─────────────────────────────────────────────────────────────────────────────

const prisma = require('../config/prisma');
const { success, error } = require('../utils/apiResponse');
const {
  getDateRange,
  getPreviousMonthRange,
  startOfMonth,
  endOfMonth,
} = require('../utils/dateHelpers');

// ─── Compare Current vs Previous Month ──────────────────────────────────────

async function compareMonths(req, res) {
  const { date, months } = req.query;
  const walletId = req.wallet.id;
  const refDate = date ? new Date(date) : new Date();
  const monthCount = Math.min(12, Math.max(1, parseInt(months, 10) || 2));

  const results = [];

  for (let i = 0; i < monthCount; i++) {
    const monthDate = new Date(
      Date.UTC(refDate.getUTCFullYear(), refDate.getUTCMonth() - i, 1)
    );
    const start = startOfMonth(monthDate);
    const end = endOfMonth(monthDate);

    const [totalAgg, byCategory, byType] = await Promise.all([
      // Total for the month
      prisma.expense.aggregate({
        where: { walletId, date: { gte: start, lte: end } },
        _sum: { amount: true },
        _count: { id: true },
      }),

      // Breakdown by category
      prisma.expense.groupBy({
        by: ['categoryId'],
        where: { walletId, date: { gte: start, lte: end } },
        _sum: { amount: true },
        _count: { id: true },
        orderBy: { _sum: { amount: 'desc' } },
      }),

      // Breakdown by type (routine vs non-routine)
      prisma.expense.groupBy({
        by: ['type'],
        where: { walletId, date: { gte: start, lte: end } },
        _sum: { amount: true },
        _count: { id: true },
      }),
    ]);

    // Enrich category names
    const categoryIds = byCategory.map((c) => c.categoryId);
    const categories = await prisma.category.findMany({
      where: { id: { in: categoryIds } },
      select: { id: true, name: true, icon: true, color: true },
    });
    const categoryMap = Object.fromEntries(categories.map((c) => [c.id, c]));

    results.push({
      month: `${monthDate.getUTCFullYear()}-${String(monthDate.getUTCMonth() + 1).padStart(2, '0')}`,
      total: totalAgg._sum.amount || 0,
      count: totalAgg._count.id || 0,
      byCategory: byCategory.map((c) => ({
        category: categoryMap[c.categoryId] || { id: c.categoryId },
        total: c._sum.amount || 0,
        count: c._count.id || 0,
      })),
      byType: byType.map((t) => ({
        type: t.type,
        total: t._sum.amount || 0,
        count: t._count.id || 0,
      })),
    });
  }

  // Calculate change percentage between current and previous month
  const comparison = {
    months: results,
  };

  if (results.length >= 2) {
    const current = Number(results[0].total);
    const previous = Number(results[1].total);
    const change = previous > 0 ? ((current - previous) / previous) * 100 : null;

    comparison.summary = {
      currentMonth: results[0].month,
      previousMonth: results[1].month,
      currentTotal: current,
      previousTotal: previous,
      changePercent: change !== null ? Math.round(change * 100) / 100 : null,
      direction: change > 0 ? 'increased' : change < 0 ? 'decreased' : 'unchanged',
    };
  }

  return success(res, comparison);
}

// ─── Category Breakdown ─────────────────────────────────────────────────────

async function breakdown(req, res) {
  const { timeframe, date } = req.query;
  const walletId = req.wallet.id;
  const range = getDateRange(timeframe || 'monthly', date);

  const [groups, totalAgg] = await Promise.all([
    prisma.expense.groupBy({
      by: ['categoryId'],
      where: {
        walletId,
        date: { gte: range.start, lte: range.end },
      },
      _sum: { amount: true },
      _count: { id: true },
      orderBy: { _sum: { amount: 'desc' } },
    }),
    prisma.expense.aggregate({
      where: {
        walletId,
        date: { gte: range.start, lte: range.end },
      },
      _sum: { amount: true },
    }),
  ]);

  const grandTotal = Number(totalAgg._sum.amount || 0);

  // Enrich category details
  const categoryIds = groups.map((g) => g.categoryId);
  const categories = await prisma.category.findMany({
    where: { id: { in: categoryIds } },
    select: { id: true, name: true, icon: true, color: true },
  });
  const categoryMap = Object.fromEntries(categories.map((c) => [c.id, c]));

  const data = groups.map((g) => {
    const total = Number(g._sum.amount || 0);
    return {
      category: categoryMap[g.categoryId] || { id: g.categoryId },
      total,
      count: g._count.id || 0,
      percentage: grandTotal > 0 ? Math.round((total / grandTotal) * 10000) / 100 : 0,
    };
  });

  return success(res, {
    range: { start: range.start, end: range.end },
    grandTotal,
    categories: data,
  });
}

// ─── Daily Spending Trend ───────────────────────────────────────────────────

async function trend(req, res) {
  const { date } = req.query;
  const walletId = req.wallet.id;
  const range = getDateRange('monthly', date);

  const dailyData = await prisma.expense.groupBy({
    by: ['date'],
    where: {
      walletId,
      date: { gte: range.start, lte: range.end },
    },
    _sum: { amount: true },
    _count: { id: true },
    orderBy: { date: 'asc' },
  });

  // Fill in days with zero spending for a complete trend line
  const days = [];
  const dataMap = new Map(
    dailyData.map((d) => [
      new Date(d.date).toISOString().split('T')[0],
      { total: d._sum.amount || 0, count: d._count.id || 0 },
    ])
  );

  const cursor = new Date(range.start);
  while (cursor <= range.end) {
    const key = cursor.toISOString().split('T')[0];
    days.push({
      date: key,
      total: dataMap.get(key)?.total || 0,
      count: dataMap.get(key)?.count || 0,
    });
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }

  return success(res, {
    month: `${range.start.getUTCFullYear()}-${String(range.start.getUTCMonth() + 1).padStart(2, '0')}`,
    days,
  });
}

module.exports = { compareMonths, breakdown, trend };
