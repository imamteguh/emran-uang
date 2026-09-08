const { getEffectiveDueDate } = require('../src/utils/bill-reminder-cron');
const assert = require('assert');

// Test 1: Monthly reminder with base due date Jan 15 evaluated on Mar 10, 2026
{
  const reminder = {
    dueDate: new Date('2026-01-15T00:00:00.000Z'),
    periodicity: 'MONTHLY',
  };
  const now = new Date(2026, 2, 10); // March 10
  const effectiveDue = getEffectiveDueDate(reminder, now);
  assert.strictEqual(effectiveDue.getFullYear(), 2026);
  assert.strictEqual(effectiveDue.getMonth(), 2); // March
  assert.strictEqual(effectiveDue.getDate(), 15);
  console.log('Test 1 Passed: Monthly reminder Jan 15 evaluated in March -> March 15');
}

// Test 2: Monthly reminder on 31st evaluated in February (non-leap year)
{
  const reminder = {
    dueDate: new Date('2026-01-31T00:00:00.000Z'),
    periodicity: 'MONTHLY',
  };
  const febNow = new Date(2026, 1, 10); // February 10, 2026
  const effectiveDue = getEffectiveDueDate(reminder, febNow);
  assert.strictEqual(effectiveDue.getFullYear(), 2026);
  assert.strictEqual(effectiveDue.getMonth(), 1); // February
  assert.strictEqual(effectiveDue.getDate(), 28); // Clamped to 28
  console.log('Test 2 Passed: 31st clamped to Feb 28 in non-leap year');
}

// Test 3: Yearly reminder evaluated in subsequent year
{
  const reminder = {
    dueDate: new Date('2025-06-01T00:00:00.000Z'),
    periodicity: 'YEARLY',
  };
  const now = new Date(2026, 4, 15); // May 15, 2026
  const effectiveDue = getEffectiveDueDate(reminder, now);
  assert.strictEqual(effectiveDue.getFullYear(), 2026);
  assert.strictEqual(effectiveDue.getMonth(), 5); // June
  assert.strictEqual(effectiveDue.getDate(), 1);
  console.log('Test 3 Passed: Yearly reminder June 1 evaluated in 2026 -> June 1, 2026');
}

// Test 4: Future reminder (not reached yet)
{
  const reminder = {
    dueDate: new Date(2026, 11, 25), // Dec 25, 2026
    periodicity: 'MONTHLY',
  };
  const now = new Date(2026, 2, 10); // March 10, 2026
  const effectiveDue = getEffectiveDueDate(reminder, now);
  assert.strictEqual(effectiveDue.getMonth(), 11);
  assert.strictEqual(effectiveDue.getDate(), 25);
  console.log('Test 4 Passed: Future reminder maintains original dueDate');
}

console.log('All Node.js date calculations passed successfully!');
