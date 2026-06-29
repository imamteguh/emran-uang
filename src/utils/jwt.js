// ─────────────────────────────────────────────────────────────────────────────
// JWT Utilities — Sign & Verify
// ─────────────────────────────────────────────────────────────────────────────

const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret';
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '30d';

/**
 * Generate an access token for the given user ID.
 * @param {string} userId
 * @returns {string} JWT access token
 */
function generateAccessToken(userId) {
  return jwt.sign({ sub: userId }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

/**
 * Generate a refresh token for the given user ID.
 * @param {string} userId
 * @returns {string} JWT refresh token
 */
function generateRefreshToken(userId) {
  return jwt.sign({ sub: userId }, JWT_REFRESH_SECRET, {
    expiresIn: JWT_REFRESH_EXPIRES_IN,
  });
}

/**
 * Verify an access token and return the decoded payload.
 * @param {string} token
 * @returns {{ sub: string }} decoded JWT payload
 * @throws {jwt.JsonWebTokenError}
 */
function verifyAccessToken(token) {
  return jwt.verify(token, JWT_SECRET);
}

/**
 * Verify a refresh token and return the decoded payload.
 * @param {string} token
 * @returns {{ sub: string }}
 * @throws {jwt.JsonWebTokenError}
 */
function verifyRefreshToken(token) {
  return jwt.verify(token, JWT_REFRESH_SECRET);
}

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
};
