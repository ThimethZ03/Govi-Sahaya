const rateLimit = require('express-rate-limit');
const { HTTP_STATUS, RATE_LIMIT } = require('../config/constants');

// General API rate limiter
exports.apiLimiter = rateLimit({
  windowMs: RATE_LIMIT.WINDOW_MS,
  max: RATE_LIMIT.MAX_REQUESTS,
  message: {
    success: false,
    message: RATE_LIMIT.MESSAGE,
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
      success: false,
      message: RATE_LIMIT.MESSAGE,
    });
  },
});

// Strict rate limiter for authentication routes
exports.authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 requests per window
  message: {
    success: false,
    message: 'Too many authentication attempts. Please try again after 15 minutes.',
  },
  skipSuccessfulRequests: true,
  handler: (req, res) => {
    res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
      success: false,
      message: 'Too many authentication attempts. Please try again after 15 minutes.',
    });
  },
});

// Rate limiter for file uploads
exports.uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 20, // 20 uploads per hour
  message: {
    success: false,
    message: 'Too many file uploads. Please try again after an hour.',
  },
  handler: (req, res) => {
    res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
      success: false,
      message: 'Too many file uploads. Please try again after an hour.',
    });
  },
});

// Rate limiter for disease detection
exports.mlLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // 10 detections per hour
  message: {
    success: false,
    message: 'Too many disease detection requests. Please try again after an hour.',
  },
  handler: (req, res) => {
    res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
      success: false,
      message: 'Too many disease detection requests. Please try again after an hour.',
    });
  },
});

// Rate limiter for creating posts/comments
exports.postLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 30, // 30 posts/comments per hour
  message: {
    success: false,
    message: 'Too many posts created. Please try again after an hour.',
  },
  handler: (req, res) => {
    res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
      success: false,
      message: 'Too many posts created. Please try again after an hour.',
    });
  },
});

// Rate limiter for messages
exports.messageLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 100, // 100 messages per hour
  message: {
    success: false,
    message: 'Too many messages sent. Please try again after an hour.',
  },
  handler: (req, res) => {
    res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
      success: false,
      message: 'Too many messages sent. Please try again after an hour.',
    });
  },
});

// Rate limiter for API calls (external services)
exports.externalApiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 50, // 50 requests per hour
  message: {
    success: false,
    message: 'Too many API requests. Please try again after an hour.',
  },
  handler: (req, res) => {
    res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
      success: false,
      message: 'Too many API requests. Please try again after an hour.',
    });
  },
});

// Custom rate limiter factory
exports.createLimiter = (windowMs, max, message) => {
  return rateLimit({
    windowMs,
    max,
    message: {
      success: false,
      message: message || RATE_LIMIT.MESSAGE,
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
        success: false,
        message: message || RATE_LIMIT.MESSAGE,
      });
    },
  });
};

// Skip rate limiting for certain conditions
exports.skipLimiter = (req, res, next) => {
  // Skip rate limiting for admin users
  if (req.user && req.user.role === 'admin') {
    return next();
  }

  // Skip rate limiting in development
  if (process.env.NODE_ENV === 'development') {
    return next();
  }

  next();
};
