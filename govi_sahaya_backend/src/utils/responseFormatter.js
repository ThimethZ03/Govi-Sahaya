const { HTTP_STATUS } = require('../config/constants');

// Success response
exports.success = (res, data, message = 'Success', statusCode = HTTP_STATUS.OK) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
    timestamp: new Date().toISOString(),
  });
};

// Success response with pagination
exports.successWithPagination = (res, data, pagination, message = 'Success') => {
  return res.status(HTTP_STATUS.OK).json({
    success: true,
    message,
    data,
    pagination: {
      currentPage: pagination.page,
      totalPages: pagination.pages,
      totalItems: pagination.total,
      itemsPerPage: pagination.limit,
      hasNextPage: pagination.page < pagination.pages,
      hasPrevPage: pagination.page > 1,
    },
    timestamp: new Date().toISOString(),
  });
};

// Created response
exports.created = (res, data, message = 'Resource created successfully') => {
  return res.status(HTTP_STATUS.CREATED).json({
    success: true,
    message,
    data,
    timestamp: new Date().toISOString(),
  });
};

// No content response
exports.noContent = (res) => {
  return res.status(HTTP_STATUS.NO_CONTENT).send();
};

// Error response
exports.error = (res, message = 'An error occurred', statusCode = HTTP_STATUS.INTERNAL_SERVER_ERROR, errors = null) => {
  const response = {
    success: false,
    message,
    timestamp: new Date().toISOString(),
  };

  if (errors) {
    response.errors = errors;
  }

  if (process.env.NODE_ENV === 'development' && errors) {
    response.stack = errors.stack;
  }

  return res.status(statusCode).json(response);
};

// Bad request response
exports.badRequest = (res, message = 'Bad request', errors = null) => {
  return exports.error(res, message, HTTP_STATUS.BAD_REQUEST, errors);
};

// Unauthorized response
exports.unauthorized = (res, message = 'Unauthorized access') => {
  return exports.error(res, message, HTTP_STATUS.UNAUTHORIZED);
};

// Forbidden response
exports.forbidden = (res, message = 'Access forbidden') => {
  return exports.error(res, message, HTTP_STATUS.FORBIDDEN);
};

// Not found response
exports.notFound = (res, message = 'Resource not found') => {
  return exports.error(res, message, HTTP_STATUS.NOT_FOUND);
};

// Conflict response
exports.conflict = (res, message = 'Resource already exists') => {
  return exports.error(res, message, HTTP_STATUS.CONFLICT);
};

// Validation error response
exports.validationError = (res, errors, message = 'Validation failed') => {
  return res.status(HTTP_STATUS.UNPROCESSABLE_ENTITY).json({
    success: false,
    message,
    errors: Array.isArray(errors) ? errors : [errors],
    timestamp: new Date().toISOString(),
  });
};

// Too many requests response
exports.tooManyRequests = (res, message = 'Too many requests') => {
  return exports.error(res, message, HTTP_STATUS.TOO_MANY_REQUESTS);
};

// Service unavailable response
exports.serviceUnavailable = (res, message = 'Service temporarily unavailable') => {
  return exports.error(res, message, HTTP_STATUS.SERVICE_UNAVAILABLE);
};

// Custom response
exports.custom = (res, statusCode, data) => {
  return res.status(statusCode).json(data);
};
