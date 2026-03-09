// src/controllers/cropDoctorController.js

const fs   = require('fs');
const os   = require('os');
const path = require('path');

const CropDoctor = require('../models/CropDoctor');
const Disease    = require('../models/Disease');
const mlService  = require('../services/mlService');
const logger     = require('../utils/logger');
const { uploadBuffer, deleteImage } = require('../utils/cloudinary');
const { HTTP_STATUS } = require('../config/constants');

// ── Helpers ────────────────────────────────────────────────────────────
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

function normalizeSeverity(input) {
  const s = String(input || '').toLowerCase().trim();
  if (['low', 'moderate', 'high', 'critical'].includes(s)) return s;
  if (s === 'medium' || s === 'med') return 'moderate';
  return 'moderate';
}

function normalizePredictions(mlResult) {
  if (!mlResult) return [];
  if (Array.isArray(mlResult)) return mlResult;
  if (mlResult.predictions && Array.isArray(mlResult.predictions)) return mlResult.predictions;
  return [mlResult];
}

function extractDiseaseName(pred) {
  return safeStr(pred?.disease_name) || safeStr(pred?.disease) ||
         safeStr(pred?.name)         || safeStr(pred?.diseaseName) || 'Unknown';
}

function extractCropName(pred) {
  return safeStr(pred?.crop_name) || safeStr(pred?.cropName) || safeStr(pred?.crop) || '';
}

function extractConfidence(pred) { return safeNum(pred?.confidence, 0); }

function extractSeverity(pred) {
  return normalizeSeverity(pred?.severity || pred?.risk_level || 'moderate');
}

// ── POST /api/v1/crop-doctor/detect ───────────────────────────────────
exports.detectDisease = async (req, res) => {
  const startTime = Date.now();
  let tmpPath = null;

  try {
    if (!req.file || !req.file.buffer || req.file.buffer.length === 0) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Please upload an image',
      });
    }

    const { cropType, location, notes } = req.body;
    logger.info(`🧑‍⚕️ CropDoctor detect: ${req.file.originalname}`);

    // ── 1. Write temp file and run ML ────────────────────────────────
    const ext = (req.file.originalname.split('.').pop() || 'jpg').toLowerCase();
    tmpPath   = path.join(os.tmpdir(), `crop_${Date.now()}.${ext}`);
    fs.writeFileSync(tmpPath, req.file.buffer);

    let mlResult;
    try {
      mlResult = await mlService.detectDisease(tmpPath);
    } finally {
      try { fs.unlinkSync(tmpPath); tmpPath = null; } catch (_) {}
    }

    const predictions    = normalizePredictions(mlResult);
    const top            = predictions[0] || null;
    const topDiseaseName = top ? extractDiseaseName(top) : 'Unknown';
    const topConfidence  = top ? extractConfidence(top)  : 0;
    const topSeverity    = top ? extractSeverity(top)    : 'moderate';

    const diseaseDoc = top
      ? await Disease.findOne({
          name:     new RegExp(`^${topDiseaseName}$`, 'i'),
          isActive: true,
        })
      : null;

    const topPrediction = top
      ? {
          disease:     diseaseDoc?._id,
          diseaseName: diseaseDoc?.name || topDiseaseName,
          confidence:  topConfidence,
          severity:    normalizeSeverity(diseaseDoc?.severity || topSeverity),
        }
      : null;

    // ── 2. Save to DB — image.url filled in background ───────────────
    // ✅ Works now — image.url no longer required in schema
    const saved = await CropDoctor.create({
      user:  req.user.id,
      image: {
        url:      '', // ✅ filled by background Cloudinary upload below
        publicId: '',
        size:     req.file.size,
        mimeType: req.file.mimetype,
      },
      predictions: predictions.map((p) => ({
        diseaseName: extractDiseaseName(p),
        confidence:  extractConfidence(p),
        severity:    extractSeverity(p),
      })),
      topPrediction,
      cropType:       cropType || extractCropName(top) || '',
      location:       location || '',
      notes:          notes    || '',
      processingTime: Date.now() - startTime,
      status:         predictions.length > 0 ? 'completed' : 'failed',
    });

    await saved.populate('topPrediction.disease');
    logger.info(`✅ CropDoctor saved: ${saved._id.toString()} in ${Date.now() - startTime}ms`);

    // ── 3. Respond to Flutter immediately ────────────────────────────
    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Disease detection completed',
      data:    saved,
    });

    // ── 4. Upload to Cloudinary in background (non-blocking) ─────────
    const fileBuffer = req.file.buffer;
    const fileName   = req.file.originalname;
    const savedDocId = saved._id;

    setImmediate(async () => {
      try {
        const uploadResult  = await uploadBuffer(
          fileBuffer,
          fileName,
          'govi_sahaya/crop_doctor', // ✅ correct folder
        );
        const imageUrl      = uploadResult?.secure_url || '';
        const imagePublicId = uploadResult?.public_id  || '';

        await CropDoctor.findByIdAndUpdate(savedDocId, {
          'image.url':      imageUrl,
          'image.publicId': imagePublicId,
        });
        logger.info(`🖼️ Background upload done for ${savedDocId}: ${imageUrl}`);
      } catch (uploadErr) {
        logger.warn(`⚠️ Background Cloudinary upload failed: ${uploadErr.message}`);
      }
    });

  } catch (error) {
    if (tmpPath) { try { fs.unlinkSync(tmpPath); } catch (_) {} }
    logger.error('Detect disease error:', error);
    if (!res.headersSent) {
      return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
        success: false,
        message: 'Disease detection failed',
        error:   error.message,
      });
    }
  }
};

