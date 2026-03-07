const sharp = require('sharp');

/**
 * Data Augmentation for Training Images
 * Generates variations of images to improve model robustness
 */
class DataAugmentation {
  constructor(options = {}) {
    this.rotationRange = options.rotationRange || 20;
    this.brightnessRange = options.brightnessRange || [0.8, 1.2];
    this.flipHorizontal = options.flipHorizontal !== false;
    this.flipVertical = options.flipVertical || false;
    this.zoomRange = options.zoomRange || [0.9, 1.1];
    this.shearRange = options.shearRange || 0.1;
    this.contrastRange = options.contrastRange || [0.8, 1.2];
  }

  /**
   * Apply random rotation
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Rotated image
   */
  async randomRotation(imageBuffer) {
    const angle = Math.random() * this.rotationRange * 2 - this.rotationRange;
    return await sharp(imageBuffer)
      .rotate(angle, { background: { r: 255, g: 255, b: 255 } })
      .toBuffer();
  }

  /**
   * Apply random brightness adjustment
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Brightness-adjusted image
   */
  async randomBrightness(imageBuffer) {
    const brightness = 
      Math.random() * (this.brightnessRange[1] - this.brightnessRange[0]) + 
      this.brightnessRange[0];
    
    return await sharp(imageBuffer)
      .modulate({ brightness: brightness })
      .toBuffer();
  }

  /**
   * Apply random contrast adjustment
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Contrast-adjusted image
   */
  async randomContrast(imageBuffer) {
    const contrast = 
      Math.random() * (this.contrastRange[1] - this.contrastRange[0]) + 
      this.contrastRange[0];
    
    return await sharp(imageBuffer)
      .linear(contrast, -(128 * contrast) + 128)
      .toBuffer();
  }

  /**
   * Apply horizontal flip
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Flipped image
   */
  async horizontalFlip(imageBuffer) {
    return await sharp(imageBuffer)
      .flop()
      .toBuffer();
  }

  /**
   * Apply vertical flip
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Flipped image
   */
  async verticalFlip(imageBuffer) {
    return await sharp(imageBuffer)
      .flip()
      .toBuffer();
  }

  /**
   * Apply random zoom
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Zoomed image
   */
  async randomZoom(imageBuffer) {
    const zoom = 
      Math.random() * (this.zoomRange[1] - this.zoomRange[0]) + 
      this.zoomRange[0];
    
    const image = sharp(imageBuffer);
    const metadata = await image.metadata();
    
    const newWidth = Math.floor(metadata.width * zoom);
    const newHeight = Math.floor(metadata.height * zoom);
    
    if (zoom > 1) {
      // Zoom in - resize then crop center
      return await image
        .resize(newWidth, newHeight)
        .extract({
          left: Math.floor((newWidth - metadata.width) / 2),
          top: Math.floor((newHeight - metadata.height) / 2),
          width: metadata.width,
          height: metadata.height
        })
        .toBuffer();
    } else {
      // Zoom out - resize then add padding
      return await image
        .resize(newWidth, newHeight)
        .extend({
          top: Math.floor((metadata.height - newHeight) / 2),
          bottom: Math.ceil((metadata.height - newHeight) / 2),
          left: Math.floor((metadata.width - newWidth) / 2),
          right: Math.ceil((metadata.width - newWidth) / 2),
          background: { r: 255, g: 255, b: 255 }
        })
        .toBuffer();
    }
  }

  /**
   * Apply random shift (translation)
   * @param {Buffer} imageBuffer - Input image buffer
   * @param {number} shiftRange - Shift range (0-1)
   * @returns {Promise<Buffer>} Shifted image
   */
  async randomShift(imageBuffer, shiftRange = 0.1) {
    const image = sharp(imageBuffer);
    const metadata = await image.metadata();
    
    const shiftX = Math.floor(
      (Math.random() * 2 - 1) * metadata.width * shiftRange
    );
    const shiftY = Math.floor(
      (Math.random() * 2 - 1) * metadata.height * shiftRange
    );

    const extendOptions = {
      top: Math.max(0, -shiftY),
      bottom: Math.max(0, shiftY),
      left: Math.max(0, -shiftX),
      right: Math.max(0, shiftX),
      background: { r: 255, g: 255, b: 255 }
    };

    return await image
      .extend(extendOptions)
      .extract({
        left: Math.max(0, shiftX),
        top: Math.max(0, shiftY),
        width: metadata.width,
        height: metadata.height
      })
      .toBuffer();
  }

