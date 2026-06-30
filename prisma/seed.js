// ─────────────────────────────────────────────────────────────────────────────
// Database Seed — Default Categories, Users, Wallets, Expenses & Reminders
// ─────────────────────────────────────────────────────────────────────────────
// Run with: npx prisma db seed
//       or: node prisma/seed.js
// ─────────────────────────────────────────────────────────────────────────────

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

const DEFAULT_CATEGORIES = [
  { name: 'Food & Drinks', icon: 'restaurant', color: '#FF6B6B' },
  { name: 'Housing', icon: 'home', color: '#4ECDC4' },
  { name: 'Transport', icon: 'directions_car', color: '#45B7D1' },
  { name: 'Groceries', icon: 'shopping_cart', color: '#96CEB4' },
  { name: 'Utilities', icon: 'lightbulb', color: '#FFEAA7' },
  { name: 'Entertainment', icon: 'movie', color: '#DDA0DD' },
  { name: 'Healthcare', icon: 'local_hospital', color: '#98D8C8' },
  { name: 'Shopping', icon: 'shopping_bag', color: '#F7DC6F' },
  { name: 'Education', icon: 'school', color: '#BB8FCE' },
  { name: 'Travel', icon: 'flight', color: '#85C1E9' },
  { name: 'Date Night', icon: 'favorite', color: '#FF69B4' },
  { name: 'Subscriptions', icon: 'subscriptions', color: '#AED6F1' },
  { name: 'Pets', icon: 'pets', color: '#F0B27A' },
  { name: 'Gifts', icon: 'card_giftcard', color: '#E6B0AA' },
  { name: 'Other', icon: 'help_outline', color: '#BDC3C7' },
];

