const Disease  = require('../models/Disease');
const logger   = require('../utils/logger');
const { HTTP_STATUS, DISEASE_CATEGORIES } = require('../config/constants');
const mlService = require('../services/mlService');
const { uploadBuffer } = require('../utils/cloudinary');
const fs   = require('fs');
const os   = require('os');
const path = require('path');

// ── Disease info JSON (cached) ─────────────────────────────────────────
let DISEASE_INFO_CACHE = null;

function loadDiseaseInfoJson() {
  if (DISEASE_INFO_CACHE) return DISEASE_INFO_CACHE;
  const filePath = path.join(__dirname, '..', 'ml', 'models', 'onion_disease_info.json');
  try {
    DISEASE_INFO_CACHE = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
    logger.info(`✅ Disease info JSON loaded`);
  } catch (e) {
    logger.warn(`⚠️ Could not load disease info JSON: ${e.message}`);
    DISEASE_INFO_CACHE = {};
  }
  return DISEASE_INFO_CACHE;
}

// ── Helpers ────────────────────────────────────────────────────────────
function formatDiseaseName(cls) {
  if (!cls) return '';
  const parts = String(cls).split('___');
  return (parts.length > 1 ? parts.slice(1).join('___') : String(cls))
    .replace(/_/g, ' ').trim();
}

function formatCropName(cls) {
  if (!cls) return '';
  return (String(cls).split('___')[0] || '').replace(/_/g, ' ').trim();
}

function riskLevelFromConfidence(conf) {
  const c = Number(conf || 0);
  if (c >= 0.9) return 'High';
  if (c >= 0.7) return 'Medium';
  return 'Low';
}

async function findDiseaseFromDB(name) {
  if (!name) return null;
  return (
    await Disease.findOne({ name: new RegExp(`^${name}$`, 'i'), isActive: true }) ||
    await Disease.findOne({ name: new RegExp(name, 'i'), isActive: true })
  );
}

function mapDiseaseToFlutterModel({ dbDisease, predictedClass, confidence, readableName, extraInfo }) {
  const diseaseInfoMap = loadDiseaseInfoJson();
  const jsonInfo = predictedClass && diseaseInfoMap[predictedClass]
    ? diseaseInfoMap[predictedClass] : null;

  const mlSymptoms  = extraInfo?.symptoms   || extraInfo?.info?.symptoms   || '';
  const mlCause     = extraInfo?.cause      || extraInfo?.info?.cause      || '';
  const mlSolution  = extraInfo?.solution   || extraInfo?.info?.solution   || '';
  const mlOrganic   = extraInfo?.organic_treatment || extraInfo?.info?.organic_treatment || '';
  const mlChemical  = extraInfo?.chemical_treatment || extraInfo?.info?.chemical_treatment || '';
  const mlCropName  = extraInfo?.crop_name  || extraInfo?.info?.crop_name  ||
                      extraInfo?.cropName   || formatCropName(predictedClass) || '';

  const symptomsFinal       = jsonInfo?.symptoms        || mlSymptoms  || 'Consult agricultural expert';
  const causeFinal          = jsonInfo?.cause           || mlCause     || 'Consult agricultural expert';
  const solutionFinal       = jsonInfo?.solution        || mlSolution  || 'Consult agricultural expert';
  const preventionFinal     = jsonInfo?.prevention      || extraInfo?.prevention || 'Follow best farming practices';
  const recommendationsFinal = Array.isArray(jsonInfo?.recommendations) ? jsonInfo.recommendations : [];

  const diseaseNameFinal = dbDisease?.name || jsonInfo?.disease_name || readableName || 'Unknown';
  const cropNameFinal    = dbDisease?.cropName || dbDisease?.crop_name ||
                           jsonInfo?.crop_name || mlCropName || 'Unknown';

  const descriptionFromML = [
    symptomsFinal ? `Symptoms: ${symptomsFinal}` : '',
    causeFinal    ? `Cause: ${causeFinal}`        : '',
  ].filter(Boolean).join('\n\n');

  const dbOrganic  = (Array.isArray(dbDisease?.treatment?.organic)
    ? dbDisease.treatment.organic.join('\n') : null) || dbDisease?.organicTreatment  || '';
  const dbChemical = (Array.isArray(dbDisease?.treatment?.chemical)
    ? dbDisease.treatment.chemical.join('\n') : null) || dbDisease?.chemicalTreatment || '';

  return {
    id:          dbDisease?._id?.toString() || predictedClass || 'unknown',
    name:        diseaseNameFinal,
    name_sinhala: dbDisease?.nameSinhala || dbDisease?.name_sinhala || '',
    crop_name:   cropNameFinal,
    description: dbDisease?.description || descriptionFromML || 'No description available',
    organic_treatment:  dbOrganic  || mlOrganic  || solutionFinal,
    chemical_treatment: dbChemical || mlChemical || solutionFinal,
    // ✅ image_url comes from DB (Cloudinary URL stored there) or empty
    image_url:   dbDisease?.imageUrl || dbDisease?.image_url || '',
    confidence:  Number(confidence || 0),
    risk_level:  dbDisease?.severity || dbDisease?.risk_level || riskLevelFromConfidence(confidence),
    class:       predictedClass || '',
    symptoms:    symptomsFinal,
    cause:       causeFinal,
    solution:    solutionFinal,
    prevention:  preventionFinal,
    recommendations: recommendationsFinal,
  };
}

