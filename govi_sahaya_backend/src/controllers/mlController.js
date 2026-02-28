// controllers/mlController.js

const Disease = require('../models/Disease');
const logger = require('../utils/logger');
const { HTTP_STATUS, DISEASE_CATEGORIES } = require('../config/constants');
const mlService = require('../services/mlService');
const fs = require('fs');
const path = require('path');

// ------------------------------
// Load disease info JSON (cached)
// ------------------------------
let DISEASE_INFO_CACHE = null;

function loadDiseaseInfoJson() {
  if (DISEASE_INFO_CACHE) return DISEASE_INFO_CACHE;

  // ✅ Your path (as you gave)
  const filePath = path.join(__dirname, '..', 'ml', 'models', 'onion_disease_info.json');

  try {
    const raw = fs.readFileSync(filePath, 'utf-8');
    DISEASE_INFO_CACHE = JSON.parse(raw);
    logger.info(`✅ Disease info JSON loaded: ${filePath}`);
    return DISEASE_INFO_CACHE;
  } catch (e) {
    logger.warn(`⚠️ Could not load disease info JSON: ${filePath}`);
    logger.warn(`⚠️ Reason: ${e.message}`);
    DISEASE_INFO_CACHE = {};
    return DISEASE_INFO_CACHE;
  }
}

// ===============================
// Helpers
// ===============================
function formatDiseaseName(cls) {
  if (!cls) return '';
  const parts = String(cls).split('___');
  const diseasePart = parts.length > 1 ? parts.slice(1).join('___') : String(cls);
  return diseasePart.replace(/_/g, ' ').trim();
}

function formatCropName(cls) {
  if (!cls) return '';
  const parts = String(cls).split('___');
  return (parts[0] || '').replace(/_/g, ' ').trim();
}

function riskLevelFromConfidence(conf) {
  const c = Number(conf || 0);
  if (c >= 0.9) return 'High';
  if (c >= 0.7) return 'Medium';
  return 'Low';
}

async function findDiseaseFromDB(diseaseNameReadable) {
  if (!diseaseNameReadable) return null;

  let disease = await Disease.findOne({
    name: new RegExp(`^${diseaseNameReadable}$`, 'i'),
    isActive: true,
  });

  if (!disease) {
    disease = await Disease.findOne({
      name: new RegExp(diseaseNameReadable, 'i'),
      isActive: true,
    });
  }

  return disease;
}

/**
 * ✅ FIXED:
 * - Adds: prevention + recommendations (emoji list)
 * - Prefers JSON values (your onion_disease_info.json) when available
 * - Still falls back to ML API + DB if JSON missing
 */
