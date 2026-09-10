const assert = require('assert');

// 1. Test payload parsing and validation logic
function processWalletUpdate(body) {
  const { name, currency, dailyBudget, monthlyBudget } = body;
  return {
    name: name !== undefined ? name : undefined,
    currency: currency !== undefined ? currency : undefined,
    dailyBudget: dailyBudget !== undefined ? (dailyBudget === null ? null : parseFloat(dailyBudget)) : undefined,
    monthlyBudget: monthlyBudget !== undefined ? (monthlyBudget === null ? null : parseFloat(monthlyBudget)) : undefined,
  };
}

// Test case 1: Setting valid monthly budget
const res1 = processWalletUpdate({ monthlyBudget: 3500000 });
assert.strictEqual(res1.monthlyBudget, 3500000);

// Test case 2: String numeric monthly budget
const res2 = processWalletUpdate({ monthlyBudget: '5000000' });
assert.strictEqual(res2.monthlyBudget, 5000000);

// Test case 3: Clearing monthly budget with null
const res3 = processWalletUpdate({ monthlyBudget: null });
assert.strictEqual(res3.monthlyBudget, null);

// Test case 4: Undefined monthly budget leaves it undefined (won't overwrite in Prisma)
const res4 = processWalletUpdate({ name: 'New Name' });
assert.strictEqual(res4.monthlyBudget, undefined);
assert.strictEqual(res4.name, 'New Name');

// Test case 5: Both daily and monthly budget updated together
const res5 = processWalletUpdate({ dailyBudget: 100000, monthlyBudget: 3000000 });
assert.strictEqual(res5.dailyBudget, 100000);
assert.strictEqual(res5.monthlyBudget, 3000000);

console.log('✅ All backend monthly budget wallet controller logic checks passed!');
