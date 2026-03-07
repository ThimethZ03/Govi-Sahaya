const { body, param, query, validationResult } = require('express-validator');
const { HTTP_STATUS, REGEX } = require('../config/constants');

// Validation result handler
const validate = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map((err) => ({
        field: err.param,
        message: err.msg,
      })),
    });
  }
  
  next();
};

// Auth validators
exports.registerValidator = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please provide a valid email')
    .normalizeEmail(),
  
  body('phone')
    .trim()
    .notEmpty()
    .withMessage('Phone number is required')
    .matches(REGEX.PHONE_LK)
    .withMessage('Please provide a valid Sri Lankan phone number'),
  
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters')
    .matches(REGEX.PASSWORD)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),
  
  body('role')
    .optional()
    .isIn(['farmer', 'expert', 'vendor'])
    .withMessage('Invalid role'),
  
  validate,
];

exports.loginValidator = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please provide a valid email'),
  
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
  
  validate,
];

exports.changePasswordValidator = [
  body('currentPassword')
    .notEmpty()
    .withMessage('Current password is required'),
  
  body('newPassword')
    .notEmpty()
    .withMessage('New password is required')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters')
    .matches(REGEX.PASSWORD)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),
  
  validate,
];

// User validators
exports.updateProfileValidator = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  
  body('phone')
    .optional()
    .trim()
    .matches(REGEX.PHONE_LK)
    .withMessage('Please provide a valid Sri Lankan phone number'),
  
  body('location.district')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('District cannot be empty'),
  
  body('location.city')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('City cannot be empty'),
  
  validate,
];

// Post validators
exports.createPostValidator = [
  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 200 })
    .withMessage('Title cannot exceed 200 characters'),
  
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Content is required')
    .isLength({ max: 5000 })
    .withMessage('Content cannot exceed 5000 characters'),
  
  body('category')
    .notEmpty()
    .withMessage('Category is required')
    .isIn(['general', 'crop_advice', 'pest_problem', 'market_price', 'equipment', 'success_story', 'question'])
    .withMessage('Invalid category'),
  
  body('tags')
    .optional()
    .custom((value) => {
      if (typeof value === 'string') {
        const tags = value.split(',');
        return tags.length <= 5;
      }
      return Array.isArray(value) && value.length <= 5;
    })
    .withMessage('Maximum 5 tags allowed'),
  
  validate,
];

// Comment validators
exports.createCommentValidator = [
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Comment content is required')
    .isLength({ max: 1000 })
    .withMessage('Comment cannot exceed 1000 characters'),
  
  body('parentComment')
    .optional()
    .isMongoId()
    .withMessage('Invalid parent comment ID'),
  
  validate,
];

// Guide validators
exports.createGuideValidator = [
  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 200 })
    .withMessage('Title cannot exceed 200 characters'),
  
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ max: 500 })
    .withMessage('Description cannot exceed 500 characters'),
  
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Content is required'),
  
  body('category')
    .notEmpty()
    .withMessage('Category is required')
    .isIn([
      'crop_management',
      'pest_control',
      'fertilizers',
      'irrigation',
      'harvesting',
      'storage',
      'marketing',
      'organic_farming',
      'modern_techniques',
    ])
    .withMessage('Invalid category'),
  
  body('difficulty')
    .optional()
    .isIn(['beginner', 'intermediate', 'advanced'])
    .withMessage('Invalid difficulty level'),
  
  validate,
];

// Expense validators
exports.createExpenseValidator = [
  body('category')
    .notEmpty()
    .withMessage('Category is required')
    .isIn(['seeds', 'fertilizers', 'pesticides', 'labor', 'equipment', 'irrigation', 'transportation', 'other'])
    .withMessage('Invalid category'),
  
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ max: 500 })
    .withMessage('Description cannot exceed 500 characters'),
  
  body('amount')
    .notEmpty()
    .withMessage('Amount is required')
    .isFloat({ min: 0 })
    .withMessage('Amount must be a positive number'),
  
  body('date')
    .optional()
    .isISO8601()
    .withMessage('Invalid date format'),
  
  body('paymentMethod')
    .optional()
    .isIn(['cash', 'card', 'bank_transfer', 'mobile_payment', 'credit'])
    .withMessage('Invalid payment method'),
  
  validate,
];

