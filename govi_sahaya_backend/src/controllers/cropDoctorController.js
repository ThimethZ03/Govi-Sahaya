const CropDoctor = require('../models/CropDoctor');
const Disease = require('../models/Disease');
const { uploadToStorage } = require('../config/firebase');
const { detectDisease } = require('../services/mlService');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// @desc    Upload and detect crop disease
// @route   POST /api/crop-doctor/detect
// @access  Private
exports.detectDisease = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Please upload an image',
      });
    }

    const { cropType, location, notes } = req.body;
    const startTime = Date.now();

    // Upload image to Firebase Storage
    const destination = `crop_images/${Date.now()}_${req.file.originalname}`;
    const imageUrl = await uploadToStorage(req.file, destination);

    // Detect disease using ML model
    const predictions = await detectDisease(req.file.buffer);

    // Get disease details for top prediction
    let topPrediction = null;
    if (predictions && predictions.length > 0) {
      const diseaseDoc = await Disease.findOne({ name: predictions[0].diseaseName });
      topPrediction = {
        disease: diseaseDoc?._id,
        diseaseName: predictions[0].diseaseName,
        confidence: predictions[0].confidence,
        severity: diseaseDoc?.severity || 'moderate',
      };
    }

    // Save detection result
    const cropDoctor = await CropDoctor.create({
      user: req.user.id,
      image: {
        url: imageUrl,
        path: destination,
        size: req.file.size,
        mimeType: req.file.mimetype,
      },
      predictions: predictions.map((pred) => ({
        diseaseName: pred.diseaseName,
        confidence: pred.confidence,
        severity: pred.severity,
      })),
      topPrediction,
      cropType,
      location,
      notes,
      processingTime: Date.now() - startTime,
      status: 'completed',
    });

    // Populate disease details
    await cropDoctor.populate('topPrediction.disease');

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Disease detection completed',
      data: cropDoctor,
    });
  } catch (error) {
    logger.error('Detect disease error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Disease detection failed',
      error: error.message,
    });
  }
};

// @desc    Get detection history
// @route   GET /api/crop-doctor/history
// @access  Private
exports.getHistory = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = { user: req.user.id };

    if (req.query.cropType) {
      query.cropType = req.query.cropType;
    }

    if (req.query.status) {
      query.status = req.query.status;
    }

    const detections = await CropDoctor.find(query)
      .populate('topPrediction.disease')
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip);

    const total = await CropDoctor.countDocuments(query);

    res.status(HTTP_STATUS.OK).json({
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
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch detection history',
    });
  }
};

// @desc    Get detection by ID
// @route   GET /api/crop-doctor/:id
// @access  Private
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

    // Check if user owns this detection
    if (detection.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to access this detection',
      });
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: detection,
    });
  } catch (error) {
    logger.error('Get detection by ID error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch detection',
    });
  }
};

// @desc    Submit feedback for detection
// @route   PUT /api/crop-doctor/:id/feedback
// @access  Private
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

    // Check if user owns this detection
    if (detection.user.toString() !== req.user.id) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this detection',
      });
    }

    // Update feedback
    detection.userFeedback = {
      isAccurate,
      actualDisease,
      comments,
      rating,
    };

    await detection.save();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Feedback submitted successfully',
      data: detection,
    });
  } catch (error) {
    logger.error('Submit feedback error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to submit feedback',
    });
  }
};

// @desc    Delete detection
// @route   DELETE /api/crop-doctor/:id
// @access  Private
exports.deleteDetection = async (req, res) => {
  try {
    const detection = await CropDoctor.findById(req.params.id);

    if (!detection) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Detection not found',
      });
    }

    // Check if user owns this detection
    if (detection.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to delete this detection',
      });
    }

    await detection.deleteOne();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Detection deleted successfully',
    });
  } catch (error) {
    logger.error('Delete detection error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete detection',
    });
  }
};

// @desc    Get detection statistics
// @route   GET /api/crop-doctor/stats
// @access  Private
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

    res.status(HTTP_STATUS.OK).json({
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
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch statistics',
    });
  }
};
