// src/middleware/uploadMiddleware.js

const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { HTTP_STATUS, UPLOAD } = require('../config/constants');

// ✅ Base uploads directory
const uploadsBaseDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadsBaseDir)) {
  fs.mkdirSync(uploadsBaseDir, { recursive: true });
}

// ✅ helper: create directory if missing
function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

// ✅ Safe filename
function makeSafeFilename(originalname) {
  const clean = originalname.replace(/\s+/g, '_');
  return `${Date.now()}_${clean}`;
}

// ✅ file filter (images + documents)
const fileFilter = (req, file, cb) => {
  const isImage = UPLOAD.ALLOWED_IMAGE_TYPES.includes(file.mimetype);
  const isDocument = UPLOAD.ALLOWED_DOCUMENT_TYPES.includes(file.mimetype);

  if (isImage || isDocument) cb(null, true);
  else {
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

// ✅ image-only filter (profile picture)
const imageOnlyFilter = (req, file, cb) => {
  const isImage = UPLOAD.ALLOWED_IMAGE_TYPES.includes(file.mimetype);
  if (isImage) cb(null, true);
  else {
    cb(
      new Error(
        `Invalid file type. Only images allowed: ${UPLOAD.ALLOWED_IMAGE_TYPES.join(', ')}`
      ),
      false
    );
  }
};

// ✅ create a multer instance with a specific folder
function createUploader(folderName, { imagesOnly = false } = {}) {
  const uploadDir = path.join(uploadsBaseDir, folderName);
  ensureDir(uploadDir);

  const storage = multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
      cb(null, makeSafeFilename(file.originalname));
    },
  });

  return multer({
    storage,
    limits: { fileSize: UPLOAD.MAX_FILE_SIZE },
    fileFilter: imagesOnly ? imageOnlyFilter : fileFilter,
  });
}

// ✅ Specific uploaders (different folders)
const forumUploader = createUploader('forum_posts');
const cropUploader = createUploader('crop_images', { imagesOnly: true });
const profileUploader = createUploader('profile_pictures', { imagesOnly: true });

// ✅ Default uploader (fallback folder)
const defaultUploader = createUploader('misc');

// -----------------------------
// Error handler wrapper
// -----------------------------
function wrapMulter(multerFn) {
  return (req, res, next) => {
    multerFn(req, res, (err) => {
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
            message: 'Too many files uploaded',
          });
        }
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: err.message,
        });
      }

      if (err) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: err.message,
        });
      }

      next();
    });
  };
}

// -----------------------------
// ✅ Exports
// -----------------------------

// ✅ NEW: correct folder functions
exports.uploadForumImages = (fieldName, maxCount = 5) =>
  wrapMulter(forumUploader.array(fieldName, maxCount));

exports.uploadCropImage = (fieldName) =>
  wrapMulter(cropUploader.single(fieldName));

exports.uploadProfilePicture = (fieldName) =>
  wrapMulter(profileUploader.single(fieldName));

// ✅ Backward-compatible generic functions (so old routes don't break)
exports.uploadSingle = (fieldName) =>
  wrapMulter(defaultUploader.single(fieldName));

exports.uploadMultiple = (fieldName, maxCount = 5) =>
  wrapMulter(defaultUploader.array(fieldName, maxCount));

exports.uploadFields = (fields) =>
  wrapMulter(defaultUploader.fields(fields));

// ✅ Validate uploaded file
exports.validateFile = (req, res, next) => {
  if (!req.file && !req.files) {
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'No file uploaded',
    });
  }
  next();
};