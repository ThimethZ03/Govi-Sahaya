// controllers/cropDoctorController.js
// ✅ FULL FIXED (NO Firebase) + diskStorage compatible + saves history correctly
//
// Key fixes:
// 1) Works with multer diskStorage (uses req.file.path)
// 2) Uses path-based mlService.detectDisease(imagePath)
// 3) ALWAYS saves CropDoctor record so "Recent Diagnoses" works
// 4) Normalizes severity enum: low/moderate/high/critical (NO "High")
// 5) Uses local image URL (/uploads/...) so image.url validation passes
// 6) Supports ML outputs: object, array, {predictions:[]}
// 7) Saves full predictions array when available

const fs = require('fs');
const path = require('path');

const CropDoctor = require('../models/CropDoctor');
const Disease = require('../models/Disease');
const mlService = require('../services/mlService');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// --------------------------
// Helpers
// --------------------------
function safeStr(v, fallback = '') {
  if (v === null || v === undefined) return fallback;
  const s = String(v).trim();
  return s.length ? s : fallback;
}

function safeNum(v, fallback = 0) {
  if (v === null || v === undefined) return fallback;
  if (typeof v === 'number') return v;
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

// ✅ Convert anything -> one of: low|moderate|high|critical
function normalizeSeverity(input) {
  const s = String(input || '').toLowerCase().trim();

  // exact allowed values
  if (['low', 'moderate', 'high', 'critical'].includes(s)) return s;

  // common variants
  if (s === 'medium') return 'moderate';
  if (s === 'med') return 'moderate';

  // if ML sends "High" / "LOW" etc. (case already lowered)
  if (s === 'high') return 'high';
  if (s === 'low') return 'low';

  // fallback
  return 'moderate';
}

// Normalize ML response into array of predictions (best first)
function normalizePredictions(mlResult) {
  if (!mlResult) return [];

  if (Array.isArray(mlResult)) return mlResult;

  if (mlResult.predictions && Array.isArray(mlResult.predictions)) {
    return mlResult.predictions;
  }

  return [mlResult];
}

function extractDiseaseName(pred) {
  return (
    safeStr(pred?.disease_name) ||
    safeStr(pred?.disease) ||
    safeStr(pred?.name) ||
    safeStr(pred?.diseaseName) ||
    'Unknown'
  );
}

function extractCropName(pred) {
  // optional - depends on your ML response
  return (
    safeStr(pred?.crop_name) ||
    safeStr(pred?.cropName) ||
    safeStr(pred?.crop) ||
    ''
  );
}

function extractConfidence(pred) {
  return safeNum(pred?.confidence, 0);
}

function extractSeverity(pred) {
  // ML may send risk_level (High/Medium/Low) or severity
  return normalizeSeverity(pred?.severity || pred?.risk_level || 'moderate');
}

// ✅ Build a public URL for the uploaded file (for DB image.url)
// IMPORTANT: You must serve "/uploads" statically in server.js/app.js
function buildLocalImageUrl(reqFile) {
  // Example req.file.path:
  // C:\...\govi_sahaya_backend\uploads\crop_images\123_name.jpg
  // We return:
  // /uploads/crop_images/123_name.jpg

  const fullPath = safeStr(reqFile?.path);
  const normalized = fullPath.replace(/\\/g, '/');
  const idx = normalized.lastIndexOf('/uploads/');
  if (idx === -1) return '';

  return normalized.substring(idx); // "/uploads/...."
}

// --------------------------
// @desc    Upload and detect crop disease
// @route   POST /api/v1/crop-doctor/detect
// @access  Private
// --------------------------
exports.detectDisease = async (req, res) => {
  const startTime = Date.now();

  try {
    if (!req.file) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Please upload an image',
      });
    }

    const { cropType, location, notes } = req.body;

    // ✅ diskStorage gives file path
    const imagePath = req.file.path;

    if (!imagePath || !fs.existsSync(imagePath)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Uploaded image file not found on server',
      });
    }

    logger.info(`🧑‍⚕️ CropDoctor detect: ${req.file.originalname} -> ${imagePath}`);

    // ✅ Local URL to satisfy schema validation: image.url required
    const imageUrl = buildLocalImageUrl(req.file);
    if (!imageUrl) {
      // If this happens, your multer destination is not inside /uploads
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message:
          'Upload path must be inside /uploads to build image URL. Please check uploadMiddleware destination.',
      });
    }

    // --------------------------
    // 1) Run ML detection (path-based)
    // --------------------------
    const mlResult = await mlService.detectDisease(imagePath);
    const predictions = normalizePredictions(mlResult);

    // If ML returned nothing, still save record with status failed
    if (!predictions || predictions.length === 0) {
      const cropDoctorFailed = await CropDoctor.create({
        user: req.user.id,
        image: {
          url: imageUrl,           // ✅ required
          path: imagePath,         // file system path
          size: req.file.size,
          mimeType: req.file.mimetype,
        },
        predictions: [],
        topPrediction: null,
        cropType: cropType || '',
        location: location || '',
        notes: notes || '',
        processingTime: Date.now() - startTime,
        status: 'failed',
      });

      return res.status(HTTP_STATUS.CREATED).json({
        success: true,
        message: 'No predictions returned from ML',
        data: cropDoctorFailed,
      });
    }

    // --------------------------
    // 2) Build top prediction + DB link
    // --------------------------
    const top = predictions[0];

    const topDiseaseName = extractDiseaseName(top);
    const topConfidence = extractConfidence(top);
    const topSeverity = extractSeverity(top);

    // Optional DB lookup (case-insensitive exact)
    const diseaseDoc = await Disease.findOne({
      name: new RegExp(`^${topDiseaseName}$`, 'i'),
      isActive: true,
    });

    const finalTopSeverity = normalizeSeverity(diseaseDoc?.severity || topSeverity);

    const topPrediction = {
      disease: diseaseDoc?._id,
      diseaseName: diseaseDoc?.name || topDiseaseName,
      confidence: topConfidence,
      severity: finalTopSeverity,
    };

    // --------------------------
    // 3) Save detection result in MongoDB (powers history)
    // --------------------------
    const saved = await CropDoctor.create({
      user: req.user.id,
      image: {
        url: imageUrl,      // ✅ required
        path: imagePath,    // disk path
        size: req.file.size,
        mimeType: req.file.mimetype,
      },

      predictions: predictions.map((p) => ({
        diseaseName: extractDiseaseName(p),
        confidence: extractConfidence(p),
        severity: extractSeverity(p), // ✅ normalized enum
      })),

      topPrediction,

      // metadata
      cropType: cropType || extractCropName(top) || '',
      location: location || '',
      notes: notes || '',
      processingTime: Date.now() - startTime,
      status: 'completed',
    });

    await saved.populate('topPrediction.disease');

    logger.info(`✅ CropDoctor saved: ${saved._id} in ${Date.now() - startTime}ms`);

    return res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Disease detection completed',
      data: saved,
    });
  } catch (error) {
    logger.error('Detect disease error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Disease detection failed',
      error: error.message,
    });
  } finally {
    // Optional cleanup: remove local file after saving (NOT recommended if you want to serve it later)
    // try { if (req.file?.path && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path); } catch (_) {}
  }
};

