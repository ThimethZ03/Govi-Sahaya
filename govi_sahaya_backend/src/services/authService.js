const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const User = require('../models/User');
const logger = require('../utils/logger');

// Generate JWT token
exports.generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

// Generate refresh token
exports.generateRefreshToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET, {
    expiresIn: '30d',
  });
};

// Verify token
exports.verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    logger.error('Token verification error:', error);
    throw new Error('Invalid or expired token');
  }
};

// Hash password
exports.hashPassword = async (password) => {
  const salt = await bcrypt.genSalt(10);
  return await bcrypt.hash(password, salt);
};

// Compare password
exports.comparePassword = async (enteredPassword, hashedPassword) => {
  return await bcrypt.compare(enteredPassword, hashedPassword);
};

// Generate password reset token
exports.generatePasswordResetToken = () => {
  const resetToken = crypto.randomBytes(32).toString('hex');
  const hashedToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  return { resetToken, hashedToken };
};

// Generate email verification token
exports.generateEmailVerificationToken = (userId) => {
  return jwt.sign({ id: userId, type: 'email_verification' }, process.env.JWT_SECRET, {
    expiresIn: '24h',
  });
};

// Verify email verification token
exports.verifyEmailToken = (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (decoded.type !== 'email_verification') {
      throw new Error('Invalid token type');
    }
    return decoded;
  } catch (error) {
    logger.error('Email verification token error:', error);
    throw new Error('Invalid or expired verification token');
  }
};

// Generate OTP
exports.generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Hash OTP
exports.hashOTP = (otp) => {
  return crypto.createHash('sha256').update(otp).digest('hex');
};

// Validate password strength
exports.validatePasswordStrength = (password) => {
  const minLength = 8;
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumbers = /\d/.test(password);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

  const errors = [];

  if (password.length < minLength) {
    errors.push(`Password must be at least ${minLength} characters long`);
  }
  if (!hasUpperCase) {
    errors.push('Password must contain at least one uppercase letter');
  }
  if (!hasLowerCase) {
    errors.push('Password must contain at least one lowercase letter');
  }
  if (!hasNumbers) {
    errors.push('Password must contain at least one number');
  }

  return {
    isValid: errors.length === 0,
    errors,
    strength: calculatePasswordStrength(password),
  };
};

// Calculate password strength (0-100)
const calculatePasswordStrength = (password) => {
  let strength = 0;

  if (password.length >= 8) strength += 20;
  if (password.length >= 12) strength += 10;
  if (/[a-z]/.test(password)) strength += 20;
  if (/[A-Z]/.test(password)) strength += 20;
  if (/\d/.test(password)) strength += 20;
  if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) strength += 10;

  return Math.min(strength, 100);
};

// Create user session
exports.createSession = async (userId, deviceInfo) => {
  const token = this.generateToken(userId);
  const refreshToken = this.generateRefreshToken(userId);

  // TODO: Store session in database or Redis if needed
  logger.info('Session created for user:', userId);

  return {
    token,
    refreshToken,
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  };
};

// Revoke user session
exports.revokeSession = async (userId, token) => {
  // TODO: Implement token blacklisting in Redis
  logger.info('Session revoked for user:', userId);
  return true;
};

// Refresh access token
exports.refreshAccessToken = async (refreshToken) => {
  try {
    const decoded = jwt.verify(
      refreshToken,
      process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET
    );

    const user = await User.findById(decoded.id);
    if (!user || !user.isActive) {
      throw new Error('User not found or inactive');
    }

    const newToken = this.generateToken(user._id);

    return {
      token: newToken,
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    };
  } catch (error) {
    logger.error('Refresh token error:', error);
    throw new Error('Invalid or expired refresh token');
  }
};

// Validate user credentials
exports.validateCredentials = async (email, password) => {
  const user = await User.findOne({ email }).select('+password');

  if (!user) {
    throw new Error('Invalid credentials');
  }

  if (!user.isActive) {
    throw new Error('Account is deactivated');
  }

  const isPasswordValid = await this.comparePassword(password, user.password);

  if (!isPasswordValid) {
    throw new Error('Invalid credentials');
  }

  return user;
};

// Check if email exists
exports.emailExists = async (email) => {
  const user = await User.findOne({ email });
  return !!user;
};

// Check if phone exists
exports.phoneExists = async (phone) => {
  const user = await User.findOne({ phone });
  return !!user;
};

// Generate unique username from email
exports.generateUsername = (email) => {
  const baseUsername = email.split('@')[0].toLowerCase().replace(/[^a-z0-9]/g, '');
  const randomSuffix = Math.floor(Math.random() * 10000);
  return `${baseUsername}${randomSuffix}`;
};