  /**
   * Apply random hue adjustment
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Hue-adjusted image
   */
  async randomHue(imageBuffer) {
    const hueRotation = Math.floor(Math.random() * 60 - 30); // -30 to +30 degrees
    
    return await sharp(imageBuffer)
      .modulate({ hue: hueRotation })
      .toBuffer();
  }

  /**
   * Apply random saturation adjustment
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Saturation-adjusted image
   */
  async randomSaturation(imageBuffer) {
    const saturation = 0.7 + Math.random() * 0.6; // 0.7 to 1.3
    
    return await sharp(imageBuffer)
      .modulate({ saturation: saturation })
      .toBuffer();
  }

  /**
   * Apply Gaussian blur
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Blurred image
   */
  async randomBlur(imageBuffer) {
    const sigma = Math.random() * 2; // 0 to 2
    
    return await sharp(imageBuffer)
      .blur(sigma)
      .toBuffer();
  }

  /**
   * Apply sharpening
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Sharpened image
   */
  async randomSharpen(imageBuffer) {
    return await sharp(imageBuffer)
      .sharpen()
      .toBuffer();
  }

  /**
   * Apply random noise
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Image with noise
   */
  async randomNoise(imageBuffer) {
    const image = sharp(imageBuffer);
    const metadata = await image.metadata();
    
    // Add Gaussian noise by adjusting brightness randomly
    const noiseLevel = 0.02 + Math.random() * 0.03; // 2% to 5% noise
    
    return await image
      .modulate({ 
        brightness: 1 + (Math.random() * 2 - 1) * noiseLevel 
      })
      .toBuffer();
  }

  /**
   * Apply random crop
   * @param {Buffer} imageBuffer - Input image buffer
   * @param {number} cropRatio - Crop ratio (0-1)
   * @returns {Promise<Buffer>} Cropped image
   */
  async randomCrop(imageBuffer, cropRatio = 0.8) {
    const image = sharp(imageBuffer);
    const metadata = await image.metadata();
    
    const cropWidth = Math.floor(metadata.width * cropRatio);
    const cropHeight = Math.floor(metadata.height * cropRatio);
    
    const left = Math.floor(Math.random() * (metadata.width - cropWidth));
    const top = Math.floor(Math.random() * (metadata.height - cropHeight));
    
    return await image
      .extract({
        left: left,
        top: top,
        width: cropWidth,
        height: cropHeight
      })
      .resize(metadata.width, metadata.height)
      .toBuffer();
  }

  /**
   * Apply channel shift
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Channel-shifted image
   */
  async randomChannelShift(imageBuffer) {
    const shiftR = Math.floor(Math.random() * 40 - 20); // -20 to +20
    const shiftG = Math.floor(Math.random() * 40 - 20);
    const shiftB = Math.floor(Math.random() * 40 - 20);
    
    return await sharp(imageBuffer)
      .linear([1, 1, 1], [shiftR, shiftG, shiftB])
      .toBuffer();
  }

  /**
   * Apply perspective transformation (simple)
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Buffer>} Transformed image
   */
  async randomPerspective(imageBuffer) {
    const angle = Math.floor(Math.random() * 20 - 10); // -10 to +10 degrees
    
    return await sharp(imageBuffer)
      .rotate(angle, { background: { r: 255, g: 255, b: 255 } })
      .toBuffer();
  }

  /**
   * Apply random augmentation pipeline
   * @param {Buffer} imageBuffer - Input image buffer
   * @param {number} count - Number of augmented versions to generate
   * @returns {Promise<Array<Buffer>>} Array of augmented images
   */
  async augment(imageBuffer, count = 5) {
    const augmentedImages = [imageBuffer]; // Include original

    for (let i = 0; i < count; i++) {
      let currentImage = imageBuffer;

      // Randomly apply transformations with probability
      const transformations = [
        { fn: this.randomRotation.bind(this), prob: 0.5 },
        { fn: this.randomBrightness.bind(this), prob: 0.6 },
        { fn: this.randomContrast.bind(this), prob: 0.5 },
        { fn: this.randomSaturation.bind(this), prob: 0.4 },
        { fn: this.randomHue.bind(this), prob: 0.3 },
        { fn: this.randomZoom.bind(this), prob: 0.4 },
        { fn: this.randomShift.bind(this), prob: 0.4 },
        { fn: this.randomBlur.bind(this), prob: 0.2 },
        { fn: this.randomNoise.bind(this), prob: 0.3 }
      ];

      for (const { fn, prob } of transformations) {
        if (Math.random() < prob) {
          currentImage = await fn(currentImage);
        }
      }

      // Flip operations
      if (this.flipHorizontal && Math.random() > 0.5) {
        currentImage = await this.horizontalFlip(currentImage);
      }

      if (this.flipVertical && Math.random() > 0.5) {
        currentImage = await this.verticalFlip(currentImage);
      }

      augmentedImages.push(currentImage);
    }

    return augmentedImages;
  }

