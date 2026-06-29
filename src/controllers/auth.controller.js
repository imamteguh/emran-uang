// ─────────────────────────────────────────────────────────────────────────────
// Auth Controller — Register, Login, Google Auth
// ─────────────────────────────────────────────────────────────────────────────

const bcrypt = require('bcryptjs');
const { OAuth2Client } = require('google-auth-library');
const prisma = require('../config/prisma');
const { generateAccessToken, generateRefreshToken, verifyRefreshToken } = require('../utils/jwt');
const { success, created, error } = require('../utils/apiResponse');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// ─── Register (Email/Password) ──────────────────────────────────────────────

async function register(req, res) {
  const { email, password, displayName } = req.body;

  // Validation
  if (!email || !password || !displayName) {
    return error(res, 'email, password, and displayName are required', 400);
  }

  if (password.length < 8) {
    return error(res, 'Password must be at least 8 characters', 400);
  }

  const normalizedEmail = email.toLowerCase().trim();

  // Check if email already exists
  const existingUser = await prisma.user.findUnique({
    where: { email: normalizedEmail },
  });
  if (existingUser) {
    return error(res, 'An account with this email already exists', 409);
  }

  // Hash password
  const passwordHash = await bcrypt.hash(password, 12);

  // Create user + personal wallet in a transaction
  const user = await prisma.$transaction(async (tx) => {
    const newUser = await tx.user.create({
      data: {
        email: normalizedEmail,
        passwordHash,
        displayName: displayName.trim(),
        authProvider: 'EMAIL',
      },
    });

    // Create default personal wallet
    await tx.wallet.create({
      data: {
        name: 'Personal Wallet',
        type: 'PERSONAL',
        currency: 'IDR',
        userId: newUser.id,
      },
    });

    // Link any pending invites for this email
    await tx.sharedGroupInvite.updateMany({
      where: {
        receiverEmail: normalizedEmail,
        status: 'PENDING',
        receiverId: null,
      },
      data: {
        receiverId: newUser.id,
      },
    });

    return newUser;
  });

  // Generate tokens
  const accessToken = generateAccessToken(user.id);
  const refreshToken = generateRefreshToken(user.id);

  return created(res, {
    user: sanitizeUser(user),
    accessToken,
    refreshToken,
  }, 'Registration successful');
}

// ─── Login (Email/Password) ─────────────────────────────────────────────────

async function login(req, res) {
  const { email, password } = req.body;

  if (!email || !password) {
    return error(res, 'email and password are required', 400);
  }

  const user = await prisma.user.findUnique({
    where: { email: email.toLowerCase().trim() },
  });

  if (!user || !user.passwordHash) {
    return error(res, 'Invalid email or password', 401);
  }

  const isValid = await bcrypt.compare(password, user.passwordHash);
  if (!isValid) {
    return error(res, 'Invalid email or password', 401);
  }

  const accessToken = generateAccessToken(user.id);
  const refreshToken = generateRefreshToken(user.id);

  return success(res, {
    user: sanitizeUser(user),
    accessToken,
    refreshToken,
  }, 'Login successful');
}

// ─── Google Auth (ID Token) ─────────────────────────────────────────────────

async function googleAuth(req, res) {
  const { idToken, accessToken: googleAccessToken } = req.body;

  if (!idToken && !googleAccessToken) {
    return error(res, 'Google idToken or accessToken is required', 400);
  }

  let payload;

  if (idToken) {
    // Verify the Google ID Token
    try {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
      payload = ticket.getPayload();
    } catch (err) {
      if (!googleAccessToken) {
        return error(res, 'Invalid Google ID token', 401);
      }
    }
  }

  if (!payload && googleAccessToken) {
    // Verify using Access Token via Google UserInfo API
    try {
      const response = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
        headers: { 'Authorization': `Bearer ${googleAccessToken}` },
      });
      if (!response.ok) {
        throw new Error('Google UserInfo API returned error status');
      }
      payload = await response.json();
    } catch (err) {
      return error(res, 'Invalid Google Access token', 401);
    }
  }

  if (!payload) {
    return error(res, 'Could not authenticate Google user', 401);
  }

  const { sub: googleId, email, name, picture } = payload;

  if (!email) {
    return error(res, 'Google account does not have an email', 400);
  }

  // Upsert: find by googleId or email, create if not exists
  let user = await prisma.user.findFirst({
    where: {
      OR: [{ googleId }, { email: email.toLowerCase() }],
    },
  });

  let isNewUser = false;

  if (!user) {
    // New user — create with personal wallet
    isNewUser = true;
    user = await prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          email: email.toLowerCase(),
          displayName: name || email.split('@')[0],
          avatarUrl: picture || null,
          authProvider: 'GOOGLE',
          googleId,
        },
      });

      await tx.wallet.create({
        data: {
          name: 'Personal Wallet',
          type: 'PERSONAL',
          currency: 'IDR',
          userId: newUser.id,
        },
      });

      // Link any pending invites for this email
      await tx.sharedGroupInvite.updateMany({
        where: {
          receiverEmail: email.toLowerCase(),
          status: 'PENDING',
          receiverId: null,
        },
        data: {
          receiverId: newUser.id,
        },
      });

      return newUser;
    });
  } else if (!user.googleId) {
    // Existing email user linking Google account
    user = await prisma.user.update({
      where: { id: user.id },
      data: {
        googleId,
        avatarUrl: user.avatarUrl || picture,
        authProvider: 'GOOGLE',
      },
    });
  }

  const accessToken = generateAccessToken(user.id);
  const refreshToken = generateRefreshToken(user.id);

  return success(res, {
    user: sanitizeUser(user),
    accessToken,
    refreshToken,
    isNewUser,
  }, isNewUser ? 'Account created via Google' : 'Google login successful');
}

