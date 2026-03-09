// src/utils/cloudinary.js

const cloudinary = require('cloudinary').v2;
const logger     = require('./logger');

// ✅ Configure once — reads from .env
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Upload a buffer to Cloudinary
 * @param {Buffer} buffer    - File buffer from multer memoryStorage
 * @param {string} filename  - Original filename (used to generate clean public_id)
 * @param {string} folder    - ✅ Cloudinary folder (default: govi_sahaya/misc)
 * @returns {Promise<cloudinary.UploadApiResponse>} — has .secure_url, .public_id
 */
exports.uploadBuffer = (buffer, filename = 'upload', folder = 'govi_sahaya/misc') => {
  return new Promise((resolve, reject) => {
    // ✅ Guard: reject early if buffer is empty
    if (!buffer || buffer.length === 0) {
      return reject(new Error('Empty file buffer'));
    }

    // ✅ Clean filename → safe public_id (no extension, no special chars)
    const cleanName = (filename || 'upload')
      .replace(/\.[^/.]+$/, '')          // remove extension
      .replace(/[^a-zA-Z0-9_-]/g, '_')  // sanitize special chars
      .substring(0, 80);                 // limit length

    // ✅ Prefix matches the folder for easy identification
    const folderPrefix = folder.split('/').pop() || 'file'; // e.g. 'crop_doctor', 'forum'

    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,                                                    // ✅ dynamic — passed by caller
        public_id:       `${folderPrefix}_${Date.now()}_${cleanName}`,
        resource_type:   'image',
        allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
        transformation:  [{ width: 1200, height: 1200, crop: 'limit', quality: 'auto' }],
      },
      (error, result) => {
        if (error) {
          logger.error('❌ Cloudinary upload error:', error.message);
          return reject(new Error(error.message));
        }
        logger.info(`✅ Cloudinary uploaded: ${result.secure_url}`);
        resolve(result); // ✅ full result — .secure_url + .public_id
      }
    );

    uploadStream.end(buffer);
  });
};

/**
 * Delete an image from Cloudinary by publicId
 * @param {string} publicId
 */
exports.deleteImage = async (publicId) => {
  try {
    if (!publicId) return;
    await cloudinary.uploader.destroy(publicId);
    logger.info(`✅ Cloudinary deleted: ${publicId}`);
  } catch (e) {
    logger.warn(`⚠️ Cloudinary delete failed: ${e.message}`);
  }
};

/**
 * Extract publicId from a Cloudinary URL
 * e.g. https://res.cloudinary.com/demo/image/upload/v123/folder/name.jpg
 *   -> folder/name
 */
exports.extractPublicId = (url) => {
  try {
    if (!url || !url.includes('cloudinary.com')) return null;
    const parts = url.split('/upload/');
    if (parts.length < 2) return null;
    const noVersion = parts[1].replace(/^v\d+\//, '');
    return noVersion.replace(/\.[^.]+$/, '');
  } catch (_) {
    return null;
  }
};
