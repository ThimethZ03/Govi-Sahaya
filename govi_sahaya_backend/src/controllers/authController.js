// controllers/authController.js
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const { admin } = require('../config/firebase');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');
const emailService = require('../services/emailService');
const authService = require('../services/authService');

// Generate JWT Token used for login sessions
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

// ── HTML pages for browser responses ─────────────────────────────
const successPage = (userName) => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Email Verified - Govi Sahaya</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: Arial, Helvetica, sans-serif;
      background: linear-gradient(135deg, #e8f5e9 0%, #f0f4f0 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: #ffffff;
      border-radius: 20px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.12);
      padding: 60px 50px;
      max-width: 500px;
      width: 100%;
      text-align: center;
    }
    .icon-wrap {
      width: 90px;
      height: 90px;
      background: linear-gradient(135deg, #2D6B42, #4CAF50);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 28px auto;
      animation: pop 0.5s ease;
    }
    @keyframes pop {
      0%   { transform: scale(0); opacity: 0; }
      70%  { transform: scale(1.15); }
      100% { transform: scale(1); opacity: 1; }
    }
    .checkmark { font-size: 44px; color: white; line-height: 1; }
    .badge {
      display: inline-block;
      background: #e8f5e9;
      color: #2D6B42;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 1.5px;
      text-transform: uppercase;
      padding: 6px 16px;
      border-radius: 20px;
      margin-bottom: 16px;
    }
    h1 { color: #1E4D2E; font-size: 28px; font-weight: 700; margin-bottom: 12px; }
    .subtitle {
      color: #666666;
      font-size: 15px;
      line-height: 1.7;
      margin-bottom: 32px;
    }
    .subtitle strong { color: #2D6B42; }
    .divider { border: none; border-top: 1px solid #f0f0f0; margin: 28px 0; }
    .steps {
      text-align: left;
      background: #f8faf8;
      border-radius: 12px;
      padding: 20px 24px;
      margin-bottom: 28px;
    }
    .steps p {
      font-size: 13px;
      font-weight: 700;
      color: #1E4D2E;
      margin-bottom: 12px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .step {
      display: flex;
      align-items: center;
      margin-bottom: 10px;
      font-size: 14px;
      color: #444444;
    }
    .step:last-child { margin-bottom: 0; }
    .step-num {
      width: 24px;
      height: 24px;
      background: #2D6B42;
      color: white;
      border-radius: 50%;
      font-size: 12px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 12px;
      flex-shrink: 0;
    }
    .footer { margin-top: 28px; font-size: 12px; color: #aaaaaa; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon-wrap">
      <span class="checkmark">✓</span>
    </div>
    <div class="badge">✅ Verified Successfully</div>
    <h1>Email Confirmed!</h1>
    <p class="subtitle">
      Hey <strong>${userName}</strong>, your email address has been verified.
      Your Govi Sahaya account is now fully active and ready to use.
    </p>
    <hr class="divider"/>
    <div class="steps">
      <p>What's next?</p>
      <div class="step">
        <div class="step-num">1</div>
        Open the Govi Sahaya app on your phone
      </div>
      <div class="step">
        <div class="step-num">2</div>
        Log in with your email and password
      </div>
      <div class="step">
        <div class="step-num">3</div>
        Start your smart farming journey 🌾
      </div>
    </div>
    <div class="footer">
      &copy; 2026 Govi Sahaya &nbsp;·&nbsp; Smart Agriculture Advisor Platform<br/>
      You can safely close this browser tab.
    </div>
  </div>
</body>
</html>`;

const errorPage = (message) => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Verification Failed - Govi Sahaya</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: Arial, Helvetica, sans-serif;
      background: linear-gradient(135deg, #fce4e4 0%, #fff5f5 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: #ffffff;
      border-radius: 20px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.12);
      padding: 60px 50px;
      max-width: 500px;
      width: 100%;
      text-align: center;
    }
    .icon-wrap {
      width: 90px;
      height: 90px;
      background: linear-gradient(135deg, #C62828, #ef5350);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 28px auto;
    }
    .x-mark { font-size: 44px; color: white; }
    .badge {
      display: inline-block;
      background: #fce4e4;
      color: #C62828;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 1.5px;
      text-transform: uppercase;
      padding: 6px 16px;
      border-radius: 20px;
      margin-bottom: 16px;
    }
    h1 { color: #B71C1C; font-size: 28px; font-weight: 700; margin-bottom: 12px; }
    .subtitle { color: #666666; font-size: 15px; line-height: 1.7; margin-bottom: 28px; }
    .error-box {
      background: #fff8e1;
      border-left: 4px solid #FFC107;
      border-radius: 6px;
      padding: 14px 18px;
      font-size: 14px;
      color: #555555;
      text-align: left;
      margin-bottom: 28px;
      line-height: 1.7;
    }
    .footer { margin-top: 28px; font-size: 12px; color: #aaaaaa; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon-wrap">
      <span class="x-mark">✕</span>
    </div>
    <div class="badge">❌ Verification Failed</div>
    <h1>Link Expired or Invalid</h1>
    <p class="subtitle">
      This verification link is no longer valid. It may have expired or already been used.
    </p>
    <div class="error-box">
      ⚠️ ${message}<br/><br/>
      Please open the Govi Sahaya app and request a new verification email.
    </div>
    <div class="footer">
      &copy; 2026 Govi Sahaya &nbsp;·&nbsp; Smart Agriculture Advisor Platform
    </div>
  </div>
</body>
</html>`;

// @desc    Register new user
// @route   POST /api/v1/auth/register
// @access  Public
exports.register = async (req, res) => {
  try {
    const { name, email, phone, password, role, location, farmDetails, firebaseUid } =
      req.body; // ✅ FIX: extract firebaseUid from body

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(HTTP_STATUS.CONFLICT).json({
        success: false,
        message: 'User already exists with this email',
      });
    }

    const user = await User.create({
      name,
      email,
      phone,
      password,
      role: role || 'farmer',
      location,
      farmDetails,
      firebaseUid: firebaseUid || undefined, // ✅ FIX: save firebaseUid so reset can update Firebase
    });

    const verificationToken =
      authService.generateEmailVerificationToken(user._id);

    emailService
      .sendVerificationEmail(user, verificationToken)
      .catch((err) => logger.error('Verification email failed:', err));

    const token = generateToken(user._id);
    user.password = undefined;

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'User registered successfully. Verification email sent.',
      data: { user, token },
    });
  } catch (error) {
    logger.error('Register error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Login user
// @route   POST /api/v1/auth/login
// @access  Public
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Please provide email and password',
      });
    }

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    if (!user.isActive) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Your account has been deactivated',
      });
    }

    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    user.lastLogin = Date.now();
    await user.save({ validateBeforeSave: false });

    const token = generateToken(user._id);
    user.password = undefined;

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Login successful',
      data: { user, token },
    });
  } catch (error) {
    logger.error('Login error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Login failed',
    });
  }
};

