// ─────────────────────────────────────────────────────────────────────────────
// Authentication Middleware — JWT & Google ID Token
// ─────────────────────────────────────────────────────────────────────────────

const { verifyAccessToken } = require('../utils/jwt');
const { error } = require('../utils/apiResponse');
const prisma = require('../config/prisma');

/**
 * Middleware that verifies the JWT from the Authorization header.
 * Attaches `req.user` (full user record) on success.
 *
 * Usage: router.get('/protected', authenticate, handler);
 */
async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return error(res, 'Missing or invalid Authorization header', 401);
    }

    const token = authHeader.split(' ')[1];

    let payload;
    try {
      payload = verifyAccessToken(token);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return error(res, 'Token expired', 401);
      }
      return error(res, 'Invalid token', 401);
    }

    // Fetch the full user from DB to ensure they still exist
    const user = await prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        email: true,
        displayName: true,
        avatarUrl: true,
        authProvider: true,
        createdAt: true,
      },
    });

    if (!user) {
      return error(res, 'User not found', 401);
    }

    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { authenticate };
