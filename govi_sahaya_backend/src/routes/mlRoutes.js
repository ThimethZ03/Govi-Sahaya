const express = require('express');
const router = express.Router();
const mlController = require('../controllers/mlController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { uploadSingle, uploadMultiple } = require('../middleware/uploadMiddleware');

// ============================================
// ML PREDICTION ROUTES (NEW)
// ============================================

/**
 * @route   GET /api/v1/ml/health
 * @desc    Check ML API health status
 * @access  Public
 */
router.get('/health', mlController.getHealth);

/**
 * @route   GET /api/v1/ml/model-info
 * @desc    Get ML model information
 * @access  Public
 */
router.get('/model-info', mlController.getModelInfo);

/**
 * @route   GET /api/v1/ml/test
 * @desc    Test ML service with mock data
 * @access  Public
 */
router.get('/test', mlController.testML);

/**
 * @route   POST /api/v1/ml/detect-disease
 * @desc    Detect disease from uploaded image
 * @access  Private
 */
router.post(
  '/detect-disease',
  protect,
  uploadSingle('image'),
  mlController.detectDisease
);

/**
 * @route   POST /api/v1/ml/batch-detect
 * @desc    Detect diseases from multiple images
 * @access  Private
 */
router.post(
  '/batch-detect',
  protect,
  uploadMultiple('images', 10),
  mlController.batchDetect
);

/**
 * @route   POST /api/v1/ml/reconnect
 * @desc    Reconnect to ML API
 * @access  Private (Admin only)
 */
router.post('/reconnect', protect, authorize('admin'), mlController.reconnect);

// ============================================
// DISEASE DATABASE ROUTES (EXISTING)
// ============================================

/**
 * @route   GET /api/v1/ml/diseases
 * @desc    Get all diseases
 * @access  Public
 */
router.get('/diseases', mlController.getAllDiseases);

/**
 * @route   GET /api/v1/ml/diseases/search
 * @desc    Search diseases
 * @access  Public
 */
router.get('/diseases/search', mlController.searchDiseases);

/**
 * @route   GET /api/v1/ml/diseases/crop/:cropType
 * @desc    Get diseases by crop type
 * @access  Public
 */
router.get('/diseases/crop/:cropType', mlController.getDiseasesByCrop);

/**
 * @route   GET /api/v1/ml/diseases/:id
 * @desc    Get disease by ID
 * @access  Public
 */
router.get('/diseases/:id', mlController.getDiseaseById);

/**
 * @route   GET /api/v1/ml/categories
 * @desc    Get disease categories
 * @access  Public
 */
router.get('/categories', mlController.getCategories);

/**
 * @route   POST /api/v1/ml/diseases
 * @desc    Create new disease
 * @access  Private (Admin only)
 */
router.post('/diseases', protect, authorize('admin'), mlController.createDisease);

/**
 * @route   PUT /api/v1/ml/diseases/:id
 * @desc    Update disease
 * @access  Private (Admin only)
 */
router.put('/diseases/:id', protect, authorize('admin'), mlController.updateDisease);

/**
 * @route   DELETE /api/v1/ml/diseases/:id
 * @desc    Delete disease
 * @access  Private (Admin only)
 */
router.delete('/diseases/:id', protect, authorize('admin'), mlController.deleteDisease);

module.exports = router;
