const express = require('express');
const router = express.Router();
const User = require('../models/User');
const {
  submitReport,
  updateSettings,
  updateLanguage,
  getLanguage,
  submitRating,
} = require('../controllers/supportController');
const { protect } = require('../middleware/authMiddleware');

// ── Support / Feedback ─────────────────────────────────────────────────
router.post('/report',  protect, submitReport);
router.post('/rating',  protect, submitRating);

// ── Language ───────────────────────────────────────────────────────────
router.get('/language', protect, getLanguage);
router.put('/language', protect, updateLanguage);

// ── Settings — GET added to fix missing read-back on app start ─────────
router.get('/settings', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('settings');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    return res.status(200).json({
      success: true,
      data: {
        pushNotifications:  user.settings?.pushNotifications  ?? true,
        emailNotifications: user.settings?.emailNotifications ?? false,
        locationAccess:     user.settings?.locationAccess     ?? true,
        dataSync:           user.settings?.dataSync           ?? true,
        language:           user.settings?.language           ?? 'en',
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

router.put('/settings', protect, updateSettings);

module.exports = router;
