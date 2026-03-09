// src/routes/mlRoutes.js

const express = require('express');
const router = express.Router();
const mlController = require('../controllers/mlController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { uploadToMemory, uploadMultipleToMemory } = require('../middleware/uploadMiddleware'); // ✅ FIXED

// ============================================
// ML PREDICTION ROUTES
// ============================================

router.get('/health',     mlController.getHealth);
router.get('/model-info', mlController.getModelInfo);
router.get('/test',       mlController.testML);

router.post(
  '/detect-disease',
  protect,
  uploadToMemory('image'),            // ✅ memory → req.file.buffer populated
  mlController.detectDisease
);

router.post(
  '/batch-detect',
  protect,
  uploadMultipleToMemory('images', 10), // ✅ FIXED: was uploadMultiple (Cloudinary, no buffer)
  mlController.batchDetect
);

router.post('/reconnect', protect, authorize('admin'), mlController.reconnect);

// ============================================
// DISEASE DATABASE ROUTES
// ============================================

router.get('/diseases',                mlController.getAllDiseases);
router.get('/diseases/search',         mlController.searchDiseases);
router.get('/diseases/crop/:cropType', mlController.getDiseasesByCrop);
router.get('/diseases/:id',            mlController.getDiseaseById);
router.get('/categories',              mlController.getCategories);

router.post('/diseases',       protect, authorize('admin'), mlController.createDisease);
router.put('/diseases/:id',    protect, authorize('admin'), mlController.updateDisease);
router.delete('/diseases/:id', protect, authorize('admin'), mlController.deleteDisease);

module.exports = router;
