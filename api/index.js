// ─────────────────────────────────────────────────────────────────────────────
// Emran Uang API — Vercel Serverless Entry Point
// ─────────────────────────────────────────────────────────────────────────────
// All routes are mounted on a single Express app. Vercel's vercel.json
// rewrites /api/* to this one serverless function, so every route shares
// the same cold-start and connection pool.
// ─────────────────────────────────────────────────────────────────────────────

// Load environment variables in development
if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
}

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const { globalErrorHandler } = require('../src/middleware/errorHandler');

// ── Route Imports ────────────────────────────────────────────────────────────
const authRoutes = require('../src/routes/auth.routes');
const expenseRoutes = require('../src/routes/expense.routes');
const analyticsRoutes = require('../src/routes/analytics.routes');
const reminderRoutes = require('../src/routes/reminder.routes');
const walletRoutes = require('../src/routes/wallet.routes');
const categoryRoutes = require('../src/routes/category.routes');
const sharingRoutes = require('../src/routes/sharing.routes');
const notificationRoutes = require('../src/routes/notification.routes');
const ocrRoutes = require('../src/routes/ocr.routes');
const chatRoutes = require('../src/routes/chat.routes');

// ── Express App ──────────────────────────────────────────────────────────────
const app = express();

// ── Global Middleware ────────────────────────────────────────────────────────
app.use(helmet());

const isDev = process.env.NODE_ENV !== 'production';
app.use(
  cors({
    origin: isDev
      ? true
      : (process.env.ALLOWED_ORIGINS
          ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
          : '*'),
    credentials: true,
  })
);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Rate limiting — 500 requests per 15 minutes per IP
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: isDev ? 1000 : 500,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many requests. Please try again later.',
  },
});
app.use('/api/', limiter);

// ── Health Check ─────────────────────────────────────────────────────────────
app.get('/api', (req, res) => {
  res.json({
    success: true,
    message: 'WalletShare API is running!',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// ── Mount Routes ─────────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/reminders', reminderRoutes);
app.use('/api/wallets', walletRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/sharing', sharingRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/ocr', ocrRoutes);
app.use('/api/chat', chatRoutes);

// ── 404 Handler ──────────────────────────────────────────────────────────────
app.use('/api/*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found`,
  });
});

// ── Global Error Handler (must be last) ──────────────────────────────────────
app.use(globalErrorHandler);

// ── Server Listener (Standalone / Docker / Local) ───────────────────────────
// When running directly (e.g. node api/index.js, Docker, PM2), start the HTTP server.
// When deployed on Vercel serverless, require.main !== module and Vercel wraps the exported app.
const isStandalone = require.main === module || process.env.RUN_STANDALONE === 'true';

if (isStandalone || process.env.NODE_ENV !== 'production') {
  const PORT = process.env.PORT || 3000;
  const HOST = process.env.HOST || '0.0.0.0';
  app.listen(PORT, HOST, () => {
    console.log(`\nWalletShare API running at http://${HOST}:${PORT}/api\n`);
  });
}

// Export for Vercel
module.exports = app;