// ── GET /api/v1/crop-doctor/history ───────────────────────────────────
exports.getHistory = async (req, res) => {
  try {
    const page  = parseInt(req.query.page,  10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const skip  = (page - 1) * limit;

    const query = { user: req.user.id };
    if (req.query.cropType) query.cropType = req.query.cropType;
    if (req.query.status)   query.status   = req.query.status;

    const detections = await CropDoctor.find(query)
      .populate('topPrediction.disease')
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip);

    const total = await CropDoctor.countDocuments(query);

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: detections,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    logger.error('Get history error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch detection history',
    });
  }
};

// ── GET /api/v1/crop-doctor/:id ────────────────────────────────────────
exports.getDetectionById = async (req, res) => {
  try {
    const detection = await CropDoctor.findById(req.params.id)
      .populate('topPrediction.disease');

    if (!detection) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false, message: 'Detection not found',
      });
    }

    if (detection.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false, message: 'Not authorized',
      });
    }

    return res.status(HTTP_STATUS.OK).json({ success: true, data: detection });
  } catch (error) {
    logger.error('Get detection by ID error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to fetch detection',
    });
  }
};

// ── PUT /api/v1/crop-doctor/:id/feedback ──────────────────────────────
exports.submitFeedback = async (req, res) => {
  try {
    const { isAccurate, actualDisease, comments, rating } = req.body;
    const detection = await CropDoctor.findById(req.params.id);

    if (!detection) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false, message: 'Detection not found',
      });
    }

    if (detection.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false, message: 'Not authorized',
      });
    }

    detection.userFeedback = { isAccurate, actualDisease, comments, rating };
    await detection.save();

    return res.status(HTTP_STATUS.OK).json({
      success: true, message: 'Feedback submitted', data: detection,
    });
  } catch (error) {
    logger.error('Submit feedback error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to submit feedback',
    });
  }
};

// ── DELETE /api/v1/crop-doctor/:id ────────────────────────────────────
exports.deleteDetection = async (req, res) => {
  try {
    const detection = await CropDoctor.findById(req.params.id);

    if (!detection) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false, message: 'Detection not found',
      });
    }

    if (detection.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false, message: 'Not authorized',
      });
    }

    // ✅ Delete from Cloudinary if image was uploaded
    if (detection.image?.publicId) {
      await deleteImage(detection.image.publicId);
    }

    await detection.deleteOne();

    return res.status(HTTP_STATUS.OK).json({
      success: true, message: 'Detection deleted successfully',
    });
  } catch (error) {
    logger.error('Delete detection error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to delete detection',
    });
  }
};

// ── GET /api/v1/crop-doctor/stats ─────────────────────────────────────
exports.getStatistics = async (req, res) => {
  try {
    const userId = req.user.id;

    const [totalDetections, byCrop, bySeverity, recentDetections] =
      await Promise.all([
        CropDoctor.countDocuments({ user: userId }),
        CropDoctor.aggregate([
          { $match: { user: userId } },
          { $group: { _id: '$cropType', count: { $sum: 1 } } },
        ]),
        CropDoctor.aggregate([
          { $match: { user: userId } },
          { $group: { _id: '$topPrediction.severity', count: { $sum: 1 } } },
        ]),
        CropDoctor.find({ user: userId })
          .populate('topPrediction.disease')
          .sort({ createdAt: -1 })
          .limit(5),
      ]);

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: { totalDetections, byCrop, bySeverity, recentDetections },
    });
  } catch (error) {
    logger.error('Get statistics error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false, message: 'Failed to fetch statistics',
    });
  }
};
