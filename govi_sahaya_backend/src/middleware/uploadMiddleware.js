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
  if (!file || !file.mimetype) return cb(null, true);
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
  if (!file || !file.mimetype) return cb(null, true);
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

// ✅ Relaxed filter JUST for planner receipts
const receiptFileFilter = (req, file, cb) => {
  if (!file || !file.mimetype) return cb(null, true);

  const mime = file.mimetype.toLowerCase();
  console.log('📎 Receipt mimetype:', mime);  // <-- ADD THIS LINE

  // Accept any image/*
  if (mime.startsWith('image/')) {
    return cb(null, true);
  }

  // Accept specific document types (PDF, DOC)
  if (UPLOAD.ALLOWED_DOCUMENT_TYPES.includes(mime)) {
    return cb(null, true);
  }

  return cb(
    new Error(
      `Invalid file type. Allowed: image/*, ${UPLOAD.ALLOWED_DOCUMENT_TYPES.join(', ')}`
    ),
    false
  );
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

// ── Planner Receipt Storage ────────────────────────────────────────────
const receiptStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder:          'govi-sahaya/receipts',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    transformation:  [{ width: 1200, height: 1200, crop: 'limit', quality: 'auto' }],
    public_id: (req) => `receipt_${req.user?.id || 'user'}_${Date.now()}`,
  },
});

// ── Multer Instances ───────────────────────────────────────────────────
const profileUploader  = multer({
  storage: profileStorage,
  limits:  { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter: imageOnlyFilter,
});

const cropUploader     = multer({
  storage: cropStorage,
  limits:  { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter: imageOnlyFilter,
});

const productUploader  = multer({
  storage: productStorage,
  limits:  { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter: imageOnlyFilter,
});

const forumUploader    = multer({
  storage: forumStorage,
  limits:  { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter: imageOnlyFilter,
});

const defaultUploader  = multer({
  storage: miscStorage,
  limits:  { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter,
});

// ✅ Use relaxed filter for receipts
const receiptUploader  = multer({
  storage: receiptStorage,
  limits:  { fileSize: UPLOAD.MAX_FILE_SIZE },
  fileFilter: receiptFileFilter,
});

const memoryUploader   = multer({
  storage: multer.memoryStorage(),
  limits:  { fileSize: UPLOAD.MAX_FILE_SIZE },
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

exports.uploadProfilePicture = (fieldName) =>
  wrapMulter(profileUploader.single(fieldName));

exports.uploadCropImage = (fieldName) =>
  wrapMulter(cropUploader.single(fieldName));

exports.uploadProductImage = (fieldName) =>
  wrapMulter(productUploader.single(fieldName));

exports.uploadForumImages = (fieldName, maxCount = 5) =>
  wrapMulter(forumUploader.array(fieldName, maxCount));

exports.uploadReceipt = (fieldName = 'receipt') =>
  wrapMulter(receiptUploader.single(fieldName));

// Optional receipt (create + update expense)
exports.uploadReceiptOptional = (fieldName = 'receipt') =>
  (req, res, next) => {
    receiptUploader.single(fieldName)(req, res, (err) => {
      if (!err && !req.file) {
        return next();
      }

      if (err instanceof multer.MulterError) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: err.code === 'LIMIT_FILE_SIZE'
            ? `File size cannot exceed ${UPLOAD.MAX_FILE_SIZE / (1024 * 1024)}MB`
            : err.message,
        });
      }

      if (err) {
        console.error('❌ Receipt upload error:', err.message);
        return res.status(500).json({
          success: false,
          message: 'Failed to upload receipt: ' + err.message,
        });
      }

      console.log('✅ Receipt uploaded:', req.file?.path);
      return next();
    });
  };

exports.uploadSingle = (fieldName) =>
  wrapMulter(defaultUploader.single(fieldName));

exports.uploadMultiple = (fieldName, maxCount = 5) =>
  wrapMulter(defaultUploader.array(fieldName, maxCount));

exports.uploadFields = (fields) =>
  wrapMulter(defaultUploader.fields(fields));

exports.uploadToMemory = (fieldName = 'image') =>
  wrapMulter(memoryUploader.single(fieldName));

exports.uploadMultipleToMemory = (fieldName = 'images', maxCount = 10) =>
  wrapMulter(memoryUploader.array(fieldName, maxCount));

exports.validateFile = (req, res, next) => {
  if (!req.file && !req.files) {
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'No file uploaded',
    });
  }
  next();
};
