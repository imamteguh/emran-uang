// ─────────────────────────────────────────────────────────────────────────────
// Database Seed — Default Categories
// ─────────────────────────────────────────────────────────────────────────────
// Run with: npx prisma db seed
//       or: node prisma/seed.js
// ─────────────────────────────────────────────────────────────────────────────

const { PrismaClient } = require('@prisma/client');

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
  console.log('🌱 Seeding default categories...\n');

  let created = 0;
  let updated = 0;

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
      console.log(`  🔄 ${cat.icon} ${cat.name} — updated`);
      updated++;
    } else {
      await prisma.category.create({
        data: {
          name: cat.name,
          icon: cat.icon,
          color: cat.color,
          isDefault: true,
          isActive: true,
          userId: null, // system-wide
        },
      });
      console.log(`  ✅ ${cat.icon} ${cat.name} — created`);
      created++;
    }
  }

  console.log(`\n🎉 Seed complete: ${created} created, ${updated} updated.\n`);
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