// ─── Get Current User ───────────────────────────────────────────────────────

async function getMe(req, res) {
  const user = await prisma.user.findUnique({
    where: { id: req.user.id },
    include: {
      wallets: {
        select: { id: true, name: true, type: true, currency: true, groupId: true },
      },
      sharedGroupMembers: {
        where: { group: { status: 'ACTIVE' } },
        include: {
          group: {
            include: {
              members: {
                include: {
                  user: {
                    select: { id: true, displayName: true, avatarUrl: true },
                  },
                },
              },
            },
          },
        },
      },
    },
  });

  if (!user) {
    return error(res, 'User not found', 404);
  }

  return success(res, {
    ...sanitizeUser(user),
    wallets: user.wallets,
    sharedGroups: user.sharedGroupMembers.map((m) => m.group),
  });
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function sanitizeUser(user) {
  return {
    id: user.id,
    email: user.email,
    displayName: user.displayName,
    avatarUrl: user.avatarUrl,
    authProvider: user.authProvider,
    createdAt: user.createdAt,
  };
}

// ─── Refresh Token ──────────────────────────────────────────────────────────

async function refresh(req, res) {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return error(res, 'Refresh token is required', 400);
  }

  try {
    const payload = verifyRefreshToken(refreshToken);
    const userId = payload.sub;

    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      return error(res, 'User not found', 401);
    }

    const newAccessToken = generateAccessToken(userId);
    const newRefreshToken = generateRefreshToken(userId);

    return success(res, {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    }, 'Token refreshed successfully');
  } catch (err) {
    return error(res, 'Invalid or expired refresh token', 401);
  }
}

// ─── Get Auth Config (Public) ───────────────────────────────────────────────

async function getAuthConfig(req, res) {
  return success(res, {
    googleClientId: process.env.GOOGLE_CLIENT_ID || null,
  }, 'Auth configuration retrieved successfully');
}

// ─── Update Profile (Protected) ─────────────────────────────────────────────

async function updateProfile(req, res) {
  const userId = req.user.id;
  const { displayName, avatarUrl, email } = req.body;

  if (displayName !== undefined && !displayName.trim()) {
    return error(res, 'displayName cannot be empty', 400);
  }

  const updateData = {};
  if (displayName !== undefined) {
    updateData.displayName = displayName.trim();
  }
  if (avatarUrl !== undefined) {
    updateData.avatarUrl = avatarUrl;
  }

  if (email !== undefined) {
    const normalizedEmail = email.toLowerCase().trim();
    if (!normalizedEmail) {
      return error(res, 'email cannot be empty', 400);
    }
    
    // Check if email already exists for another user
    const existingUser = await prisma.user.findFirst({
      where: {
        email: normalizedEmail,
        id: { not: userId },
      },
    });
    if (existingUser) {
      return error(res, 'An account with this email already exists', 409);
    }
    updateData.email = normalizedEmail;
  }

  const updatedUser = await prisma.user.update({
    where: { id: userId },
    data: updateData,
  });

  return success(res, sanitizeUser(updatedUser), 'Profile updated successfully');
}

// ─── Change Password (Protected) ───────────────────────────────────────────

async function changePassword(req, res) {
  const userId = req.user.id;
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    return error(res, 'currentPassword and newPassword are required', 400);
  }

  if (newPassword.length < 8) {
    return error(res, 'New password must be at least 8 characters', 400);
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (!user) {
    return error(res, 'User not found', 404);
  }

  if (!user.passwordHash) {
    return error(res, 'This account is linked via Google OAuth and does not have a local password.', 400);
  }

  const isValid = await bcrypt.compare(currentPassword, user.passwordHash);
  if (!isValid) {
    return error(res, 'Incorrect current password', 400);
  }

  // Hash new password
  const newPasswordHash = await bcrypt.hash(newPassword, 12);

  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash: newPasswordHash },
  });

  return success(res, null, 'Password changed successfully');
}

module.exports = {
  register,
  login,
  googleAuth,
  getMe,
  refresh,
  getAuthConfig,
  updateProfile,
  changePassword,
};

