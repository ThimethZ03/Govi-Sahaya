const express = require('express');
const router = express.Router();
const {
  getAllNews,
  getNewsById,
  getFeaturedNews,
  getLatestNews,
  syncExternalNews,
  syncEsanaNews,
  syncEsanaNewsAll, // ✅ NEW
  getAgricultureStats,
  createNews,
  updateNews,
  deleteNews,
  likeNews,
  shareNews,
} = require('../controllers/newsController');
const { protect, authorize } = require('../middleware/authMiddleware');

// Public routes
router.get('/', getAllNews);
router.get('/featured', getFeaturedNews);
router.get('/latest', getLatestNews);
router.get('/stats/agriculture', getAgricultureStats);
router.get('/:id', getNewsById);

// Protected routes
router.post('/:id/like', protect, likeNews);
router.post('/:id/share', protect, shareNews);

// Admin only routes
router.post('/sync', protect, authorize('admin'), syncExternalNews);
router.post('/sync/esana', protect, authorize('admin'), syncEsanaNews);
router.post('/sync/esana/all', protect, authorize('admin'), syncEsanaNewsAll); // ✅ NEW
router.post('/', protect, authorize('admin'), createNews);
router.put('/:id', protect, authorize('admin'), updateNews);
router.delete('/:id', protect, authorize('admin'), deleteNews);

module.exports = router;
