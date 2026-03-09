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
const { uploadSingle } = require('../middleware/uploadMiddleware');

// ── Public routes ─────────────────────────────────────────────────

// GET /api/v1/knowledge/guides
router.get('/guides', getAllGuides);

// GET /api/v1/knowledge/guides/featured
router.get('/guides/featured', getFeaturedGuides);

// GET /api/v1/knowledge/guides/popular
router.get('/guides/popular', getPopularGuides);

// GET /api/v1/knowledge/guides/slug/:slug
router.get('/guides/slug/:slug', getGuideBySlug);

// GET /api/v1/knowledge/guides/:id
router.get('/guides/:id', getGuideById);

// GET /api/v1/knowledge/categories
router.get('/categories', getCategories);

// GET /api/v1/knowledge/categories/:category
router.get('/categories/:category', getGuidesByCategory);

// ── Protected routes ─────────────────────────────────────────────

// POST /api/v1/knowledge/guides/:id/like
router.post('/guides/:id/like', protect, likeGuide);

// ── Expert/Admin routes ──────────────────────────────────────────

// POST /api/v1/knowledge/guides
router.post(
  '/guides',
  protect,
  authorize('expert', 'admin'),
  uploadSingle('coverImage'),
  createGuide
);

// PUT /api/v1/knowledge/guides/:id
router.put(
  '/guides/:id',
  protect,
  authorize('expert', 'admin'),
  uploadSingle('coverImage'),
  updateGuide
);

// DELETE /api/v1/knowledge/guides/:id
router.delete(
  '/guides/:id',
  protect,
  authorize('expert', 'admin'),
  deleteGuide
);

module.exports = router;
