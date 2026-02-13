const express = require('express');
const router = express.Router();

// Import all route modules
const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const cropDoctorRoutes = require('./cropDoctorRoutes');
const mlRoutes = require('./mlRoutes');
const weatherRoutes = require('./weatherRoutes');
const newsRoutes = require('./newsRoutes');
const forumRoutes = require('./forumRoutes');
const knowledgeHubRoutes = require('./knowledgeHubRoutes');
const profitPlannerRoutes = require('./profitPlannerRoutes');
const shopRoutes = require('./shopRoutes');
const safetyRoutes = require('./safetyRoutes');
const notificationRoutes = require('./notificationRoutes');

// API version prefix
const API_PREFIX = '/api/v1';

// Health check route
router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Govi Sahaya API is running',
    timestamp: new Date().toISOString(),
  });
});

console.log('📋 Registering routes...');

// Mount routes
router.use(`${API_PREFIX}/auth`, authRoutes);
console.log('✅ Auth routes: /api/v1/auth');

router.use(`${API_PREFIX}/users`, userRoutes);
console.log('✅ User routes: /api/v1/users');

router.use(`${API_PREFIX}/crop-doctor`, cropDoctorRoutes);
console.log('✅ Crop Doctor routes: /api/v1/crop-doctor');

router.use(`${API_PREFIX}/ml`, mlRoutes);
console.log('✅ ML routes: /api/v1/ml');

router.use(`${API_PREFIX}/weather`, weatherRoutes);
console.log('✅ Weather routes: /api/v1/weather');

router.use(`${API_PREFIX}/news`, newsRoutes);
console.log('✅ News routes: /api/v1/news');

router.use(`${API_PREFIX}/forum`, forumRoutes);
console.log('✅ Forum routes: /api/v1/forum');

router.use(`${API_PREFIX}/knowledge`, knowledgeHubRoutes);
console.log('✅ Knowledge Hub routes: /api/v1/knowledge');

router.use(`${API_PREFIX}/planner`, profitPlannerRoutes); // ✅ Changed to /planner
console.log('✅ Profit Planner routes: /api/v1/planner');

router.use(`${API_PREFIX}/shop`, shopRoutes);
console.log('✅ Shop routes: /api/v1/shop');

router.use(`${API_PREFIX}/safety`, safetyRoutes);
console.log('✅ Safety routes: /api/v1/safety');

router.use(`${API_PREFIX}/notifications`, notificationRoutes);
console.log('✅ Notification routes: /api/v1/notifications');

// Add inline crop routes
router.get(`${API_PREFIX}/crops`, async (req, res) => {
  try {
    const Crop = require('../models/Crop');
    const crops = await Crop.find().select('-__v');
    res.status(200).json({
      success: true,
      count: crops.length,
      data: crops,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching crops',
      error: error.message,
    });
  }
});

// Add inline disease routes
router.get(`${API_PREFIX}/diseases`, async (req, res) => {
  try {
    const Disease = require('../models/Disease');
    const diseases = await Disease.find().select('-__v');
    res.status(200).json({
      success: true,
      count: diseases.length,
      data: diseases,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching diseases',
      error: error.message,
    });
  }
});

// 404 handler for undefined routes
router.use('*', (req, res) => {
  console.log('❌ 404 - Route not found:', req.method, req.originalUrl);
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.originalUrl,
    method: req.method,
  });
});

module.exports = router;