function mapDiseaseToFlutterModel({
  dbDisease,
  predictedClass,
  confidence,
  readableName,
  extraInfo,
}) {
  // ✅ load your disease info map and pick by class key
  const diseaseInfoMap = loadDiseaseInfoJson();
  const jsonInfo = predictedClass && diseaseInfoMap[predictedClass] ? diseaseInfoMap[predictedClass] : null;

  // -----------------------------
  // 1) ML Response fields
  // -----------------------------
  const mlSymptoms = extraInfo?.symptoms || extraInfo?.info?.symptoms || '';
  const mlCause = extraInfo?.cause || extraInfo?.info?.cause || '';
  const mlSolution = extraInfo?.solution || extraInfo?.info?.solution || '';

  const mlOrganic = extraInfo?.organic_treatment || extraInfo?.info?.organic_treatment || '';
  const mlChemical = extraInfo?.chemical_treatment || extraInfo?.info?.chemical_treatment || '';

  const mlCropName =
    extraInfo?.crop_name ||
    extraInfo?.info?.crop_name ||
    extraInfo?.cropName ||
    formatCropName(predictedClass) ||
    '';

  // -----------------------------
  // 2) Prefer JSON -> ML -> fallback
  // -----------------------------
  const symptomsFinal = jsonInfo?.symptoms || mlSymptoms || 'Consult agricultural expert';
  const causeFinal = jsonInfo?.cause || mlCause || 'Consult agricultural expert';
  const solutionFinal = jsonInfo?.solution || mlSolution || 'Consult agricultural expert';
  const preventionFinal = jsonInfo?.prevention || extraInfo?.prevention || extraInfo?.info?.prevention || 'Follow best farming practices';

  const recommendationsFinal = Array.isArray(jsonInfo?.recommendations)
    ? jsonInfo.recommendations
    : [];

  // Disease / crop names (prefer DB, then JSON, then readable)
  const diseaseNameFinal =
    dbDisease?.name ||
    jsonInfo?.disease_name ||
    readableName ||
    'Unknown';

  const cropNameFinal =
    dbDisease?.cropName ||
    dbDisease?.crop_name ||
    jsonInfo?.crop_name ||
    mlCropName ||
    'Unknown';

  // Build a nice description if DB missing
  const descriptionFromML = [
    symptomsFinal ? `Symptoms: ${symptomsFinal}` : '',
    causeFinal ? `Cause: ${causeFinal}` : '',
  ].filter(Boolean).join('\n\n');

  // -----------------------------
  // 3) DB treatment (if exists)
  // -----------------------------
  const dbOrganic =
    (dbDisease?.treatment?.organic && Array.isArray(dbDisease.treatment.organic)
      ? dbDisease.treatment.organic.join('\n')
      : null) ||
    dbDisease?.organicTreatment ||
    dbDisease?.organic_treatment ||
    '';

  const dbChemical =
    (dbDisease?.treatment?.chemical && Array.isArray(dbDisease.treatment.chemical)
      ? dbDisease.treatment.chemical.join('\n')
      : null) ||
    dbDisease?.chemicalTreatment ||
    dbDisease?.chemical_treatment ||
    '';

  // -----------------------------
  // 4) Final fallback logic
  // -----------------------------
  const organicFinal = dbOrganic || mlOrganic || solutionFinal;
  const chemicalFinal = dbChemical || mlChemical || solutionFinal;

  return {
    // ✅ Flutter DiseaseModel keys
    id: dbDisease?._id?.toString() || predictedClass || 'unknown',
    name: diseaseNameFinal,
    name_sinhala: dbDisease?.nameSinhala || dbDisease?.name_sinhala || '',
    crop_name: cropNameFinal,

    // Flutter dialog uses description
    description:
      dbDisease?.description ||
      descriptionFromML ||
      'No description available',

    organic_treatment: organicFinal,
    chemical_treatment: chemicalFinal,
    image_url: dbDisease?.imageUrl || dbDisease?.image_url || '',
    confidence: Number(confidence || 0),
    risk_level:
      dbDisease?.severity ||
      dbDisease?.risk_level ||
      riskLevelFromConfidence(confidence),

    // ✅ Extra fields (so you can show emojis nicely in Flutter)
    class: predictedClass || '',
    symptoms: symptomsFinal,
    cause: causeFinal,
    solution: solutionFinal,
    prevention: preventionFinal,
    recommendations: recommendationsFinal,
  };
}

// ============================================
// ML PREDICTION CONTROLLERS
// ============================================

/**
 * @desc    Detect disease from uploaded image
 * @route   POST /api/v1/ml/detect-disease
 * @access  Private
 */
exports.detectDisease = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'No image file uploaded. Please upload an image.',
      });
    }

    logger.info(`🔍 ML detect-disease: ${req.file.originalname}`);

    const imagePath = req.file.path;

    const mlResult = await mlService.detectDisease(imagePath);

    // normalize top prediction
    let top = null;
    if (Array.isArray(mlResult)) top = mlResult[0];
    else if (mlResult?.predictions && Array.isArray(mlResult.predictions)) top = mlResult.predictions[0];
    else top = mlResult;

    const predictedClass = top?.class || top?.label || top?.id || '';
    const confidence = Number(top?.confidence ?? mlResult?.confidence ?? 0);

    const readableName =
      top?.disease_name ||
      top?.disease ||
      top?.name ||
      formatDiseaseName(predictedClass) ||
      'Unknown';

    const extraInfo = top || mlResult || {};

    const dbDisease = await findDiseaseFromDB(readableName);

    const flutterJson = mapDiseaseToFlutterModel({
      dbDisease,
      predictedClass,
      confidence,
      readableName,
      extraInfo,
    });

    logger.info(
      `✅ ML result: ${flutterJson.crop_name} - ${flutterJson.name} (${(flutterJson.confidence * 100).toFixed(2)}%)`
    );

    return res.status(HTTP_STATUS.OK).json(flutterJson);
  } catch (error) {
    logger.error('❌ Disease detection error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Disease detection failed',
      error: error.message,
    });
  }
};

/**
 * @desc    Batch detect diseases from multiple images
 * @route   POST /api/v1/ml/batch-detect
 * @access  Private
 */
