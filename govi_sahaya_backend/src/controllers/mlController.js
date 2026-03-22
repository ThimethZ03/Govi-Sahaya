const Disease = require('../models/Disease');
const logger = require('../utils/logger');
const { HTTP_STATUS, DISEASE_CATEGORIES } = require('../config/constants');
const mlService = require('../services/mlService');

// ============================================
// ML PREDICTION CONTROLLERS (NEW)
// ============================================

/**
 * @desc    Detect disease from uploaded image
 * @route   POST /api/v1/ml/detect-disease
 * @access  Private
 */
exports.detectDisease = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'No image file uploaded. Please upload an image.'
      });
    }

    logger.info(`🔍 Processing disease detection for: ${req.file.originalname}`);

    // Get image buffer
    const imageBuffer = req.file.buffer;

    // Detect disease using ML service
    const predictions = await mlService.detectDisease(imageBuffer);

    logger.info(`✅ Disease detection completed`);

    // Return predictions
    return res.status(HTTP_STATUS.OK).json({
      success: true,
      predictions: predictions,
      imageInfo: {
        originalName: req.file.originalname,
        size: req.file.size,
        mimeType: req.file.mimetype
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    logger.error('❌ Disease detection error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Disease detection failed',
      error: error.message
    });
  }
};

/**
 * @desc    Batch detect diseases from multiple images
 * @route   POST /api/v1/ml/batch-detect
 * @access  Private
 */
exports.batchDetect = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'No image files uploaded'
      });
    }

    logger.info(`🔍 Processing batch detection for ${req.files.length} images`);

    // Get image buffers
    const imageBuffers = req.files.map(file => file.buffer);

    // Batch detect diseases
    const results = await mlService.batchDetectDiseases(imageBuffers);

    logger.info(`✅ Batch detection completed`);

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      totalImages: req.files.length,
      results: results,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    logger.error('❌ Batch detection error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Batch detection failed',
      error: error.message
    });
  }
};

/**
 * @desc    Get ML API health status
 * @route   GET /api/v1/ml/health
 * @access  Public
 */
exports.getHealth = async (req, res) => {
  try {
    const health = await mlService.checkHealth();
    
    return res.status(HTTP_STATUS.OK).json({
      success: true,
      ...health,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    logger.error('❌ Health check error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * @desc    Get ML model information
 * @route   GET /api/v1/ml/model-info
 * @access  Public
 */
exports.getModelInfo = async (req, res) => {
  try {
    const modelInfo = mlService.getModelInfo();
    
    return res.status(HTTP_STATUS.OK).json({
      success: true,
      modelInfo: modelInfo,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    logger.error('❌ Model info error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * @desc    Reconnect to ML API
 * @route   POST /api/v1/ml/reconnect
 * @access  Private (Admin only)
 */
exports.reconnect = async (req, res) => {
  try {
    logger.info('🔄 Attempting to reconnect to ML API...');
    
    const connected = await mlService.reconnect();
    
    return res.status(HTTP_STATUS.OK).json({
      success: true,
      connected: connected,
      message: connected 
        ? '✅ Successfully connected to ML API' 
        : '⚠️ Failed to connect to ML API',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    logger.error('❌ Reconnect error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * @desc    Test ML service with mock data
 * @route   GET /api/v1/ml/test
 * @access  Public
 */
exports.testML = async (req, res) => {
  try {
    logger.info('🧪 Testing ML service...');

    // Get mock predictions
    const mockPredictions = await mlService.getMockPredictions();
    
    // Get model info
    const modelInfo = mlService.getModelInfo();

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      message: '✅ ML Service test successful',
      mockPredictions: mockPredictions,
      modelInfo: modelInfo,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    logger.error('❌ ML test error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'ML service test failed',
      error: error.message
    });
  }
};

// ============================================
// DISEASE DATABASE CONTROLLERS (EXISTING)
// ============================================

/**
 * @desc    Get all diseases
 * @route   GET /api/v1/ml/diseases
 * @access  Public
 */
exports.getAllDiseases = async (req, res) => {
  try {
    const { category, severity, search } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = { isActive: true };

    if (category) query.category = category;
    if (severity) query.severity = severity;
    if (search) {
      query.$text = { $search: search };
    }

    const diseases = await Disease.find(query)
      .limit(limit)
      .skip(skip)
      .sort({ name: 1 });

    const total = await Disease.countDocuments(query);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: diseases,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get all diseases error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch diseases',
    });
  }
};

/**
 * @desc    Get disease by ID
 * @route   GET /api/v1/ml/diseases/:id
 * @access  Public
 */
exports.getDiseaseById = async (req, res) => {
  try {
    const disease = await Disease.findById(req.params.id);

    if (!disease) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Disease not found',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: disease,
    });
  } catch (error) {
    logger.error('Get disease by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch disease',
    });
  }
};

/**
 * @desc    Get diseases by crop
 * @route   GET /api/v1/ml/diseases/crop/:cropType
 * @access  Public
 */
exports.getDiseasesByCrop = async (req, res) => {
  try {
    const { cropType } = req.params;

    if (!Object.values(DISEASE_CATEGORIES).includes(cropType)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Invalid crop type',
      });
    }

    const diseases = await Disease.find({
      category: cropType,
      isActive: true,
    }).sort({ name: 1 });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: diseases,
      count: diseases.length,
    });
  } catch (error) {
    logger.error('Get diseases by crop error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch diseases',
    });
  }
};

/**
 * @desc    Search diseases
 * @route   GET /api/v1/ml/diseases/search
 * @access  Public
 */
exports.searchDiseases = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Search query is required',
      });
    }

    const diseases = await Disease.find({
      $text: { $search: q },
      isActive: true,
    }).limit(20);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: diseases,
    });
  } catch (error) {
    logger.error('Search diseases error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Search failed',
    });
  }
};

/**
 * @desc    Get disease categories
 * @route   GET /api/v1/ml/categories
 * @access  Public
 */
exports.getCategories = async (req, res) => {
  try {
    const categories = await Disease.aggregate([
      { $match: { isActive: true } },
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: categories,
    });
  } catch (error) {
    logger.error('Get categories error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch categories',
    });
  }
};

/**
 * @desc    Create disease (Admin only)
 * @route   POST /api/v1/ml/diseases
 * @access  Private/Admin
 */
exports.createDisease = async (req, res) => {
  try {
    const disease = await Disease.create(req.body);

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Disease created successfully',
      data: disease,
    });
  } catch (error) {
    logger.error('Create disease error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * @desc    Update disease (Admin only)
 * @route   PUT /api/v1/ml/diseases/:id
 * @access  Private/Admin
 */
exports.updateDisease = async (req, res) => {
  try {
    const disease = await Disease.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    if (!disease) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Disease not found',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Disease updated successfully',
      data: disease,
    });
  } catch (error) {
    logger.error('Update disease error:', error);
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * @desc    Delete disease (Admin only)
 * @route   DELETE /api/v1/ml/diseases/:id
 * @access  Private/Admin
 */
exports.deleteDisease = async (req, res) => {
  try {
    const disease = await Disease.findByIdAndUpdate(
      req.params.id,
      { isActive: false },
      { new: true }
    );

    if (!disease) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Disease not found',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Disease deleted successfully',
    });
  } catch (error) {
    logger.error('Delete disease error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete disease',
    });
  }
};