// ── POST /api/v1/ml/detect-disease ────────────────────────────────────
exports.detectDisease = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'No image file uploaded.',
      });
    }

    logger.info(`🔍 ML detect-disease: ${req.file.originalname}`);

    // ✅ Write temp file for ML service
    const ext     = req.file.originalname.split('.').pop() || 'jpg';
    const tmpPath = path.join(os.tmpdir(), `ml_${Date.now()}.${ext}`);
    fs.writeFileSync(tmpPath, req.file.buffer);

    let mlResult;
    try {
      mlResult = await mlService.detectDisease(tmpPath);
    } finally {
      try { fs.unlinkSync(tmpPath); } catch (_) {}
    }

    let top = null;
    if (Array.isArray(mlResult))                               top = mlResult[0];
    else if (mlResult?.predictions && Array.isArray(mlResult.predictions)) top = mlResult.predictions[0];
    else                                                        top = mlResult;

    const predictedClass = top?.class || top?.label || top?.id || '';
    const confidence     = Number(top?.confidence ?? mlResult?.confidence ?? 0);
    const readableName   = top?.disease_name || top?.disease || top?.name ||
                           formatDiseaseName(predictedClass) || 'Unknown';
    const extraInfo      = top || mlResult || {};

    const dbDisease  = await findDiseaseFromDB(readableName);
    const flutterJson = mapDiseaseToFlutterModel({ dbDisease, predictedClass, confidence, readableName, extraInfo });

    logger.info(`✅ ML result: ${flutterJson.crop_name} - ${flutterJson.name} (${(flutterJson.confidence * 100).toFixed(2)}%)`);

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

// ── POST /api/v1/ml/batch-detect ──────────────────────────────────────
exports.batchDetect = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({ success: false, message: 'No image files uploaded' });
    }

    logger.info(`🔍 ML batch-detect: ${req.files.length} images`);

    // ✅ Write all temp files
    const tmpPaths = req.files.map((file) => {
      const ext = file.originalname.split('.').pop() || 'jpg';
      const tmpPath = path.join(os.tmpdir(), `ml_batch_${Date.now()}_${Math.random()}.${ext}`);
      fs.writeFileSync(tmpPath, file.buffer);
      return tmpPath;
    });

    let mlResults;
    try {
      mlResults = await mlService.batchDetectDiseases(tmpPaths);
    } finally {
      tmpPaths.forEach((p) => { try { fs.unlinkSync(p); } catch (_) {} });
    }

    const results = await Promise.all(
      mlResults.map(async (r, i) => {
        let top = Array.isArray(r) ? r[0]
                : (r?.predictions && Array.isArray(r.predictions)) ? r.predictions[0]
                : r;

        const predictedClass = top?.class || top?.label || top?.id || '';
        const confidence     = Number(top?.confidence ?? r?.confidence ?? 0);
        const readableName   = top?.disease_name || top?.disease || top?.name ||
                               formatDiseaseName(predictedClass) || 'Unknown';
        const dbDisease = await findDiseaseFromDB(readableName);

        return {
          filename: req.files[i]?.originalname || `image_${i + 1}`,
          ...mapDiseaseToFlutterModel({ dbDisease, predictedClass, confidence, readableName, extraInfo: top || r || {} }),
        };
      })
    );

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      totalImages: req.files.length,
      results,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('❌ Batch detection error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Batch detection failed', error: error.message });
  }
};

// ── Unchanged ML utility routes ────────────────────────────────────────
exports.getHealth = async (req, res) => {
  try {
    const health = await mlService.checkHealth();
    return res.status(HTTP_STATUS.OK).json({ success: true, ...health, timestamp: new Date().toISOString() });
  } catch (error) {
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, error: error.message });
  }
};

