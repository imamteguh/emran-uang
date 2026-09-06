#!/bin/sh
set -e

echo "==> [Emran Uang API] Initializing container..."

# Run database push if requested (helpful for initial setup or schema updates)
if [ "$RUN_DB_PUSH" = "true" ]; then
  echo "==> [Prisma] Synchronizing database schema with 'prisma db push'..."
  # Try running prisma db push with retries in case database container is still booting
  MAX_RETRIES=15
  COUNT=0
  until npx prisma db push --skip-generate || [ $COUNT -ge $MAX_RETRIES ]; do
    COUNT=$((COUNT + 1))
    echo "==> [Prisma] Database not ready yet, retrying in 2s ($COUNT/$MAX_RETRIES)..."
    sleep 2
  done

  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "==> [Error] Failed to connect and push schema to database after $MAX_RETRIES attempts."
    exit 1
  fi
  echo "==> [Prisma] Database schema synchronized successfully."
fi

# Run database seed if requested
if [ "$RUN_DB_SEED" = "true" ]; then
  echo "==> [Prisma] Seeding database..."
  npm run db:seed || echo "==> [Prisma] Seed finished or skipped."
fi

echo "==> [Emran Uang API] Starting application..."
exec "$@"
