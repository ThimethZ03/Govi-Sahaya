const express = require('express');
const router = express.Router();

const {
  detectDisease,
  getHistory,
  getDetectionById,
  submitFeedback,
  deleteDetection,
  getStatistics,
} = require('../controllers/cropDoctorController');

const { protect } = require('../middleware/authMiddleware');

// ✅ CHANGED: use crop uploader (saves to /uploads/crop_images)
const { uploadCropImage } = require('../middleware/uploadMiddleware');

// All routes are protected
router.use(protect);

// Detection routes
router.post('/detect', uploadCropImage('image'), detectDisease);
router.get('/history', getHistory);
router.get('/stats', getStatistics);
router.get('/:id', getDetectionById);
router.put('/:id/feedback', submitFeedback);
router.delete('/:id', deleteDetection);

module.exports = router;