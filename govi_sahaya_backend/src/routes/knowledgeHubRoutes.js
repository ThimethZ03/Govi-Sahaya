const express = require('express');
const router = express.Router();
const {
  getAllGuides,
  getGuideById,
  getGuideBySlug,
  createGuide,
  updateGuide,
  deleteGuide,
  likeGuide,
  getGuidesByCategory,
  getFeaturedGuides,
  getPopularGuides,
  getCategories,
} = require('../controllers/knowledgeHubController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { uploadSingle } = require('../middleware/uploadMiddleware'); // ✅ Correct

// Public routes
router.get('/guides', getAllGuides);
router.get('/guides/featured', getFeaturedGuides);
router.get('/guides/popular', getPopularGuides);
router.get('/guides/slug/:slug', getGuideBySlug);
router.get('/guides/:id', getGuideById);
router.get('/categories', getCategories);
router.get('/categories/:category', getGuidesByCategory);

// Protected routes
router.post('/guides/:id/like', protect, likeGuide);

// Expert/Admin only routes
router.post(
  '/guides',
  protect,
  authorize('expert', 'admin'),
  uploadSingle('coverImage'),
  createGuide
);
router.put(
  '/guides/:id',
  protect,
  authorize('expert', 'admin'),
  uploadSingle('coverImage'),
  updateGuide
);
router.delete('/guides/:id', protect, authorize('expert', 'admin'), deleteGuide);

module.exports = router;

