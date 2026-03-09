const User = require('../models/User');
const logger = require('../utils/logger');

// ── GET /api/v1/support/language ───────────────────────────────────────────
const getLanguage = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('settings');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    logger.info(`Language fetched for user: ${req.user.id}`);

    return res.status(200).json({
      success: true,
      data: {
        language: user.settings?.language || 'en',
      },
    });
  } catch (error) {
    logger.error('getLanguage error:', error);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── POST /api/v1/support/report ────────────────────────────────────────────
const submitReport = async (req, res) => {
  try {
    const { category, description } = req.body;

    if (!category || !description?.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Category and description are required',
      });
    }

    logger.info(`Problem report from user ${req.user?.id}: [${category}] ${description}`);

    return res.status(200).json({
      success: true,
      message: 'Report submitted successfully. We will review it shortly.',
    });
  } catch (error) {
    logger.error('submitReport error:', error);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── PUT /api/v1/support/settings ───────────────────────────────────────────
const updateSettings = async (req, res) => {
  try {
    const {
      pushNotifications,
      emailNotifications,
      locationAccess,
      dataSync,
    } = req.body;

    const updates = {};
    if (pushNotifications  !== undefined) updates['settings.pushNotifications']  = pushNotifications;
    if (emailNotifications !== undefined) updates['settings.emailNotifications'] = emailNotifications;
    if (locationAccess     !== undefined) updates['settings.locationAccess']     = locationAccess;
    if (dataSync           !== undefined) updates['settings.dataSync']           = dataSync;

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: updates },
      { new: true, runValidators: true }
    ).select('settings');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    logger.info(`Settings updated for user: ${req.user.id}`);

    return res.status(200).json({
      success: true,
      message: 'Settings saved',
      data: {
        pushNotifications:  user.settings.pushNotifications,
        emailNotifications: user.settings.emailNotifications,
        locationAccess:     user.settings.locationAccess,
        dataSync:           user.settings.dataSync,
        language:           user.settings.language,
      },
    });
  } catch (error) {
    logger.error('updateSettings error:', error);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── PUT /api/v1/support/language ───────────────────────────────────────────
const updateLanguage = async (req, res) => {
  try {
    const { language } = req.body;
    const allowed = ['en', 'si', 'ta'];

    if (!language || !allowed.includes(language)) {
      return res.status(400).json({
        success: false,
        message: `Invalid language. Allowed: ${allowed.join(', ')}`,
      });
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: { 'settings.language': language } },
      { new: true }
    ).select('settings');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    logger.info(`Language set to '${language}' for user: ${req.user.id}`);

    return res.status(200).json({
      success: true,
      message: 'Language updated',
      data: { language: user.settings.language },
    });
  } catch (error) {
    logger.error('updateLanguage error:', error);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── POST /api/v1/support/rating ────────────────────────────────────────────
const submitRating = async (req, res) => {
  try {
    const { rating, feedback } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5',
      });
    }

    logger.info(`Rating from user ${req.user?.id}: ${rating}/5 — "${feedback ?? 'no feedback'}"`);

    return res.status(200).json({
      success: true,
      message: 'Rating submitted. Thank you!',
      data: { rating, feedback: feedback ?? '' },
    });
  } catch (error) {
    logger.error('submitRating error:', error);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ✅ getLanguage added to exports
module.exports = { getLanguage, submitReport, updateSettings, updateLanguage, submitRating };