// Field validators
exports.createFieldValidator = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Field name is required')
    .isLength({ max: 100 })
    .withMessage('Field name cannot exceed 100 characters'),
  
  body('area.value')
    .notEmpty()
    .withMessage('Field area is required')
    .isFloat({ min: 0 })
    .withMessage('Area must be a positive number'),
  
  body('area.unit')
    .notEmpty()
    .withMessage('Area unit is required')
    .isIn(['acres', 'hectares', 'perches', 'square_meters'])
    .withMessage('Invalid area unit'),
  
  body('soilType')
    .optional()
    .isIn(['clay', 'sandy', 'loamy', 'silt', 'peaty', 'chalky', 'mixed'])
    .withMessage('Invalid soil type'),
  
  validate,
];

// Shop item validators
exports.createShopItemValidator = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Product name is required')
    .isLength({ max: 200 })
    .withMessage('Product name cannot exceed 200 characters'),
  
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ max: 2000 })
    .withMessage('Description cannot exceed 2000 characters'),
  
  body('category')
    .notEmpty()
    .withMessage('Category is required')
    .isIn(['seeds', 'fertilizers', 'pesticides', 'tools', 'equipment', 'irrigation', 'organic_products'])
    .withMessage('Invalid category'),
  
  body('price.original')
    .notEmpty()
    .withMessage('Price is required')
    .isFloat({ min: 0 })
    .withMessage('Price must be a positive number'),
  
  body('stock.quantity')
    .notEmpty()
    .withMessage('Stock quantity is required')
    .isInt({ min: 0 })
    .withMessage('Stock must be a non-negative integer'),
  
  body('stock.unit')
    .notEmpty()
    .withMessage('Stock unit is required')
    .isIn(['kg', 'g', 'l', 'ml', 'pieces', 'packets', 'bags'])
    .withMessage('Invalid stock unit'),
  
  validate,
];

// Order validators
exports.createOrderValidator = [
  body('items')
    .isArray({ min: 1 })
    .withMessage('Order must contain at least one item'),
  
  body('items.*.product')
    .notEmpty()
    .withMessage('Product ID is required')
    .isMongoId()
    .withMessage('Invalid product ID'),
  
  body('items.*.quantity')
    .notEmpty()
    .withMessage('Quantity is required')
    .isInt({ min: 1 })
    .withMessage('Quantity must be at least 1'),
  
  body('shippingAddress.addressLine1')
    .trim()
    .notEmpty()
    .withMessage('Address line 1 is required'),
  
  body('shippingAddress.city')
    .trim()
    .notEmpty()
    .withMessage('City is required'),
  
  body('paymentMethod')
    .notEmpty()
    .withMessage('Payment method is required')
    .isIn(['cash_on_delivery', 'card', 'bank_transfer', 'mobile_payment'])
    .withMessage('Invalid payment method'),
  
  validate,
];

// Message validators
exports.sendMessageValidator = [
  body('receiverId')
    .notEmpty()
    .withMessage('Receiver ID is required')
    .isMongoId()
    .withMessage('Invalid receiver ID'),
  
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Message content is required')
    .isLength({ max: 2000 })
    .withMessage('Message cannot exceed 2000 characters'),
  
  body('messageType')
    .optional()
    .isIn(['text', 'image', 'file'])
    .withMessage('Invalid message type'),
  
  validate,
];

// Notification validators
exports.createNotificationValidator = [
  body('user')
    .notEmpty()
    .withMessage('User ID is required')
    .isMongoId()
    .withMessage('Invalid user ID'),
  
  body('type')
    .notEmpty()
    .withMessage('Notification type is required')
    .isIn(['weather_alert', 'disease_detection', 'order_update', 'forum_reply', 'price_alert', 'general'])
    .withMessage('Invalid notification type'),
  
  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 200 })
    .withMessage('Title cannot exceed 200 characters'),
  
  body('message')
    .trim()
    .notEmpty()
    .withMessage('Message is required')
    .isLength({ max: 500 })
    .withMessage('Message cannot exceed 500 characters'),
  
  validate,
];

// Review validators
exports.addReviewValidator = [
  body('rating')
    .notEmpty()
    .withMessage('Rating is required')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5'),
  
  body('comment')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Comment cannot exceed 500 characters'),
  
  validate,
];

// ID parameter validator
exports.mongoIdValidator = [
  param('id')
    .isMongoId()
    .withMessage('Invalid ID format'),
  
  validate,
];

// Pagination validator
exports.paginationValidator = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  
  validate,
];