async function main() {
  console.log('🌱 Seeding database with rich sample data...\n');

  // 1. Seed categories
  console.log('1. Seeding default categories...');
  for (const cat of DEFAULT_CATEGORIES) {
    const existing = await prisma.category.findFirst({
      where: {
        name: cat.name,
        isDefault: true,
        userId: null,
      },
    });

    if (existing) {
      await prisma.category.update({
        where: { id: existing.id },
        data: {
          icon: cat.icon,
          color: cat.color,
        },
      });
    } else {
      await prisma.category.create({
        data: {
          name: cat.name,
          icon: cat.icon,
          color: cat.color,
          isDefault: true,
          isActive: true,
          userId: null,
        },
      });
    }
  }
  const dbCategories = await prisma.category.findMany({ where: { userId: null } });
  const categoryMap = Object.fromEntries(dbCategories.map((c) => [c.name, c.id]));
  console.log('   Categories seeded successfully.');

  // 2. Clean up existing test users if they exist (safe cascaded cleanup)
  console.log('2. Cleaning up previous seed users...');
  const emails = ['user@example.com', 'partner@example.com'];
  const existingUsers = await prisma.user.findMany({
    where: { email: { in: emails } },
    select: { id: true },
  });
  const userIds = existingUsers.map((u) => u.id);

  if (userIds.length > 0) {
    // Delete expenses created by user or in user's wallets
    const seedWallets = await prisma.wallet.findMany({
      where: { OR: [{ userId: { in: userIds } }, { group: { members: { some: { userId: { in: userIds } } } } }] },
      select: { id: true },
    });
    const walletIds = seedWallets.map((w) => w.id);

    await prisma.expense.deleteMany({
      where: { OR: [{ userId: { in: userIds } }, { walletId: { in: walletIds } }] },
    });

    await prisma.billReminder.deleteMany({
      where: { OR: [{ userId: { in: userIds } }, { walletId: { in: walletIds } }] },
    });

    await prisma.wallet.deleteMany({
      where: { id: { in: walletIds } },
    });

    await prisma.sharedGroupInvite.deleteMany({
      where: { OR: [{ senderId: { in: userIds } }, { receiverId: { in: userIds } }] },
    });

    await prisma.sharedGroupMember.deleteMany({
      where: { userId: { in: userIds } },
    });

    // Delete groups where no members remain
    const groups = await prisma.sharedGroup.findMany({
      include: { members: true },
    });
    for (const g of groups) {
      if (g.members.length === 0) {
        await prisma.sharedGroup.delete({ where: { id: g.id } });
      }
    }

    await prisma.user.deleteMany({
      where: { id: { in: userIds } },
    });
    console.log(`   Cleaned up ${userIds.length} test users.`);
  }

  // 3. Create users
  console.log('3. Seeding users...');
  const hashedPassword = await bcrypt.hash('password123', 10);
  const userA = await prisma.user.create({
    data: {
      email: 'user@example.com',
      displayName: 'Emran Uang',
      passwordHash: hashedPassword,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
    },
  });

  const userB = await prisma.user.create({
    data: {
      email: 'partner@example.com',
      displayName: 'Lina Bersama',
      passwordHash: hashedPassword,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200',
    },
  });
  console.log('   Users created: user@example.com & partner@example.com.');

  // 4. Create personal wallets
  console.log('4. Seeding wallets...');
  const walletA = await prisma.wallet.create({
    data: {
      name: 'Dompet Pribadi Emran',
      type: 'PERSONAL',
      currency: 'IDR',
      userId: userA.id,
      dailyBudget: 150000.0,
    },
  });

  const walletB = await prisma.wallet.create({
    data: {
      name: 'Dompet Pribadi Lina',
      type: 'PERSONAL',
      currency: 'IDR',
      userId: userB.id,
      dailyBudget: 120000.0,
    },
  });

  // 5. Create shared group & shared wallet
  const group = await prisma.sharedGroup.create({
    data: {
      name: 'Keuangan Keluarga',
      status: 'ACTIVE',
    },
  });

  await prisma.sharedGroupMember.createMany({
    data: [
      { userId: userA.id, groupId: group.id, role: 'OWNER' },
      { userId: userB.id, groupId: group.id, role: 'MEMBER' },
    ],
  });

  const sharedWallet = await prisma.wallet.create({
    data: {
      name: 'Tabungan Bersama',
      type: 'SHARED',
      currency: 'IDR',
      groupId: group.id,
      dailyBudget: 500000.0,
    },
  });
  console.log('   Wallets created: personal and shared wallets.');

  // 6. Create bill reminders
  console.log('6. Seeding bill reminders...');
  await prisma.billReminder.createMany({
    data: [
      {
        title: 'Netflix Family Plan',
        amount: 186000.0,
        dueDate: new Date('2026-07-05'),
        periodicity: 'MONTHLY',
        status: 'ACTIVE',
        userId: userA.id,
        walletId: walletA.id,
        categoryId: categoryMap['Subscriptions'] || null,
        autoLogExpense: true,
      },
      {
        title: 'Wifi Indihome',
        amount: 385000.0,
        dueDate: new Date('2026-07-15'),
        periodicity: 'MONTHLY',
        status: 'ACTIVE',
        userId: userA.id,
        walletId: sharedWallet.id,
        categoryId: categoryMap['Utilities'] || null,
        autoLogExpense: true,
      },
      {
        title: 'Electricity Token',
        amount: 500000.0,
        dueDate: new Date('2026-07-20'),
        periodicity: 'MONTHLY',
        status: 'ACTIVE',
        userId: userB.id,
        walletId: sharedWallet.id,
        categoryId: categoryMap['Utilities'] || null,
        autoLogExpense: false,
      },
    ],
  });
  console.log('   Bill reminders seeded.');

  // 7. Seed expenses spanning 4 months (March, April, May, June 2026)
  console.log('7. Seeding historical expenses (March - June 2026)...');

  const months = [
    { year: 2026, month: 2, name: 'March' }, // 0-indexed month
    { year: 2026, month: 3, name: 'April' },
    { year: 2026, month: 4, name: 'May' },
    { year: 2026, month: 5, name: 'June' },
  ];

  const personalExpenseTemplates = [
    { category: 'Food & Drinks', desc: 'Makan Siang Bakso', amount: 35000, type: 'NON_ROUTINE', dayOffset: 2 },
    { category: 'Food & Drinks', desc: 'Kopi Kenangan', amount: 28000, type: 'NON_ROUTINE', dayOffset: 5 },
    { category: 'Transport', desc: 'Bensin Motor', amount: 50000, type: 'NON_ROUTINE', dayOffset: 8 },
    { category: 'Entertainment', desc: 'Tiket Bioskop', amount: 45000, type: 'NON_ROUTINE', dayOffset: 12 },
    { category: 'Groceries', desc: 'Camilan Minimarket', amount: 72000, type: 'NON_ROUTINE', dayOffset: 15 },
    { category: 'Subscriptions', desc: 'Spotify Premium', amount: 55000, type: 'ROUTINE', dayOffset: 1 },
    { category: 'Utilities', desc: 'Pulsa & Data', amount: 150000, type: 'ROUTINE', dayOffset: 10 },
  ];

  const sharedExpenseTemplates = [
    { category: 'Housing', desc: 'Biaya Kontrakan Bulanan', amount: 1800000, type: 'ROUTINE', dayOffset: 1, logger: 'userA' },
    { category: 'Groceries', desc: 'Belanja Bulanan Sayur & Beras', amount: 650000, type: 'NON_ROUTINE', dayOffset: 3, logger: 'userA' },
    { category: 'Utilities', desc: 'Listrik Rumah', amount: 350000, type: 'ROUTINE', dayOffset: 10, logger: 'userB' },
    { category: 'Food & Drinks', desc: 'Makan Malam Keluarga', amount: 280000, type: 'NON_ROUTINE', dayOffset: 14, logger: 'userA' },
    { category: 'Food & Drinks', desc: 'Gofood Weekend', amount: 120000, type: 'NON_ROUTINE', dayOffset: 22, logger: 'userB' },
    { category: 'Groceries', desc: 'Kebutuhan Kamar Mandi & Dapur', amount: 220000, type: 'NON_ROUTINE', dayOffset: 25, logger: 'userB' },
  ];

  let expenseCount = 0;

  for (const m of months) {
    // Generate dates inside the month
    const baseDate = new Date(Date.UTC(m.year, m.month, 1));
    const multiplier = 1.0 + (m.month - 2) * 0.1; // March: 1.0, April: 1.1, May: 1.2, June: 1.3 to create spending trend

    // ── Feed Personal Expenses ──
    for (const t of personalExpenseTemplates) {
      const expDate = new Date(Date.UTC(m.year, m.month, t.dayOffset, 12, 0, 0));
      const categoryId = categoryMap[t.category] || categoryMap['Other'];
      const finalAmount = Math.round(t.amount * multiplier);

      await prisma.expense.create({
        data: {
          amount: finalAmount,
          description: t.desc,
          date: expDate,
          type: t.type,
          userId: userA.id,
          walletId: walletA.id,
          categoryId,
        },
      });
      expenseCount++;
    }

    // ── Feed Shared Expenses ──
    for (const t of sharedExpenseTemplates) {
      const expDate = new Date(Date.UTC(m.year, m.month, t.dayOffset, 14, 0, 0));
      const categoryId = categoryMap[t.category] || categoryMap['Other'];
      const finalAmount = Math.round(t.amount * multiplier);
      const loggerId = t.logger === 'userA' ? userA.id : userB.id;

      await prisma.expense.create({
        data: {
          amount: finalAmount,
          description: t.desc,
          date: expDate,
          type: t.type,
          userId: loggerId,
          walletId: sharedWallet.id,
          categoryId,
        },
      });
      expenseCount++;
    }
  }

  console.log(`   Seeded ${expenseCount} historical expenses across 4 months successfully.`);
  console.log('\n🎉 Database seeding finished successfully!\n');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
