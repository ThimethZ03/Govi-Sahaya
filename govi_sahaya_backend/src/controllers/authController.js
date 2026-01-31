const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { admin } = require('../config/firebase');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// Generate JWT Token
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

// @desc    Register new user
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res) => {
  try {
    const { name, email, phone, password, role, location, farmDetails } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(HTTP_STATUS.CONFLICT).json({
        success: false,
        message: 'User already exists with this email',
      });
    }

    // Create user
    const user = await User.create({
      name,
      email,
      phone,
      password,
      role: role || 'farmer',
      location,
      farmDetails,
    });

    // Generate token
    const token = generateToken(user._id);

    // Remove password from response
    user.password = undefined;

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user,
        token,
      },
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
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Please provide email and password',
      });
    }

    // Check if user exists and get password
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Your account has been deactivated',
      });
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Update last login
    user.lastLogin = Date.now();
    await user.save({ validateBeforeSave: false });

    // Generate token
    const token = generateToken(user._id);

    // Remove password from response
    user.password = undefined;

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Login successful',
      data: {
        user,
        token,
      },
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
// @route   POST /api/auth/firebase-login
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

    // Verify Firebase token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const firebaseUid = decodedToken.uid;

    // Find or create user
    let user = await User.findOne({ firebaseUid });

    if (!user) {
      // Create new user
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
      // Update last login
      user.lastLogin = Date.now();
      await user.save({ validateBeforeSave: false });
    }

    // Generate JWT token
    const token = generateToken(user._id);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Firebase login successful',
      data: {
        user,
        token,
      },
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
// @route   GET /api/auth/me
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
// @route   POST /api/auth/logout
// @access  Private
exports.logout = async (req, res) => {
  try {
    // In a stateless JWT system, logout is typically handled client-side
    // by removing the token. Here we can add any server-side cleanup if needed.

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
// @route   PUT /api/auth/change-password
// @access  Private
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Get user with password
    const user = await User.findById(req.user.id).select('+password');

    // Verify current password
    const isPasswordValid = await user.comparePassword(currentPassword);
    if (!isPasswordValid) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    // Update password
    user.password = newPassword;
    await user.save();

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
// @route   POST /api/auth/forgot-password
// @access  Public
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found with this email',
      });
    }

    // Generate reset token
    const resetToken = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: '1h',
    });

    // Save reset token and expiry
    user.resetPasswordToken = resetToken;
    user.resetPasswordExpire = Date.now() + 3600000; // 1 hour
    await user.save({ validateBeforeSave: false });

    // TODO: Send email with reset link
    // const resetUrl = `${req.protocol}://${req.get('host')}/api/auth/reset-password/${resetToken}`;

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Password reset link sent to email',
      resetToken, // Remove this in production
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
// @route   PUT /api/auth/reset-password/:token
// @access  Public
exports.resetPassword = async (req, res) => {
  try {
    const { token } = req.params;
    const { password } = req.body;

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Find user
    const user = await User.findOne({
      _id: decoded.id,
      resetPasswordToken: token,
      resetPasswordExpire: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Invalid or expired reset token',
      });
    }

    // Update password
    user.password = password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;
    await user.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Password reset successful',
    });
  } catch (error) {
    logger.error('Reset password error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'Invalid or expired token',
    });
  }
};

// @desc    Verify email
// @route   GET /api/auth/verify-email/:token
// @access  Public
exports.verifyEmail = async (req, res) => {
  try {
    const { token } = req.params;

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Update user
    const user = await User.findByIdAndUpdate(
      decoded.id,
      { isVerified: true },
      { new: true }
    );

    if (!user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'User not found',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Email verified successfully',
    });
  } catch (error) {
    logger.error('Verify email error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'Invalid or expired verification token',
    });
  }
};

// @desc    Firebase sync - Login or register from Firebase
// @route   POST /api/v1/auth/firebase-sync
// @access  Public
exports.firebaseSync = async (req, res) => {
  try {
    const { firebaseUid, email, name, phone } = req.body;

    // Validate required fields
    if (!firebaseUid || !email) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Firebase UID and email are required',
      });
    }

    // Find or create user
    let user = await User.findOne({ firebaseUid });

    if (!user) {
      // Check if user exists with this email (from previous registration)
      user = await User.findOne({ email });
      
      if (user) {
        // Update existing user with Firebase UID
        user.firebaseUid = firebaseUid;
        user.name = name || user.name;
        user.phone = phone || user.phone;
        user.isVerified = true;
        user.lastLogin = Date.now();
        await user.save();
        
        logger.info(`Updated existing user with Firebase UID: ${email}`);
      } else {
        // Create new user from Firebase
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
      }
    } else {
      // Update existing Firebase user
      user.name = name || user.name;
      user.phone = phone || user.phone;
      user.lastLogin = Date.now();
      await user.save({ validateBeforeSave: false });
      
      logger.info(`Updated Firebase user login: ${email}`);
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Your account has been deactivated',
      });
    }

    // Generate JWT token
    const token = generateToken(user._id);

    // Remove password from response
    user.password = undefined;

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Firebase sync successful',
      data: {
        user,
        token,
      },
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