exports.getModelInfo = async (req, res) => {
  try {
    return res.status(HTTP_STATUS.OK).json({ success: true, modelInfo: mlService.getModelInfo(), timestamp: new Date().toISOString() });
  } catch (error) {
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, error: error.message });
  }
};

exports.reconnect = async (req, res) => {
  try {
    const connected = await mlService.reconnect();
    return res.status(HTTP_STATUS.OK).json({
      success: true, connected,
      message: connected ? '✅ Connected to ML API' : '⚠️ Failed to connect',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, error: error.message });
  }
};

exports.testML = async (req, res) => {
  try {
    const [mockPredictions, modelInfo] = await Promise.all([
      mlService.getMockPredictions(),
      Promise.resolve(mlService.getModelInfo()),
    ]);
    return res.status(HTTP_STATUS.OK).json({ success: true, message: '✅ ML Service test successful', mockPredictions, modelInfo, timestamp: new Date().toISOString() });
  } catch (error) {
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'ML service test failed', error: error.message });
  }
};

// ── Disease DB controllers (unchanged) ────────────────────────────────
exports.getAllDiseases = async (req, res) => {
  try {
    const { category, severity, search } = req.query;
    const page  = parseInt(req.query.page)  || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip  = (page - 1) * limit;

    const query = { isActive: true };
    if (category) query.category = category;
    if (severity) query.severity = severity;
    if (search)   query.$text = { $search: search };

    const [diseases, total] = await Promise.all([
      Disease.find(query).limit(limit).skip(skip).sort({ name: 1 }),
      Disease.countDocuments(query),
    ]);

    return res.status(HTTP_STATUS.OK).json({ success: true, data: diseases, pagination: { page, limit, total, pages: Math.ceil(total / limit) } });
  } catch (error) {
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Failed to fetch diseases' });
  }
};

exports.getDiseaseById = async (req, res) => {
  try {
    const disease = await Disease.findById(req.params.id);
    if (!disease) return res.status(HTTP_STATUS.NOT_FOUND).json({ success: false, message: 'Disease not found' });
    return res.status(HTTP_STATUS.OK).json({ success: true, data: disease });
  } catch (error) {
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Failed to fetch disease' });
  }
};

exports.getDiseasesByCrop = async (req, res) => {
  try {
    const { cropType } = req.params;
    if (!Object.values(DISEASE_CATEGORIES).includes(cropType)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({ success: false, message: 'Invalid crop type' });
    }
    const diseases = await Disease.find({ category: cropType, isActive: true }).sort({ name: 1 });
    return res.status(HTTP_STATUS.OK).json({ success: true, data: diseases, count: diseases.length });
  } catch (error) {
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Failed to fetch diseases' });
  }
};

exports.searchDiseases = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) return res.status(HTTP_STATUS.BAD_REQUEST).json({ success: false, message: 'Search query required' });
    const diseases = await Disease.find({ $text: { $search: q }, isActive: true }).limit(20);
    return res.status(HTTP_STATUS.OK).json({ success: true, data: diseases });
  } catch (error) {
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Search failed' });
  }
};

exports.getCategories = async (req, res) => {
  try {
    const categories = await Disease.aggregate([
      { $match: { isActive: true } },
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]);
    return res.status(HTTP_STATUS.OK).json({ success: true, data: categories });
  } catch (error) {
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Failed to fetch categories' });
  }
};

exports.createDisease = async (req, res) => {
  try {
    const disease = await Disease.create(req.body);
    return res.status(HTTP_STATUS.CREATED).json({ success: true, message: 'Disease created', data: disease });
  } catch (error) {
    return res.status(HTTP_STATUS.BAD_REQUEST).json({ success: false, message: error.message });
  }
};

exports.updateDisease = async (req, res) => {
  try {
    const disease = await Disease.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!disease) return res.status(HTTP_STATUS.NOT_FOUND).json({ success: false, message: 'Disease not found' });
    return res.status(HTTP_STATUS.OK).json({ success: true, message: 'Disease updated', data: disease });
  } catch (error) {
    return res.status(HTTP_STATUS.BAD_REQUEST).json({ success: false, message: error.message });
  }
};

exports.deleteDisease = async (req, res) => {
  try {
    const disease = await Disease.findByIdAndUpdate(req.params.id, { isActive: false }, { new: true });
    if (!disease) return res.status(HTTP_STATUS.NOT_FOUND).json({ success: false, message: 'Disease not found' });
    return res.status(HTTP_STATUS.OK).json({ success: true, message: 'Disease deleted' });
  } catch (error) {
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Failed to delete disease' });
  }
};
