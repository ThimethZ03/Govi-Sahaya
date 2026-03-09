const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { admin } = require('../config/firebase');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// Protect routes - Verify JWT token
exports.protect = async (req, res, next) => {
  try {
    let token;

    // Check for token in Authorization header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    // Check if token exists
    if (!token) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Not authorized to access this route. Please login.',
      });
    }

    try {
      // Verify JWT token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Get user from token
      const user = await User.findById(decoded.id).select('-password');

      if (!user) {
        return res.status(HTTP_STATUS.UNAUTHORIZED).json({
          success: false,
          message: 'User not found',
        });
      }

      // Check if user is active
      if (!user.isActive) {
        return res.status(HTTP_STATUS.FORBIDDEN).json({
          success: false,
          message: 'Your account has been deactivated',
        });
      }

      // Attach user to request object
      req.user = user;
      next();
    } catch (error) {
      logger.error('Token verification error:', error);
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Invalid or expired token',
      });
    }
  } catch (error) {
    logger.error('Auth middleware error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Authentication failed',
    });
  }
};

// Verify Firebase token
exports.protectFirebase = async (req, res, next) => {
  try {
    let token;

    // Check for token in Authorization header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Not authorized to access this route',
      });
    }

    try {
      // Verify Firebase token
      const decodedToken = await admin.auth().verifyIdToken(token);

      // Get user from Firebase UID
      const user = await User.findOne({ firebaseUid: decodedToken.uid });

      if (!user) {
        return res.status(HTTP_STATUS.UNAUTHORIZED).json({
          success: false,
          message: 'User not found',
        });
      }

      if (!user.isActive) {
        return res.status(HTTP_STATUS.FORBIDDEN).json({
          success: false,
          message: 'Your account has been deactivated',
        });
      }

      req.user = user;
      next();
    } catch (error) {
      logger.error('Firebase token verification error:', error);
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Invalid or expired Firebase token',
      });
    }
  } catch (error) {
    logger.error('Firebase auth middleware error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Authentication failed',
    });
  }
};

// Authorize specific roles
exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        message: 'Not authorized to access this route',
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: `User role '${req.user.role}' is not authorized to access this route`,
      });
    }

    next();
  };
};

// Optional auth - Attach user if token exists, but don't require it
exports.optionalAuth = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (token) {
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.id).select('-password');

        if (user && user.isActive) {
          req.user = user;
        }
      } catch (error) {
        // Token is invalid, but we don't throw error for optional auth
        logger.debug('Optional auth - Invalid token');
      }
    }

    next();
  } catch (error) {
    logger.error('Optional auth error:', error);
    next();
  }
};

// Check if user owns the resource
exports.checkOwnership = (model) => {
  return async (req, res, next) => {
    try {
      const resource = await model.findById(req.params.id);

      if (!resource) {
        return res.status(HTTP_STATUS.NOT_FOUND).json({
          success: false,
          message: 'Resource not found',
        });
      }

      // Check if user owns the resource or is admin
      if (
        resource.user.toString() !== req.user.id &&
        req.user.role !== 'admin'
      ) {
        return res.status(HTTP_STATUS.FORBIDDEN).json({
          success: false,
          message: 'Not authorized to access this resource',
        });
      }

      req.resource = resource;
      next();
    } catch (error) {
      logger.error('Ownership check error:', error);
      return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
        success: false,
        message: 'Authorization check failed',
      });
    }
  };
};

// Verify user is verified
exports.requireVerified = (req, res, next) => {
  if (!req.user.isVerified) {
    return res.status(HTTP_STATUS.FORBIDDEN).json({
      success: false,
      message: 'Please verify your email to access this resource',
    });
  }
  next();
};
