const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🚀 Starting database reset (preserving default categories)...');
  
  console.log('1. Clearing expenses...');
  await prisma.expense.deleteMany({});
  
  console.log('2. Clearing bill reminders...');
  await prisma.billReminder.deleteMany({});
  
  console.log('3. Clearing shared group invites...');
  await prisma.sharedGroupInvite.deleteMany({});
  
  console.log('4. Clearing shared group members...');
  await prisma.sharedGroupMember.deleteMany({});
  
  console.log('5. Clearing wallets...');
  await prisma.wallet.deleteMany({});
  
  console.log('6. Clearing shared groups...');
  await prisma.sharedGroup.deleteMany({});
  
  console.log('7. Clearing users...');
  await prisma.user.deleteMany({});
  
  console.log('8. Clearing custom categories (if any)...');
  await prisma.category.deleteMany({
    where: {
      isDefault: false
    }
  });

  console.log('Checking remaining categories:');
  const categories = await prisma.category.findMany({});
  console.log(`Remaining categories count: ${categories.length}`);
  
  console.log('✅ Database reset completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Reset failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
