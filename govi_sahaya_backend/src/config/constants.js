// Application Constants for Govi Sahaya Backend

module.exports = {
  // Application Info
  APP_NAME: 'Govi Sahaya',
  APP_VERSION: '1.0.0',
  APP_DESCRIPTION: 'Smart Agriculture Advisor Platform',

  // API Configuration
  API: {
    VERSION: 'v1',
    BASE_PATH: '/api/v1',
    TIMEOUT: 30000,
    MAX_REQUEST_SIZE: '10mb',
  },

  // Server Configuration
  SERVER: {
    PORT: process.env.PORT || 5000,
    HOST: process.env.HOST || '0.0.0.0',
  },

  // Database Configuration
  DATABASE: {
    NAME: 'govi_sahaya',
    MAX_POOL_SIZE: 10,
    MIN_POOL_SIZE: 2,
  },

  // Authentication
  AUTH: {
    JWT_EXPIRY: '7d',
    REFRESH_TOKEN_EXPIRY: '30d',
    PASSWORD_MIN_LENGTH: 8,
    PASSWORD_MAX_LENGTH: 128,
    SALT_ROUNDS: 10,
  },

  // User Roles
  ROLES: {
    ADMIN: 'admin',
    FARMER: 'farmer',
    EXPERT: 'expert',
    VENDOR: 'vendor',
  },

  // File Upload Configuration
  UPLOAD: {
    MAX_FILE_SIZE: 10 * 1024 * 1024, // 10MB
    ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
    ALLOWED_DOCUMENT_TYPES: ['application/pdf', 'application/msword'],
    CROP_IMAGE_PATH: 'uploads/crop_images',
    PROFILE_IMAGE_PATH: 'uploads/profile_pictures',
    PRODUCT_IMAGE_PATH: 'uploads/shop_products',
  },

  // ✅ Cloudinary Configuration
  CLOUDINARY: {
    CLOUD_NAME: process.env.CLOUDINARY_CLOUD_NAME,
    API_KEY:    process.env.CLOUDINARY_API_KEY,
    API_SECRET: process.env.CLOUDINARY_API_SECRET,
    FOLDER:     process.env.CLOUDINARY_FOLDER || 'govi_sahaya',
    FOLDERS: {
      PROFILES: 'govi_sahaya/profiles',
      CROPS:    'govi_sahaya/crops',
      PRODUCTS: 'govi_sahaya/products',
      FORUM:    'govi_sahaya/forum',
      DISEASES: 'govi_sahaya/diseases',
    },
    TRANSFORMS: {
      PROFILE: { width: 400,  height: 400,  crop: 'fill',  quality: 'auto' },
      PRODUCT: { width: 800,  height: 800,  crop: 'fill',  quality: 'auto' },
      FORUM:   { width: 1200, height: 800,  crop: 'limit', quality: 'auto' },
      THUMB:   { width: 150,  height: 150,  crop: 'fill',  quality: 'auto' },
    },
  },

  // Crop Disease Detection
  ML: {
    MODEL_PATH: './src/ml/models/crop_disease_model.h5',
    IMAGE_SIZE: 224,
    CONFIDENCE_THRESHOLD: 0.7,
    MAX_PREDICTIONS: 5,
  },

  // Supported Crops
  CROPS: {
    POTATO: 'potato',
    TOMATO: 'tomato',
    PUMPKIN: 'pumpkin',
    ONION: 'onion',
  },

  // Disease Categories
  DISEASE_CATEGORIES: {
    POTATO: 'potato',
    TOMATO: 'tomato',
    PUMPKIN: 'pumpkin',
    ONION: 'onion',
    GENERAL: 'general',
  },

  // Common Diseases by Crop
  COMMON_DISEASES: {
    POTATO: [
      'late_blight',
      'early_blight',
      'potato_virus_y',
      'black_scurf',
      'common_scab',
    ],
    TOMATO: [
      'early_blight',
      'late_blight',
      'leaf_curl',
      'bacterial_wilt',
      'mosaic_virus',
      'septoria_leaf_spot',
    ],
    PUMPKIN: [
      'powdery_mildew',
      'downy_mildew',
      'anthracnose',
      'bacterial_wilt',
      'mosaic_virus',
    ],
    ONION: [
      'purple_blotch',
      'downy_mildew',
      'white_rot',
      'neck_rot',
      'smut',
    ],
  },

  // Disease Severity Levels
  SEVERITY_LEVELS: {
    LOW: 'low',
    MODERATE: 'moderate',
    HIGH: 'high',
    CRITICAL: 'critical',
  },

  // Weather API
  WEATHER: {
    API_KEY:        process.env.WEATHER_API_KEY,
    BASE_URL:       'https://api.openweathermap.org/data/2.5',
    CACHE_DURATION: 30 * 60 * 1000, // 30 minutes
  },

  // News API
  NEWS: {
    API_KEY:   process.env.NEWS_API_KEY,
    BASE_URL:  'https://newsapi.org/v2',
    CATEGORY:  'agriculture',
    LANGUAGE:  'en',
    PAGE_SIZE: 20,
  },

  // Pagination
  PAGINATION: {
    DEFAULT_PAGE:  1,
    DEFAULT_LIMIT: 10,
    MAX_LIMIT:     100,
  },

  // Forum Configuration
  FORUM: {
    POST_MAX_LENGTH:    5000,
    COMMENT_MAX_LENGTH: 1000,
    MAX_TAGS:           5,
  },

  // Knowledge Hub Categories
  KNOWLEDGE_CATEGORIES: [
    'crop_management',
    'pest_control',
    'fertilizers',
    'irrigation',
    'harvesting',
    'storage',
    'marketing',
    'organic_farming',
    'modern_techniques',
  ],

  // Expense Categories
  EXPENSE_CATEGORIES: [
    'seeds',
    'fertilizers',
    'pesticides',
    'labor',
    'equipment',
    'irrigation',
    'transportation',
    'other',
  ],

  // Shop Categories
  SHOP_CATEGORIES: [
    'seeds',
    'fertilizers',
    'pesticides',
    'tools',
    'equipment',
    'irrigation',
    'organic_products',
  ],

  // Order Status
  ORDER_STATUS: {
    PENDING:    'pending',
    CONFIRMED:  'confirmed',
    PROCESSING: 'processing',
    SHIPPED:    'shipped',
    DELIVERED:  'delivered',
    CANCELLED:  'cancelled',
  },

  // Payment Methods
  PAYMENT_METHODS: {
    CASH_ON_DELIVERY: 'cash_on_delivery',
    CARD:             'card',
    BANK_TRANSFER:    'bank_transfer',
    MOBILE_PAYMENT:   'mobile_payment',
  },

  // Notification Types
  NOTIFICATION_TYPES: {
    WEATHER_ALERT:     'weather_alert',
    DISEASE_DETECTION: 'disease_detection',
    ORDER_UPDATE:      'order_update',
    FORUM_REPLY:       'forum_reply',
    PRICE_ALERT:       'price_alert',
    GENERAL:           'general',
  },

  // Rate Limiting
  RATE_LIMIT: {
    WINDOW_MS:    15 * 60 * 1000, // 15 minutes
    MAX_REQUESTS: 100,
    MESSAGE:      'Too many requests, please try again later.',
  },

  // SMS Configuration
  SMS: {
    PROVIDER:    'twilio',
    FROM_NUMBER: process.env.SMS_FROM_NUMBER,
  },

  // Email Configuration
  EMAIL: {
    FROM:    process.env.EMAIL_FROM || 'noreply@govishahaya.lk',
    SUPPORT: 'support@govishahaya.lk',
  },

  // Currency
  CURRENCY: {
    CODE:   'LKR',
    SYMBOL: 'Rs.',
    LOCALE: 'en-LK',
  },

  // Date Formats
  DATE_FORMATS: {
    SHORT:    'DD/MM/YYYY',
    LONG:     'DD MMMM YYYY',
    TIME:     'HH:mm:ss',
    DATETIME: 'DD/MM/YYYY HH:mm',
  },

  // Error Messages
  ERRORS: {
    INTERNAL_SERVER:   'Internal server error occurred',
    UNAUTHORIZED:      'Unauthorized access',
    FORBIDDEN:         'Access forbidden',
    NOT_FOUND:         'Resource not found',
    BAD_REQUEST:       'Bad request',
    VALIDATION_ERROR:  'Validation error',
    DATABASE_ERROR:    'Database operation failed',
    FILE_UPLOAD_ERROR: 'File upload failed',
    ML_PREDICTION_ERROR: 'ML prediction failed',
  },

  // Success Messages
  SUCCESS: {
    CREATED:   'Resource created successfully',
    UPDATED:   'Resource updated successfully',
    DELETED:   'Resource deleted successfully',
    RETRIEVED: 'Resource retrieved successfully',
  },

  // Regular Expressions
  REGEX: {
    EMAIL:    /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    PHONE_LK: /^(\+94|0)?[0-9]{9}$/,
    PASSWORD: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/,
    URL:      /^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$/,
  },

  // HTTP Status Codes
  HTTP_STATUS: {
    OK:                    200,
    CREATED:               201,
    NO_CONTENT:            204,
    BAD_REQUEST:           400,
    UNAUTHORIZED:          401,
    FORBIDDEN:             403,
    NOT_FOUND:             404,
    CONFLICT:              409,
    UNPROCESSABLE_ENTITY:  422,
    TOO_MANY_REQUESTS:     429,
    INTERNAL_SERVER_ERROR: 500,
    SERVICE_UNAVAILABLE:   503,
  },
};
