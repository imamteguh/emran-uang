const assert = require('assert');

// 1. Simulation of setCategoryBudget validation & decision logic
function processCategoryBudgetRequest({ categoryId, amount }) {
  if (!categoryId) {
    return { error: 'categoryId is required', status: 400 };
  }

  const parsedAmount = parseFloat(amount);
  if (isNaN(parsedAmount) || parsedAmount < 0) {
    return { error: 'amount must be a non-negative number', status: 400 };
  }

  if (parsedAmount === 0) {
    return { action: 'DELETE', categoryId, amount: 0 };
  }

  return { action: 'UPSERT', categoryId, amount: parsedAmount };
}

// 2. Simulation of Category budget status evaluation logic
function evaluateCategoryBudget({ limit, currentSpend }) {
  const percent = limit > 0 ? currentSpend / limit : 0;
  const remaining = limit - currentSpend;
  const isOver = currentSpend > limit;
  const isNear = percent >= 0.8 && !isOver;

  let status = 'Aman';
  if (isOver) status = 'Overbudget';
  else if (isNear) status = 'Mendekati Batas';

  return {
    limit,
    currentSpend,
    remaining,
    percent: Math.min(percent, 1.0),
    rawPercent: percent,
    isOver,
    isNear,
    status,
  };
}

// ─── Test Suite ─────────────────────────────────────────────────────────────

// Case 1: Valid upsert
const r1 = processCategoryBudgetRequest({ categoryId: 'cat_food', amount: 1500000 });
assert.strictEqual(r1.action, 'UPSERT');
assert.strictEqual(r1.amount, 1500000);
assert.strictEqual(r1.categoryId, 'cat_food');

// Case 2: String amount
const r2 = processCategoryBudgetRequest({ categoryId: 'cat_transport', amount: '750000' });
assert.strictEqual(r2.action, 'UPSERT');
assert.strictEqual(r2.amount, 750000);

// Case 3: Zero amount triggers deletion
const r3 = processCategoryBudgetRequest({ categoryId: 'cat_food', amount: 0 });
assert.strictEqual(r3.action, 'DELETE');
assert.strictEqual(r3.amount, 0);

// Case 4: Missing categoryId
const r4 = processCategoryBudgetRequest({ amount: 500000 });
assert.strictEqual(r4.status, 400);

// Case 5: Negative amount
const r5 = processCategoryBudgetRequest({ categoryId: 'cat_food', amount: -1000 });
assert.strictEqual(r5.status, 400);

// Case 6: Category budget status - Aman (< 80%)
const s1 = evaluateCategoryBudget({ limit: 1000000, currentSpend: 500000 });
assert.strictEqual(s1.status, 'Aman');
assert.strictEqual(s1.isOver, false);
assert.strictEqual(s1.isNear, false);
assert.strictEqual(s1.remaining, 500000);
assert.strictEqual(s1.percent, 0.5);

// Case 7: Category budget status - Mendekati Batas (80% - 100%)
const s2 = evaluateCategoryBudget({ limit: 1000000, currentSpend: 850000 });
assert.strictEqual(s2.status, 'Mendekati Batas');
assert.strictEqual(s2.isOver, false);
assert.strictEqual(s2.isNear, true);
assert.strictEqual(s2.remaining, 150000);

// Case 8: Category budget status - Overbudget (> 100%)
const s3 = evaluateCategoryBudget({ limit: 1000000, currentSpend: 1200000 });
assert.strictEqual(s3.status, 'Overbudget');
assert.strictEqual(s3.isOver, true);
assert.strictEqual(s3.isNear, false);
assert.strictEqual(s3.remaining, -200000);
assert.strictEqual(s3.percent, 1.0); // Clamped for progress bar
assert.strictEqual(s3.rawPercent, 1.2);

console.log('✅ All backend category budget logic and evaluation tests passed!');
