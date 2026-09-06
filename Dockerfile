# ==============================================================================
# Emran Uang API — Production Dockerfile
# ==============================================================================

FROM node:20-alpine AS base

# Install OpenSSL and libc6-compat required by Prisma engine on Alpine
RUN apk add --no-cache openssl libc6-compat

WORKDIR /app

# Copy dependency definitions
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies (including devDependencies so prisma CLI is available for generate and db push)
RUN npm ci

# Generate Prisma Client
RUN npx prisma generate

# Copy source code and entrypoint script
COPY api ./api
COPY src ./src
COPY docker-entrypoint.sh ./

# Make entrypoint script executable and ensure Unix line endings
RUN chmod +x ./docker-entrypoint.sh && sed -i 's/\r$//' ./docker-entrypoint.sh

# Set default production environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["node", "api/index.js"]
