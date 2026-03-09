const express = require('express');
const router  = express.Router();

const {
  detectDisease, getHistory, getDetectionById,
  submitFeedback, deleteDetection, getStatistics,
} = require('../controllers/cropDoctorController');

const { protect } = require('../middleware/authMiddleware');
const { uploadToMemory } = require('../middleware/uploadMiddleware'); // ✅ CHANGED

router.use(protect);

router.post('/detect',      uploadToMemory('image'), detectDisease); // ✅ FIXED
router.get('/history',      getHistory);
router.get('/stats',        getStatistics);
router.get('/:id',          getDetectionById);
router.put('/:id/feedback', submitFeedback);
router.delete('/:id',       deleteDetection);

module.exports = router;