// @desc    Login with Firebase
// @route   POST /api/v1/auth/firebase-login
// @access  Public
exports.firebaseLogin = async (req, res) => {
  try {
    const { idToken, userData } = req.body;

    if (!idToken) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Firebase ID token is required',
      });
    }

    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const firebaseUid = decodedToken.uid;

    let user = await User.findOne({ firebaseUid });

    if (!user) {
      user = await User.create({
        firebaseUid,
        email: decodedToken.email || userData.email,
        name: userData.name || decodedToken.name || 'User',
        phone: userData.phone || decodedToken.phone_number || '',
        profilePicture: decodedToken.picture,
        isVerified: decodedToken.email_verified || false,
        role: 'farmer',
      });
    } else {
      user.lastLogin = Date.now();
      await user.save({ validateBeforeSave: false });
    }

    const token = generateToken(user._id);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Firebase login successful',
      data: { user, token },
    });
  } catch (error) {
    logger.error('Firebase login error:', error);
    res.status(HTTP_STATUS.UNAUTHORIZED).json({
      success: false,
      message: 'Firebase authentication failed',
    });
  }
};

// @desc    Get current logged in user
// @route   GET /api/v1/auth/me
// @access  Private
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: user,
    });
  } catch (error) {
    logger.error('Get me error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch user data',
    });
  }
};

// @desc    Logout user
// @route   POST /api/v1/auth/logout
// @access  Private
exports.logout = async (req, res) => {
  try {
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (error) {
    logger.error('Logout error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Logout failed',
    });
  }
};

// @desc    Change password
// @route   PUT /api/v1/auth/change-password
// @access  Private
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(req.user.id).select('+password');

    const isPasswordValid = await user.comparePassword(currentPassword);
    if (!isPasswordValid) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    user.password = newPassword;
    await user.save();

    // Also update Firebase password so app login works
    if (user.firebaseUid) {
      try {
        await admin.auth().updateUser(user.firebaseUid, { password: newPassword });
        logger.info(`Firebase password updated (change-password) for: ${user.email}`);
      } catch (firebaseErr) {
        logger.error('Firebase change-password update failed:', firebaseErr.message);
      }
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error) {
    logger.error('Change password error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to change password',
    });
  }
};