// --------------------------
// @desc    Get detection history
// @route   GET /api/v1/crop-doctor/history
// @access  Private
// --------------------------
exports.getHistory = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const skip = (page - 1) * limit;

    const query = { user: req.user.id };
    if (req.query.cropType) query.cropType = req.query.cropType;
    if (req.query.status) query.status = req.query.status;

    const detections = await CropDoctor.find(query)
      .populate('topPrediction.disease')
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip);

    const total = await CropDoctor.countDocuments(query);

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: detections,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get history error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch detection history',
    });
  }
};

// --------------------------
// @desc    Get detection by ID
// @route   GET /api/v1/crop-doctor/:id
// @access  Private
// --------------------------
exports.getDetectionById = async (req, res) => {
  try {
    const detection = await CropDoctor.findById(req.params.id).populate(
      'topPrediction.disease'
    );

    if (!detection) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Detection not found',
      });
    }

    if (detection.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to access this detection',
      });
    }

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: detection,
    });
  } catch (error) {
    logger.error('Get detection by ID error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch detection',
    });
  }
};

// --------------------------
// @desc    Submit feedback for detection
// @route   PUT /api/v1/crop-doctor/:id/feedback
// @access  Private
// --------------------------
exports.submitFeedback = async (req, res) => {
  try {
    const { isAccurate, actualDisease, comments, rating } = req.body;

    const detection = await CropDoctor.findById(req.params.id);

    if (!detection) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Detection not found',
      });
    }

    if (detection.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this detection',
      });
    }

    detection.userFeedback = { isAccurate, actualDisease, comments, rating };
    await detection.save();

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Feedback submitted successfully',
      data: detection,
    });
  } catch (error) {
    logger.error('Submit feedback error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to submit feedback',
    });
  }
};

// --------------------------
// @desc    Delete detection
// @route   DELETE /api/v1/crop-doctor/:id
// @access  Private
// --------------------------
exports.deleteDetection = async (req, res) => {
  try {
    const detection = await CropDoctor.findById(req.params.id);

    if (!detection) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Detection not found',
      });
    }

    if (detection.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to delete this detection',
      });
    }

    await detection.deleteOne();

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Detection deleted successfully',
    });
  } catch (error) {
    logger.error('Delete detection error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete detection',
    });
  }
};

// --------------------------
// @desc    Get detection statistics
// @route   GET /api/v1/crop-doctor/stats
// @access  Private
// --------------------------
exports.getStatistics = async (req, res) => {
  try {
    const userId = req.user.id;

    const totalDetections = await CropDoctor.countDocuments({ user: userId });

    const byCrop = await CropDoctor.aggregate([
      { $match: { user: userId } },
      { $group: { _id: '$cropType', count: { $sum: 1 } } },
    ]);

    const bySeverity = await CropDoctor.aggregate([
      { $match: { user: userId } },
      { $group: { _id: '$topPrediction.severity', count: { $sum: 1 } } },
    ]);

    const recentDetections = await CropDoctor.find({ user: userId })
      .populate('topPrediction.disease')
      .sort({ createdAt: -1 })
      .limit(5);

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: {
        totalDetections,
        byCrop,
        bySeverity,
        recentDetections,
      },
    });
  } catch (error) {
    logger.error('Get statistics error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch statistics',
    });
  }
};