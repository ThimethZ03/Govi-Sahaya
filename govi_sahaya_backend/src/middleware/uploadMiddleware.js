const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { HTTP_STATUS, UPLOAD } = require('../config/constants');

// ✅ Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// ✅ Disk storage for local file uploads (instead of memory for Firebase)
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadPath = path.join(__dirname, '../../uploads/forum_posts');
    
    // Create directory if it doesn't exist
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    
    cb(null, uploadPath);
  },
  filename: function (req, file, cb) {
    // Generate unique filename: timestamp_originalname
    const uniqueSuffix = Date.now() + '_' + file.originalname.replace(/\s+/g, '_');
    cb(null, uniqueSuffix);
  }
});

// File filter
const fileFilter = (req, file, cb) => {
  // Check file type based on mimetype
  const isImage = UPLOAD.ALLOWED_IMAGE_TYPES.includes(file.mimetype);
  const isDocument = UPLOAD.ALLOWED_DOCUMENT_TYPES.includes(file.mimetype);

  if (isImage || isDocument) {
    cb(null, true);
  } else {
    cb(
      new Error(
        `Invalid file type. Allowed types: ${[
          ...UPLOAD.ALLOWED_IMAGE_TYPES,
          ...UPLOAD.ALLOWED_DOCUMENT_TYPES,
        ].join(', ')}`
      ),
      false
    );
  }
};

// Configure multer
const upload = multer({
  storage: storage, // ✅ Changed from memoryStorage to diskStorage
  limits: {
    fileSize: UPLOAD.MAX_FILE_SIZE,
  },
  fileFilter: fileFilter,
});

// Single file upload
exports.uploadSingle = (fieldName) => {
  return (req, res, next) => {
    const uploadMiddleware = upload.single(fieldName);

    uploadMiddleware(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return res.status(HTTP_STATUS.BAD_REQUEST).json({
            success: false,
            message: `File size cannot exceed ${UPLOAD.MAX_FILE_SIZE / (1024 * 1024)}MB`,
          });
        }
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: err.message,
        });
      } else if (err) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: err.message,
        });
      }
      next();
    });
  };
};

// Multiple files upload
exports.uploadMultiple = (fieldName, maxCount = 5) => {
  return (req, res, next) => {
    const uploadMiddleware = upload.array(fieldName, maxCount);

    uploadMiddleware(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return res.status(HTTP_STATUS.BAD_REQUEST).json({
            success: false,
            message: `File size cannot exceed ${UPLOAD.MAX_FILE_SIZE / (1024 * 1024)}MB`,
          });
        }
        if (err.code === 'LIMIT_FILE_COUNT') {
          return res.status(HTTP_STATUS.BAD_REQUEST).json({
            success: false,
            message: `Cannot upload more than ${maxCount} files`,
          });
        }
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: err.message,
        });
      } else if (err) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: err.message,
        });
      }
      next();
    });
  };
};

// Multiple fields upload
exports.uploadFields = (fields) => {
  return (req, res, next) => {
    const uploadMiddleware = upload.fields(fields);

    uploadMiddleware(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return res.status(HTTP_STATUS.BAD_REQUEST).json({
            success: false,
            message: `File size cannot exceed ${UPLOAD.MAX_FILE_SIZE / (1024 * 1024)}MB`,
          });
        }
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: err.message,
        });
      } else if (err) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: err.message,
        });
      }
      next();
    });
  };
};

// Image only filter
exports.imageFilter = (req, file, cb) => {
  if (UPLOAD.ALLOWED_IMAGE_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(
      new Error(
        `Invalid file type. Only images are allowed: ${UPLOAD.ALLOWED_IMAGE_TYPES.join(', ')}`
      ),
      false
    );
  }
};

// Validate uploaded file
exports.validateFile = (req, res, next) => {
  if (!req.file && !req.files) {
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'No file uploaded',
    });
  }
  next();
};
