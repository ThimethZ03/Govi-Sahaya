const express = require('express');
const router = express.Router();
const {
  submitReport,
  updateSettings,
  updateLanguage,
  getLanguage,       // ✅ ADD — import the new controller function
  submitRating,
} = require('../controllers/supportController');
const { protect } = require('../middleware/authMiddleware');

router.post('/report',    protect, submitReport);
router.put('/settings',   protect, updateSettings);
router.get('/language',   protect, getLanguage);   // ✅ ADD — was missing, caused 404
router.put('/language',   protect, updateLanguage);
router.post('/rating',    protect, submitRating);

module.exports = router;
