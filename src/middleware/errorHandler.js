// ─────────────────────────────────────────────────────────────────────────────
// Global Error Handler Middleware
// ─────────────────────────────────────────────────────────────────────────────

const { error } = require('../utils/apiResponse');

/**
 * Wraps an async route handler to catch rejected promises and forward
 * them to Express's error handler — avoids try/catch boilerplate in
 * every controller.
 *
 * Usage: router.get('/path', asyncHandler(myController));
 *
 * @param {Function} fn — async (req, res, next) => ...
 * @returns {Function}
 */
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

/**
 * Express error-handling middleware (4-arg signature).
 * Mount as the LAST middleware on the app.
 */
function globalErrorHandler(err, req, res, _next) {
  // Log the full error in dev, just the message in prod
  if (process.env.NODE_ENV === 'development') {
    console.error('─── Unhandled Error ───');
    console.error(err);
  } else {
    console.error(`[ERROR] ${err.message}`);
  }

  // Prisma known request errors
  if (err.code === 'P2002') {
    const target = err.meta?.target;
    return error(
      res,
      `A record with that ${target ? target.join(', ') : 'value'} already exists`,
      409
    );
  }

  if (err.code === 'P2025') {
    return error(res, 'Record not found', 404);
  }

  // JWT errors (shouldn't reach here if auth middleware is correct, but safety net)
  if (err.name === 'JsonWebTokenError') {
    return error(res, 'Invalid token', 401);
  }

  if (err.name === 'TokenExpiredError') {
    return error(res, 'Token expired', 401);
  }

  // Validation errors
  if (err.name === 'ValidationError') {
    return error(res, err.message, 422, err.errors);
  }

  // Default 500
  const statusCode = err.statusCode || 500;
  const message =
    process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message || 'Internal server error';

  return error(res, message, statusCode);
}

module.exports = { asyncHandler, globalErrorHandler };
