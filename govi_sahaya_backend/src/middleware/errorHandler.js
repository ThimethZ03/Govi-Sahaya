const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// Error handler middleware
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error
  logger.error('Error:', {
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    const message = 'Resource not found';
    error = {
      statusCode: HTTP_STATUS.NOT_FOUND,
      message,
    };
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    const message = `Duplicate field value: ${field}. Please use another value`;
    error = {
      statusCode: HTTP_STATUS.CONFLICT,
      message,
    };
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors)
      .map((val) => val.message)
      .join(', ');
    error = {
      statusCode: HTTP_STATUS.BAD_REQUEST,
      message,
    };
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    const message = 'Invalid token. Please login again';
    error = {
      statusCode: HTTP_STATUS.UNAUTHORIZED,
      message,
    };
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'Token expired. Please login again';
    error = {
      statusCode: HTTP_STATUS.UNAUTHORIZED,
      message,
    };
  }

  // Multer file upload errors
  if (err.name === 'MulterError') {
    let message = 'File upload error';
    if (err.code === 'LIMIT_FILE_SIZE') {
      message = 'File size is too large';
    } else if (err.code === 'LIMIT_FILE_COUNT') {
      message = 'Too many files';
    } else if (err.code === 'LIMIT_UNEXPECTED_FILE') {
      message = 'Unexpected file field';
    }
    error = {
      statusCode: HTTP_STATUS.BAD_REQUEST,
      message,
    };
  }

  // Firebase errors
  if (err.code && err.code.startsWith('auth/')) {
    const message = 'Firebase authentication error';
    error = {
      statusCode: HTTP_STATUS.UNAUTHORIZED,
      message,
    };
  }

  res.status(error.statusCode || HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
    success: false,
    message: error.message || 'Server Error',
    ...(process.env.NODE_ENV === 'development' && {
      error: err,
      stack: err.stack,
    }),
  });
};

// Not found handler
const notFound = (req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  res.status(HTTP_STATUS.NOT_FOUND);
  next(error);
};

// Async handler wrapper
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = {
  errorHandler,
  notFound,
  asyncHandler,
};