  /**
   * Apply specific augmentation
   * @param {Buffer} imageBuffer - Input image buffer
   * @param {string} type - Type of augmentation
   * @returns {Promise<Buffer>} Augmented image
   */
  async applyAugmentation(imageBuffer, type) {
    switch (type) {
      case 'rotate':
        return await this.randomRotation(imageBuffer);
      case 'brightness':
        return await this.randomBrightness(imageBuffer);
      case 'contrast':
        return await this.randomContrast(imageBuffer);
      case 'flip_h':
        return await this.horizontalFlip(imageBuffer);
      case 'flip_v':
        return await this.verticalFlip(imageBuffer);
      case 'zoom':
        return await this.randomZoom(imageBuffer);
      case 'shift':
        return await this.randomShift(imageBuffer);
      case 'hue':
        return await this.randomHue(imageBuffer);
      case 'saturation':
        return await this.randomSaturation(imageBuffer);
      case 'blur':
        return await this.randomBlur(imageBuffer);
      case 'sharpen':
        return await this.randomSharpen(imageBuffer);
      case 'noise':
        return await this.randomNoise(imageBuffer);
      case 'crop':
        return await this.randomCrop(imageBuffer);
      case 'channel_shift':
        return await this.randomChannelShift(imageBuffer);
      case 'perspective':
        return await this.randomPerspective(imageBuffer);
      default:
        return imageBuffer;
    }
  }

  /**
   * Generate augmented dataset
   * @param {Array<Buffer>} images - Array of image buffers
   * @param {number} augmentationsPerImage - Number of augmentations per image
   * @returns {Promise<Array<Buffer>>} Augmented dataset
   */
  async generateDataset(images, augmentationsPerImage = 5) {
    console.log(`🔄 Generating augmented dataset...`);
    console.log(`📊 Original images: ${images.length}`);
    console.log(`📊 Augmentations per image: ${augmentationsPerImage}`);
    
    const augmentedDataset = [];

    for (let i = 0; i < images.length; i++) {
      console.log(`Processing image ${i + 1}/${images.length}...`);
      const augmented = await this.augment(images[i], augmentationsPerImage);
      augmentedDataset.push(...augmented);
    }

    console.log(`✅ Generated ${augmentedDataset.length} total images`);
    return augmentedDataset;
  }

  /**
   * Save augmented images to directory
   * @param {Array<Buffer>} images - Array of image buffers
   * @param {string} outputDir - Output directory path
   * @param {string} prefix - Filename prefix
   * @returns {Promise<void>}
   */
  async saveAugmentedImages(images, outputDir, prefix = 'aug') {
    const fs = require('fs').promises;
    
    try {
      // Create directory if it doesn't exist
      await fs.mkdir(outputDir, { recursive: true });

      for (let i = 0; i < images.length; i++) {
        const filename = `${prefix}_${i.toString().padStart(4, '0')}.jpg`;
        const filepath = require('path').join(outputDir, filename);
        
        await sharp(images[i])
          .jpeg({ quality: 90 })
          .toFile(filepath);
      }

      console.log(`✅ Saved ${images.length} augmented images to ${outputDir}`);
    } catch (error) {
      throw new Error(`Failed to save augmented images: ${error.message}`);
    }
  }

  /**
   * Preview augmentations
   * @param {Buffer} imageBuffer - Input image buffer
   * @returns {Promise<Object>} Preview of all augmentation types
   */
  async previewAugmentations(imageBuffer) {
    const previews = {};
    
    const augmentationTypes = [
      'rotate', 'brightness', 'contrast', 'flip_h', 'flip_v',
      'zoom', 'shift', 'hue', 'saturation', 'blur', 'sharpen',
      'noise', 'crop', 'channel_shift', 'perspective'
    ];

    for (const type of augmentationTypes) {
      try {
        previews[type] = await this.applyAugmentation(imageBuffer, type);
      } catch (error) {
        console.warn(`Preview for ${type} failed:`, error.message);
        previews[type] = null;
      }
    }

    return previews;
  }
}

module.exports = DataAugmentation;
