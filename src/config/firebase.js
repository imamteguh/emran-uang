// ─────────────────────────────────────────────────────────────────────────────
// Firebase Admin Configuration — Graceful Initialization
// ─────────────────────────────────────────────────────────────────────────────

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let firebaseAdminInstance = null;

try {
  let serviceAccount = null;

  // 1. Try to load service account credentials from environmental JSON
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      console.log('[Firebase] Loaded service account credentials from FIREBASE_SERVICE_ACCOUNT env var.');
    } catch (parseError) {
      console.error('[Firebase] Failed to parse FIREBASE_SERVICE_ACCOUNT env var as JSON:', parseError.message);
    }
  }

  // 2. Try to load from file path specified in env
  if (!serviceAccount && process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    const fullPath = path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
    if (fs.existsSync(fullPath)) {
      try {
        serviceAccount = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
        console.log(`[Firebase] Loaded service account credentials from file: ${fullPath}`);
      } catch (readError) {
        console.error(`[Firebase] Failed to read or parse service account file at ${fullPath}:`, readError.message);
      }
    } else {
      console.warn(`[Firebase] Service account file not found at path: ${fullPath}`);
    }
  }

  // 3. Fallback: try default file name in project root (for easy dev drop-in)
  if (!serviceAccount) {
    const defaultPath = path.resolve(__dirname, '../../firebase-service-account.json');
    if (fs.existsSync(defaultPath)) {
      try {
        serviceAccount = JSON.parse(fs.readFileSync(defaultPath, 'utf8'));
        console.log('[Firebase] Found default firebase-service-account.json in project root. Initializing...');
      } catch (readError) {
        console.error('[Firebase] Failed to read/parse default firebase-service-account.json:', readError.message);
      }
    }
  }

  // Initialize Firebase Admin if credentials found
  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.cert(serviceAccount),
    });
    firebaseAdminInstance = admin;
    console.log('[Firebase] Firebase Admin SDK initialized successfully.');
  } else {
    console.warn('[Firebase] Warning: No service account credentials found. Push notifications are disabled.');
  }
} catch (error) {
  console.error('[Firebase] Failed to initialize Firebase Admin SDK:', error.message);
}

module.exports = firebaseAdminInstance;
