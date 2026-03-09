const sharp = require('sharp');
const fs = require('fs').promises;

/**
 * Image Preprocessor for Crop Disease Detection
 * Prepares images for ML model inference
 */
class ImagePreprocessor {
  constructor(config = {}) {
    this.targetSize = config.targetSize || [224, 224];
    this.colorMode = config.colorMode || 'RGB';
    this.normalization = config.normalization || 'rescale_1_255';
  }

  /**
   * Preprocess image for model input
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @returns {Promise<Object>} Preprocessed image data
   */
  async preprocess(imagePath) {
    try {
      let imageBuffer;

      // Handle both Buffer and file path inputs
      if (Buffer.isBuffer(imagePath)) {
        imageBuffer = imagePath;
      } else {
        imageBuffer = await fs.readFile(imagePath);
      }

      // Resize and convert to RGB
      const processedBuffer = await sharp(imageBuffer)
        .resize(this.targetSize[0], this.targetSize[1], {
          fit: 'cover',
          position: 'center'
        })
        .removeAlpha() // Remove alpha channel
        .toColorspace('srgb') // Ensure RGB
        .raw()
        .toBuffer({ resolveWithObject: true });

      // Extract raw pixel data
      const { data, info } = processedBuffer;
      
      // Convert to array and normalize
      const pixels = new Float32Array(data.length);
      
      if (this.normalization === 'rescale_1_255') {
        // Normalize to [0, 1]
        for (let i = 0; i < data.length; i++) {
          pixels[i] = data[i] / 255.0;
        }
      } else if (this.normalization === 'standardize') {
        // Standardize with ImageNet mean and std
        const mean = [0.485, 0.456, 0.406];
        const std = [0.229, 0.224, 0.225];
        
        for (let i = 0; i < data.length; i += 3) {
          pixels[i] = (data[i] / 255.0 - mean[0]) / std[0];
          pixels[i + 1] = (data[i + 1] / 255.0 - mean[1]) / std[1];
          pixels[i + 2] = (data[i + 2] / 255.0 - mean[2]) / std[2];
        }
      }

      // Reshape to [1, height, width, channels] for model input
      const shape = [1, info.height, info.width, info.channels];

      return {
        data: pixels,
        shape: shape,
        width: info.width,
        height: info.height,
        channels: info.channels
      };
    } catch (error) {
      throw new Error(`Image preprocessing failed: ${error.message}`);
    }
  }

  /**
   * Batch preprocess multiple images
   * @param {Array} imagePaths - Array of image paths or buffers
   * @returns {Promise<Array>} Array of preprocessed images
   */
  async batchPreprocess(imagePaths) {
    const promises = imagePaths.map(path => this.preprocess(path));
    return Promise.all(promises);
  }

  /**
   * Extract image features for analysis
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @returns {Promise<Object>} Image features
   */
  async extractFeatures(imagePath) {
    try {
      let imageBuffer;

      if (Buffer.isBuffer(imagePath)) {
        imageBuffer = imagePath;
      } else {
        imageBuffer = await fs.readFile(imagePath);
      }

      const image = sharp(imageBuffer);
      const metadata = await image.metadata();
      const stats = await image.stats();

      return {
        format: metadata.format,
        width: metadata.width,
        height: metadata.height,
        channels: metadata.channels,
        space: metadata.space,
        hasAlpha: metadata.hasAlpha,
        colorStats: {
          channels: stats.channels.map(ch => ({
            mean: ch.mean,
            std: ch.std,
            min: ch.min,
            max: ch.max
          }))
        }
      };
    } catch (error) {
      throw new Error(`Feature extraction failed: ${error.message}`);
    }
  }

  /**
   * Validate image quality
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @returns {Promise<Object>} Validation result
   */
  async validateImage(imagePath) {
    try {
      const features = await this.extractFeatures(imagePath);
      
      const issues = [];
      
      // Check minimum size
      if (features.width < 100 || features.height < 100) {
        issues.push('Image resolution too low (minimum 100x100)');
      }
      
      // Check if image is too dark or too bright
      const avgBrightness = features.colorStats.channels
        .reduce((sum, ch) => sum + ch.mean, 0) / features.channels;
      
      if (avgBrightness < 30) {
        issues.push('Image is too dark');
      } else if (avgBrightness > 225) {
        issues.push('Image is too bright');
      }
      
      // Check if image is blurry (using standard deviation)
      const avgStd = features.colorStats.channels
        .reduce((sum, ch) => sum + ch.std, 0) / features.channels;
      
      if (avgStd < 20) {
        issues.push('Image may be blurry or lack detail');
      }

      return {
        isValid: issues.length === 0,
        issues: issues,
        features: features
      };
    } catch (error) {
      return {
        isValid: false,
        issues: [`Invalid image: ${error.message}`],
        features: null
      };
    }
  }