exports.batchDetect = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'No image files uploaded',
      });
    }

    logger.info(`🔍 ML batch-detect: ${req.files.length} images`);

    const imagePaths = req.files.map((file) => file.path);

    const mlResults = await mlService.batchDetectDiseases(imagePaths);

    const results = [];

    for (let i = 0; i < mlResults.length; i++) {
      const r = mlResults[i];

      let top = null;
      if (Array.isArray(r)) top = r[0];
      else if (r?.predictions && Array.isArray(r.predictions)) top = r.predictions[0];
      else top = r;

      const predictedClass = top?.class || top?.label || top?.id || '';
      const confidence = Number(top?.confidence ?? r?.confidence ?? 0);

      const readableName =
        top?.disease_name ||
        top?.disease ||
        top?.name ||
        formatDiseaseName(predictedClass) ||
        'Unknown';

      const extraInfo = top || r || {};

      const dbDisease = await findDiseaseFromDB(readableName);

      results.push({
        filename: req.files[i]?.originalname || `image_${i + 1}`,
        ...mapDiseaseToFlutterModel({
          dbDisease,
          predictedClass,
          confidence,
          readableName,
          extraInfo,
        }),
      });
    }

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      totalImages: req.files.length,
      results,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('❌ Batch detection error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Batch detection failed',
      error: error.message,
    });
  }
};

// ============================================
// OTHER ML ROUTES
// ============================================
exports.getHealth = async (req, res) => {
  try {
    const health = await mlService.checkHealth();

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      ...health,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('❌ Health check error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: error.message,
    });
  }
};

exports.getModelInfo = async (req, res) => {
  try {
    const modelInfo = mlService.getModelInfo();

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      modelInfo,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('❌ Model info error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: error.message,
    });
  }
};

exports.reconnect = async (req, res) => {
  try {
    logger.info('🔄 Reconnecting to ML API...');
    const connected = await mlService.reconnect();

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      connected,
      message: connected ? '✅ Successfully connected to ML API' : '⚠️ Failed to connect to ML API',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('❌ Reconnect error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: error.message,
    });
  }
};

exports.testML = async (req, res) => {
  try {
    logger.info('🧪 Testing ML service...');

    const mockPredictions = await mlService.getMockPredictions();
    const modelInfo = mlService.getModelInfo();

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      message: '✅ ML Service test successful',
      mockPredictions,
      modelInfo,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('❌ ML test error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'ML service test failed',
      error: error.message,
    });
  }
};

// ============================================
// DISEASE DATABASE CONTROLLERS (UNCHANGED)
// ============================================

exports.getAllDiseases = async (req, res) => {
  try {
    const { category, severity, search } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = { isActive: true };

    if (category) query.category = category;
    if (severity) query.severity = severity;
    if (search) query.$text = { $search: search };

    const diseases = await Disease.find(query).limit(limit).skip(skip).sort({ name: 1 });
    const total = await Disease.countDocuments(query);

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: diseases,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get all diseases error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch diseases',
    });
  }
};

exports.getDiseaseById = async (req, res) => {
  try {
    const disease = await Disease.findById(req.params.id);

    if (!disease) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Disease not found',
      });
    }

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: disease,
    });
  } catch (error) {
    logger.error('Get disease by ID error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch disease',
    });
  }
};

exports.getDiseasesByCrop = async (req, res) => {
  try {
    const { cropType } = req.params;

    if (!Object.values(DISEASE_CATEGORIES).includes(cropType)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Invalid crop type',
      });
    }

    const diseases = await Disease.find({ category: cropType, isActive: true }).sort({ name: 1 });

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: diseases,
      count: diseases.length,
    });
  } catch (error) {
    logger.error('Get diseases by crop error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch diseases',
    });
  }
};

exports.searchDiseases = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Search query is required',
      });
    }

    const diseases = await Disease.find({ $text: { $search: q }, isActive: true }).limit(20);

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: diseases,
    });
  } catch (error) {
    logger.error('Search diseases error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Search failed',
    });
  }
};

exports.getCategories = async (req, res) => {
  try {
    const categories = await Disease.aggregate([
      { $match: { isActive: true } },
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]);

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: categories,
    });
  } catch (error) {
    logger.error('Get categories error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch categories',
    });
  }
};

exports.createDisease = async (req, res) => {
  try {
    const disease = await Disease.create(req.body);

    return res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Disease created successfully',
      data: disease,
    });
  } catch (error) {
    logger.error('Create disease error:', error);
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

exports.updateDisease = async (req, res) => {
  try {
    const disease = await Disease.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    if (!disease) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Disease not found',
      });
    }

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Disease updated successfully',
      data: disease,
    });
  } catch (error) {
    logger.error('Update disease error:', error);
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: error.message,
    });
  }
};

exports.deleteDisease = async (req, res) => {
  try {
    const disease = await Disease.findByIdAndUpdate(
      req.params.id,
      { isActive: false },
      { new: true }
    );

    if (!disease) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({
        success: false,
        message: 'Disease not found',
      });
    }

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Disease deleted successfully',
    });
  } catch (error) {
    logger.error('Delete disease error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to delete disease',
    });
  }
};