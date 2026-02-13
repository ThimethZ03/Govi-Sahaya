const sharp = require('sharp');
const logger = require('../utils/logger');

// Resize image
exports.resizeImage = async (imageBuffer, width, height, options = {}) => {
  try {
    const { fit = 'cover', quality = 80 } = options;

    return await sharp(imageBuffer)
      .resize(width, height, { fit })
      .jpeg({ quality })
      .toBuffer();
  } catch (error) {
    logger.error('Resize image error:', error);
    throw new Error('Failed to resize image');
  }
};

// Compress image
exports.compressImage = async (imageBuffer, quality = 80) => {
  try {
    return await sharp(imageBuffer)
      .jpeg({ quality, progressive: true })
      .toBuffer();
  } catch (error) {
    logger.error('Compress image error:', error);
    throw new Error('Failed to compress image');
  }
};

// Convert image format
exports.convertFormat = async (imageBuffer, format = 'jpeg') => {
  try {
    const sharpImage = sharp(imageBuffer);

    switch (format.toLowerCase()) {
      case 'jpeg':
      case 'jpg':
        return await sharpImage.jpeg({ quality: 90 }).toBuffer();
      case 'png':
        return await sharpImage.png({ compressionLevel: 9 }).toBuffer();
      case 'webp':
        return await sharpImage.webp({ quality: 90 }).toBuffer();
      default:
        throw new Error(`Unsupported format: ${format}`);
    }
  } catch (error) {
    logger.error('Convert format error:', error);
    throw new Error('Failed to convert image format');
  }
};

// Create thumbnail
exports.createThumbnail = async (imageBuffer, size = 200) => {
  try {
    return await sharp(imageBuffer)
      .resize(size, size, {
        fit: 'cover',
        position: 'center',
      })
      .jpeg({ quality: 80 })
      .toBuffer();
  } catch (error) {
    logger.error('Create thumbnail error:', error);
    throw new Error('Failed to create thumbnail');
  }
};

// Get image metadata
exports.getImageMetadata = async (imageBuffer) => {
  try {
    const metadata = await sharp(imageBuffer).metadata();

    return {
      width: metadata.width,
      height: metadata.height,
      format: metadata.format,
      size: metadata.size,
      hasAlpha: metadata.hasAlpha,
      orientation: metadata.orientation,
    };
  } catch (error) {
    logger.error('Get image metadata error:', error);
    throw new Error('Failed to get image metadata');
  }
};

// Crop image
exports.cropImage = async (imageBuffer, left, top, width, height) => {
  try {
    return await sharp(imageBuffer)
      .extract({ left, top, width, height })
      .toBuffer();
  } catch (error) {
    logger.error('Crop image error:', error);
    throw new Error('Failed to crop image');
  }
};

// Rotate image
exports.rotateImage = async (imageBuffer, angle) => {
  try {
    return await sharp(imageBuffer)
      .rotate(angle)
      .toBuffer();
  } catch (error) {
    logger.error('Rotate image error:', error);
    throw new Error('Failed to rotate image');
  }
};

// Add watermark
exports.addWatermark = async (imageBuffer, watermarkBuffer, position = 'bottom-right') => {
  try {
    const image = sharp(imageBuffer);
    const metadata = await image.metadata();

    const watermarkResize = await sharp(watermarkBuffer)
      .resize(Math.floor(metadata.width * 0.2))
      .toBuffer();

    const gravity = position.replace('-', ' ');

    return await image
      .composite([
        {
          input: watermarkResize,
          gravity: gravity,
        },
      ])
      .toBuffer();
  } catch (error) {
    logger.error('Add watermark error:', error);
    throw new Error('Failed to add watermark');
  }
};

// Optimize image for web
exports.optimizeForWeb = async (imageBuffer, maxWidth = 1920) => {
  try {
    const metadata = await sharp(imageBuffer).metadata();

    let image = sharp(imageBuffer);

    // Resize if larger than maxWidth
    if (metadata.width > maxWidth) {
      image = image.resize(maxWidth, null, {
        fit: 'inside',
        withoutEnlargement: true,
      });
    }

    // Optimize and convert to WebP
    return await image
      .webp({ quality: 85, effort: 6 })
      .toBuffer();
  } catch (error) {
    logger.error('Optimize for web error:', error);
    throw new Error('Failed to optimize image');
  }
};

// Remove background (requires additional library like @tensorflow-models/body-pix)
exports.removeBackground = async (imageBuffer) => {
  try {
    // Placeholder - requires ML model integration
    logger.warn('Background removal not implemented');
    return imageBuffer;
  } catch (error) {
    logger.error('Remove background error:', error);
    throw new Error('Failed to remove background');
  }
};

// Adjust brightness
exports.adjustBrightness = async (imageBuffer, multiplier = 1.2) => {
  try {
    return await sharp(imageBuffer)
      .modulate({ brightness: multiplier })
      .toBuffer();
  } catch (error) {
    logger.error('Adjust brightness error:', error);
    throw new Error('Failed to adjust brightness');
  }
};

// Adjust contrast
exports.adjustContrast = async (imageBuffer, amount = 1.2) => {
  try {
    return await sharp(imageBuffer)
      .linear(amount, -(128 * amount) + 128)
      .toBuffer();
  } catch (error) {
    logger.error('Adjust contrast error:', error);
    throw new Error('Failed to adjust contrast');
  }
};

// Apply blur
exports.applyBlur = async (imageBuffer, sigma = 5) => {
  try {
    return await sharp(imageBuffer)
      .blur(sigma)
      .toBuffer();
  } catch (error) {
    logger.error('Apply blur error:', error);
    throw new Error('Failed to apply blur');
  }
};

// Sharpen image
exports.sharpenImage = async (imageBuffer, amount = 1) => {
  try {
    return await sharp(imageBuffer)
      .sharpen({ sigma: amount })
      .toBuffer();
  } catch (error) {
    logger.error('Sharpen image error:', error);
    throw new Error('Failed to sharpen image');
  }
};

// Convert to grayscale
exports.toGrayscale = async (imageBuffer) => {
  try {
    return await sharp(imageBuffer)
      .grayscale()
      .toBuffer();
  } catch (error) {
    logger.error('Convert to grayscale error:', error);
    throw new Error('Failed to convert to grayscale');
  }
};