  /**
   * Apply image enhancements
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @param {Object} options - Enhancement options
   * @returns {Promise<Buffer>} Enhanced image buffer
   */
  async enhance(imagePath, options = {}) {
    try {
      let imageBuffer;

      if (Buffer.isBuffer(imagePath)) {
        imageBuffer = imagePath;
      } else {
        imageBuffer = await fs.readFile(imagePath);
      }

      let image = sharp(imageBuffer);

      // Apply enhancements
      if (options.brightness) {
        image = image.modulate({ brightness: options.brightness });
      }

      if (options.contrast) {
        image = image.linear(options.contrast, -(128 * options.contrast) + 128);
      }

      if (options.sharpen) {
        image = image.sharpen();
      }

      if (options.denoise) {
        image = image.median(3);
      }

      return await image.toBuffer();
    } catch (error) {
      throw new Error(`Image enhancement failed: ${error.message}`);
    }
  }

  /**
   * Convert image to base64
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @returns {Promise<string>} Base64 encoded image
   */
  async toBase64(imagePath) {
    try {
      let imageBuffer;

      if (Buffer.isBuffer(imagePath)) {
        imageBuffer = imagePath;
      } else {
        imageBuffer = await fs.readFile(imagePath);
      }

      const processedBuffer = await sharp(imageBuffer)
        .resize(this.targetSize[0], this.targetSize[1], {
          fit: 'cover'
        })
        .jpeg({ quality: 90 })
        .toBuffer();

      return `data:image/jpeg;base64,${processedBuffer.toString('base64')}`;
    } catch (error) {
      throw new Error(`Base64 conversion failed: ${error.message}`);
    }
  }

  /**
   * Get image thumbnail
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @param {number} size - Thumbnail size (default: 128)
   * @returns {Promise<Buffer>} Thumbnail buffer
   */
  async getThumbnail(imagePath, size = 128) {
    try {
      let imageBuffer;

      if (Buffer.isBuffer(imagePath)) {
        imageBuffer = imagePath;
      } else {
        imageBuffer = await fs.readFile(imagePath);
      }

      return await sharp(imageBuffer)
        .resize(size, size, {
          fit: 'cover',
          position: 'center'
        })
        .jpeg({ quality: 80 })
        .toBuffer();
    } catch (error) {
      throw new Error(`Thumbnail generation failed: ${error.message}`);
    }
  }

  /**
   * Crop image to focus on center
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @param {Object} options - Crop options
   * @returns {Promise<Buffer>} Cropped image buffer
   */
  async centerCrop(imagePath, options = {}) {
    try {
      let imageBuffer;

      if (Buffer.isBuffer(imagePath)) {
        imageBuffer = imagePath;
      } else {
        imageBuffer = await fs.readFile(imagePath);
      }

      const image = sharp(imageBuffer);
      const metadata = await image.metadata();

      const targetWidth = options.width || this.targetSize[0];
      const targetHeight = options.height || this.targetSize[1];

      // Calculate crop area
      const cropWidth = Math.min(metadata.width, targetWidth);
      const cropHeight = Math.min(metadata.height, targetHeight);
      const left = Math.floor((metadata.width - cropWidth) / 2);
      const top = Math.floor((metadata.height - cropHeight) / 2);

      return await image
        .extract({
          left: left,
          top: top,
          width: cropWidth,
          height: cropHeight
        })
        .resize(targetWidth, targetHeight)
        .toBuffer();
    } catch (error) {
      throw new Error(`Center crop failed: ${error.message}`);
    }
  }