// @desc    Forgot password
// @route   POST /api/v1/auth/forgot-password
// @access  Public
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found with this email',
      });
    }

    const resetToken = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    user.resetPasswordToken = resetToken;
    user.resetPasswordExpire = Date.now() + 3600000;
    await user.save({ validateBeforeSave: false });

    logger.info(`Reset token saved for: ${user.email}`);

    emailService
      .sendPasswordResetEmail(user, resetToken)
      .catch((err) => logger.error('Password reset email failed:', err));

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Password reset link sent to email',
    });
  } catch (error) {
    logger.error('Forgot password error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to process request',
    });
  }
};

// @desc    Reset password
// @route   PUT /api/v1/auth/reset-password/:token
// @access  Public
exports.resetPassword = async (req, res) => {
  try {
    const { token } = req.params;
    const { password } = req.body;

    if (!password || password.length < 8) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Password must be at least 8 characters',
      });
    }

    // Verify JWT first — clear error if expired
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Reset link has expired. Please request a new one.',
      });
    }

    // Check token is still in DB and not expired
    const user = await User.findOne({
      _id: decoded.id,
      resetPasswordToken: token,
      resetPasswordExpire: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Reset link is invalid or has already been used.',
      });
    }

    // Update password in MongoDB
    user.password = password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;
    await user.save();

    logger.info(`Password reset successful for: ${user.email}`);

    // ✅ FIX: Look up Firebase by EMAIL — works even if firebaseUid is null in MongoDB
    try {
      const firebaseUser = await admin.auth().getUserByEmail(user.email);
      await admin.auth().updateUser(firebaseUser.uid, { password });

      // Backfill firebaseUid if it was missing
      if (!user.firebaseUid && firebaseUser.uid) {
        user.firebaseUid = firebaseUser.uid;
        await user.save({ validateBeforeSave: false });
      }

      logger.info(`Firebase password updated (reset) for: ${user.email}`);
    } catch (firebaseErr) {
      // User may not exist in Firebase — not a fatal error
      logger.warn(`Firebase update skipped for ${user.email}: ${firebaseErr.message}`);
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Password reset successful. You can now log in with your new password.',
    });
  } catch (error) {
    logger.error('Reset password error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'Failed to reset password. Please try again.',
    });
  }
};

// @desc    Verify email — returns beautiful HTML page (not JSON)
// @route   GET /api/v1/auth/verify-email/:token
// @access  Public
exports.verifyEmail = async (req, res) => {
  try {
    const { token } = req.params;

    const decoded = authService.verifyEmailToken(token);

    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(404).send(errorPage('User not found.'));
    }

    if (user.isVerified) {
      return res.status(200).send(successPage(user.name));
    }

    user.isVerified = true;
    user.verificationToken = undefined;
    await user.save({ validateBeforeSave: false });

    emailService
      .sendWelcomeEmail(user)
      .catch((err) => logger.error('Welcome email failed:', err));

    logger.info(`Email verified for user: ${user.email}`);

    return res.status(200).send(successPage(user.name));
  } catch (error) {
    logger.error('Verify email error:', error);
    return res.status(400).send(errorPage('Invalid or expired verification token.'));
  }
};

// @desc    Firebase sync - Login or register from Firebase
// @route   POST /api/v1/auth/firebase-sync
// @access  Public
exports.firebaseSync = async (req, res) => {
  try {
    const { firebaseUid, email, name, phone } = req.body;

    if (!firebaseUid || !email) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Firebase UID and email are required',
      });
    }

    let user = await User.findOne({ firebaseUid });

    if (!user) {
      user = await User.findOne({ email });

      if (user) {
        user.firebaseUid = firebaseUid;
        user.name = name || user.name;
        user.phone = phone || user.phone;
        user.isVerified = true;
        user.lastLogin = Date.now();
        await user.save();

        logger.info(`Updated existing user with Firebase UID: ${email}`);
      } else {
        user = await User.create({
          firebaseUid,
          email,
          name: name || 'User',
          phone: phone || '',
          role: 'farmer',
          isVerified: true,
          isActive: true,
        });

        logger.info(`Created new user from Firebase: ${email}`);

        // Send welcome email only on first-time Google sign-up
        emailService
          .sendWelcomeEmail(user)
          .catch((err) =>
            logger.error('Welcome email (Google signup) failed:', err)
          );
      }
    } else {
      user.name = name || user.name;
      user.phone = phone || user.phone;
      user.lastLogin = Date.now();
      await user.save({ validateBeforeSave: false });

      logger.info(`Updated Firebase user login: ${email}`);
    }

    if (!user.isActive) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Your account has been deactivated',
      });
    }

    const token = generateToken(user._id);
    const refreshToken = jwt.sign(
      { id: user._id },
      process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    user.password = undefined;

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Firebase sync successful',
      data: { user, token, refreshToken },
    });
  } catch (error) {
    logger.error('Firebase sync error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Firebase sync failed',
      error: error.message,
    });
  }
};
