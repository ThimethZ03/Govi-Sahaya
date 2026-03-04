// src/middleware/uploadMiddleware.js

const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('cloudinary').v2;
const { HTTP_STATUS, UPLOAD, CLOUDINARY } = require('../config/constants');

// ── Configure Cloudinary ───────────────────────────────────────────────
cloudinary.config({
  cloud_name: CLOUDINARY.CLOUD_NAME,
  api_key:    CLOUDINARY.API_KEY,
  api_secret: CLOUDINARY.API_SECRET,
});

// ── File Filters ───────────────────────────────────────────────────────
const imageOnlyFilter = (req, file, cb) => {
  const isImage = UPLOAD.ALLOWED_IMAGE_TYPES.includes(file.mimetype);
  if (isImage) {
    cb(null, true);
  } else {
    cb(
      new Error(
        `Invalid file type. Only images allowed: ${UPLOAD.ALLOWED_IMAGE_TYPES.join(', ')}`
      ),
      false
    );
  }
};

const fileFilter = (req, file, cb) => {
  const isImage    = UPLOAD.ALLOWED_IMAGE_TYPES.includes(file.mimetype);
  const isDocument = UPLOAD.ALLOWED_DOCUMENT_TYPES.includes(file.mimetype);
  if (isImage || isDocument) {
    cb(null, true);
  } else {
    cb(
      new Error(
        `Invalid file type. Allowed: ${[
          ...UPLOAD.ALLOWED_IMAGE_TYPES,
          ...UPLOAD.ALLOWED_DOCUMENT_TYPES,
        ].join(', ')}`
      ),
      false
    );
  }
};

// ── Cloudinary Storage Engines ─────────────────────────────────────────
const profileStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder:          CLOUDINARY.FOLDERS.PROFILES,
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation:  [{ width: 400, height: 400, crop: 'fill', quality: 'auto' }],
    public_id: (req, file) => `profile_${req.user?.id || 'user'}_${Date.now()}`,
  },
});

const cropStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder:          CLOUDINARY.FOLDERS.CROPS,
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation:  [{ width: 800, height: 800, crop: 'limit', quality: 'auto' }],
    public_id: (req, file) => `crop_${Date.now()}`,
  },
});

const productStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder:          CLOUDINARY.FOLDERS.PRODUCTS,
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation:  [{ width: 800, height: 800, crop: 'fill', quality: 'auto' }],
    public_id: (req, file) => `product_${Date.now()}`,
  },
});

const forumStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder:          CLOUDINARY.FOLDERS.FORUM,
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation:  [{ width: 1200, height: 800, crop: 'limit', quality: 'auto' }],
    public_id: (req, file) => `forum_${Date.now()}`,
  },
});

const miscStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder:          CLOUDINARY.FOLDER,
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    public_id: (req, file) => `misc_${Date.now()}`,
  },
});

// ── Multer Instances ───────────────────────────────────────────────────
const profileUploader = multer({
  storage:    profileStorage,
  limits:     { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter: imageOnlyFilter,
});

const cropUploader = multer({
  storage:    cropStorage,
  limits:     { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter: imageOnlyFilter,
});

const productUploader = multer({
  storage:    productStorage,
  limits:     { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter: imageOnlyFilter,
});

const forumUploader = multer({
  storage:    forumStorage,
  limits:     { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter: imageOnlyFilter,
});

const defaultUploader = multer({
  storage:    miscStorage,
  limits:     { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter,
});

// ✅ NEW: Memory storage uploader — for ML service (needs req.file.buffer)
const memoryUploader = multer({
  storage:    multer.memoryStorage(),
  limits:     { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter: imageOnlyFilter,
});

// ── Error Handler Wrapper ──────────────────────────────────────────────
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

// ── Helper: Delete image from Cloudinary ──────────────────────────────
exports.deleteImage = async (imageUrl) => {
  try {
    if (!imageUrl || !imageUrl.includes('cloudinary')) return;
    const parts = imageUrl.split('/');
    const uploadIndex = parts.indexOf('upload');
    if (uploadIndex === -1) return;
    const pathParts = parts.slice(uploadIndex + 1);
    if (pathParts[0].startsWith('v') && !isNaN(pathParts[0].slice(1))) {
      pathParts.shift();
    }
    const publicId = pathParts.join('/').replace(/\.[^/.]+$/, '');
    await cloudinary.uploader.destroy(publicId);
  } catch (err) {
    console.error('Cloudinary delete error:', err.message);
  }
};

// ── Exports ────────────────────────────────────────────────────────────

// ✅ Profile picture → Cloudinary profiles folder
exports.uploadProfilePicture = (fieldName) =>
  wrapMulter(profileUploader.single(fieldName));

// ✅ Crop / disease images → Cloudinary crops folder
exports.uploadCropImage = (fieldName) =>
  wrapMulter(cropUploader.single(fieldName));

// ✅ Shop product images → Cloudinary products folder
exports.uploadProductImage = (fieldName) =>
  wrapMulter(productUploader.single(fieldName));

// ✅ Forum post images (multiple) → Cloudinary forum folder
exports.uploadForumImages = (fieldName, maxCount = 5) =>
  wrapMulter(forumUploader.array(fieldName, maxCount));

// ✅ Generic single/multiple → Cloudinary misc folder
exports.uploadSingle = (fieldName) =>
  wrapMulter(defaultUploader.single(fieldName));

exports.uploadMultiple = (fieldName, maxCount = 5) =>
  wrapMulter(defaultUploader.array(fieldName, maxCount));

exports.uploadFields = (fields) =>
  wrapMulter(defaultUploader.fields(fields));

// ✅ Memory storage — ML service only (req.file.buffer populated, no Cloudinary upload)
exports.uploadToMemory = (fieldName = 'image') =>
  wrapMulter(memoryUploader.single(fieldName));

exports.uploadMultipleToMemory = (fieldName = 'images', maxCount = 10) =>
  wrapMulter(memoryUploader.array(fieldName, maxCount));

// ✅ Validate uploaded file exists
exports.validateFile = (req, res, next) => {
  if (!req.file && !req.files) {
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'No file uploaded',
    });
  }
  next();
};