  /**
   * Detect edges in image (useful for quality assessment)
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @returns {Promise<Object>} Edge detection result
   */
  async detectEdges(imagePath) {
    try {
      let imageBuffer;

      if (Buffer.isBuffer(imagePath)) {
        imageBuffer = imagePath;
      } else {
        imageBuffer = await fs.readFile(imagePath);
      }

      // Apply Sobel edge detection
      const edgeBuffer = await sharp(imageBuffer)
        .greyscale()
        .convolve({
          width: 3,
          height: 3,
          kernel: [-1, -1, -1, -1, 8, -1, -1, -1, -1]
        })
        .toBuffer();

      // Calculate edge strength
      const edgeStats = await sharp(edgeBuffer).stats();
      const edgeStrength = edgeStats.channels[0].mean;

      return {
        edgeStrength: edgeStrength,
        hasStrongEdges: edgeStrength > 30,
        edgeBuffer: edgeBuffer
      };
    } catch (error) {
      throw new Error(`Edge detection failed: ${error.message}`);
    }
  }

  /**
   * Calculate color histogram
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @returns {Promise<Object>} Color histogram
   */
  async getColorHistogram(imagePath) {
    try {
      let imageBuffer;

      if (Buffer.isBuffer(imagePath)) {
        imageBuffer = imagePath;
      } else {
        imageBuffer = await fs.readFile(imagePath);
      }

      const stats = await sharp(imageBuffer).stats();

      return {
        red: {
          mean: stats.channels[0].mean,
          std: stats.channels[0].std,
          min: stats.channels[0].min,
          max: stats.channels[0].max
        },
        green: {
          mean: stats.channels[1].mean,
          std: stats.channels[1].std,
          min: stats.channels[1].min,
          max: stats.channels[1].max
        },
        blue: {
          mean: stats.channels[2].mean,
          std: stats.channels[2].std,
          min: stats.channels[2].min,
          max: stats.channels[2].max
        },
        dominantColor: this.getDominantColor(stats.channels)
      };
    } catch (error) {
      throw new Error(`Histogram calculation failed: ${error.message}`);
    }
  }

  /**
   * Get dominant color from channel stats
   * @param {Array} channels - Channel statistics
   * @returns {string} Dominant color name
   */
  getDominantColor(channels) {
    const [red, green, blue] = channels.map(ch => ch.mean);

    if (red > green && red > blue) return 'red';
    if (green > red && green > blue) return 'green';
    if (blue > red && blue > green) return 'blue';
    
    // Check for common combinations
    if (red > 150 && green > 150 && blue < 100) return 'yellow';
    if (red < 100 && green < 100 && blue > 150) return 'blue';
    if (red > 150 && green < 100 && blue < 100) return 'red';
    if (red < 100 && green > 150 && blue < 100) return 'green';
    
    return 'mixed';
  }

  /**
   * Remove background (simple threshold-based)
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @returns {Promise<Buffer>} Image with background removed
   */
  async removeBackground(imagePath) {
    try {
      let imageBuffer;

      if (Buffer.isBuffer(imagePath)) {
        imageBuffer = imagePath;
      } else {
        imageBuffer = await fs.readFile(imagePath);
      }

      // Simple threshold-based background removal
      return await sharp(imageBuffer)
        .threshold(128) // Adjust threshold as needed
        .toBuffer();
    } catch (error) {
      throw new Error(`Background removal failed: ${error.message}`);
    }
  }

  /**
   * Normalize image orientation (fix rotation issues)
   * @param {Buffer|string} imagePath - Image buffer or file path
   * @returns {Promise<Buffer>} Normalized image
   */
  async normalizeOrientation(imagePath) {
    try {
      let imageBuffer;

      if (Buffer.isBuffer(imagePath)) {
        imageBuffer = imagePath;
      } else {
        imageBuffer = await fs.readFile(imagePath);
      }

      return await sharp(imageBuffer)
        .rotate() // Auto-rotate based on EXIF
        .toBuffer();
    } catch (error) {
      throw new Error(`Orientation normalization failed: ${error.message}`);
    }
  }

  /**
   * Save preprocessed image
   * @param {Buffer} imageBuffer - Image buffer
   * @param {string} outputPath - Output file path
   * @returns {Promise<void>}
   */
  async saveImage(imageBuffer, outputPath) {
    try {
      await sharp(imageBuffer)
        .jpeg({ quality: 90 })
        .toFile(outputPath);
      
      console.log(`✅ Image saved to: ${outputPath}`);
    } catch (error) {
      throw new Error(`Image save failed: ${error.message}`);
    }
  }
}

module.exports = ImagePreprocessor;
