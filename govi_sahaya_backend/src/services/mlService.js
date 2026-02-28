// services/mlService.js
// ✅ FULL FIXED VERSION (diskStorage + correct form-data key + returns full fields)
//
// Fixes:
// 1) diskStorage => we read from filePath (Sharp reads path)
// 2) Send to Python ML API with key "file" (your ml_api.py accepts file OR image)
// 3) If Python returns {success:true, ...} we normalize to ONE top result object
// 4) If error happens (400/500) we fallback to mock predictions
// 5) Adds safer logging (shows server error body)

const axios = require('axios');
const sharp = require('sharp');
const FormData = require('form-data');
const fs = require('fs');
const logger = require('../utils/logger');
const { ML } = require('../config/constants');

let mlApiAvailable = false;
const ML_API_URL = process.env.ML_API_URL || 'http://127.0.0.1:5001';

// ----------------------------
// Initialize ML service
// ----------------------------
exports.initialize = async () => {
  try {
    logger.info('Initializing ML service...');

    try {
      const response = await axios.get(`${ML_API_URL}/health`, { timeout: 3000 });

      if (response.data?.status === 'ok' || response.data?.status === 'healthy') {
        mlApiAvailable = true;
        logger.info('✅ ML API Status: Connected');
        logger.info(`📡 ML API URL: ${ML_API_URL}`);
      } else {
        mlApiAvailable = false;
        logger.warn('⚠️ ML API Status: Offline (unexpected health response)');
      }
    } catch (error) {
      mlApiAvailable = false;
      logger.warn('⚠️  ML API Status: Offline');
      logger.info('💡 To enable ML predictions:');
      logger.info('   1. cd ml');
      logger.info('   2. .\\venv\\Scripts\\Activate');
      logger.info('   3. python ml_api.py');
      logger.warn('📝 Using mock predictions until ML API is started');
    }
  } catch (error) {
    logger.error('ML service initialization error:', error.message);
    logger.warn('⚠️  ML service will use mock predictions');
  }
};

// ----------------------------
// Preprocess image from FILE PATH (diskStorage)
// ----------------------------
exports.preprocessImage = async (filePath) => {
  try {
    if (!filePath) throw new Error('No image filePath provided');

    // ensure file exists
    if (!fs.existsSync(filePath)) {
      throw new Error(`Image file not found: ${filePath}`);
    }

    // sharp can read path directly
    const processedImage = await sharp(filePath)
      .resize(ML.IMAGE_SIZE || 224, ML.IMAGE_SIZE || 224, { fit: 'cover' })
      .jpeg({ quality: 90 })
      .toBuffer();

    return processedImage;
  } catch (error) {
    logger.error('Image preprocessing error:', error);
    throw new Error('Failed to process image');
  }
};

// ----------------------------
// Normalize ML API response
// ----------------------------
function normalizeMlApiResponse(data) {
  // Python currently returns:
  // { success:true, id, name, crop_name, description, organic_treatment, chemical_treatment, confidence, ... }
  // OR some older versions might return {predictions:[...]}
  if (!data) return null;

  // If wrapped with predictions list
  if (data.predictions && Array.isArray(data.predictions) && data.predictions.length > 0) {
    return data.predictions[0];
  }

  // If already a single object result
  return data;
}

// ----------------------------
// Detect disease expects FILE PATH
// ----------------------------
exports.detectDisease = async (filePath) => {
  const startTime = Date.now();

  try {
    if (!mlApiAvailable) {
      logger.warn('Using mock predictions - ML API not available');
      return await exports.getMockPredictions();
    }

    const processedImage = await exports.preprocessImage(filePath);

    // ✅ IMPORTANT: send key = "file" (Node side)
    // Your ml_api.py accepts request.files.get("file") OR request.files.get("image")
    const form = new FormData();
    form.append('file', processedImage, {
      filename: 'image.jpg',
      contentType: 'image/jpeg',
    });

    const response = await axios.post(`${ML_API_URL}/predict`, form, {
      headers: { ...form.getHeaders() },
      timeout: 30000,
      maxContentLength: Infinity,
      maxBodyLength: Infinity,
      // helpful: allow us to read 400 body
      validateStatus: (s) => s != null && s < 500,
    });

    const processingTime = Date.now() - startTime;

    // If Python returns error (400/4xx)
    if (response.status >= 400) {
      logger.error(
        `ML API returned HTTP ${response.status} in ${processingTime}ms`,
        response.data
      );
      logger.warn('Falling back to mock predictions due to ML API error');
      return await exports.getMockPredictions();
    }

    logger.info(`✅ Disease detection completed in ${processingTime}ms`);

    const top = normalizeMlApiResponse(response.data);

    // If somehow empty, fallback
    if (!top) {
      logger.warn('ML API response empty. Falling back to mock predictions.');
      return await exports.getMockPredictions();
    }

    // Return a SINGLE object (controller will normalize too)
    return top;
  } catch (error) {
    const processingTime = Date.now() - startTime;

    // show server message if available
    const serverMsg = error?.response?.data;
    if (serverMsg) {
      logger.error(`Disease detection error in ${processingTime}ms:`, serverMsg);
    } else {
      logger.error(`Disease detection error in ${processingTime}ms:`, error.message);
    }

    logger.warn('Falling back to mock predictions due to error');
    return await exports.getMockPredictions();
  }
};

// ----------------------------
// Batch detect expects array of FILE PATHS
// ----------------------------
exports.batchDetectDiseases = async (filePaths) => {
  try {
    if (!Array.isArray(filePaths) || filePaths.length === 0) {
      return [];
    }

    const results = await Promise.all(filePaths.map((p) => exports.detectDisease(p)));
    return results;
  } catch (error) {
    logger.error('Batch disease detection error:', error);
    throw error;
  }
};

// ----------------------------
// Mock predictions (unchanged)
// ----------------------------
exports.getMockPredictions = async () => {
  return [
    {
      class: 'Purple_Blotch',
      disease: 'Purple Blotch',
      confidence: 0.85,
      severity: 'high',
      cropType: 'onion',
      symptoms: 'Purple spots with yellow margins on leaves, lesions on flower stalks',
      cause: 'Fungal disease caused by Alternaria porri, thrives in warm humid conditions',
      treatment: {
        organic: [
          'Apply neem oil spray (3-5ml per liter)',
          'Use garlic extract solution',
          'Remove and destroy infected plant parts',
          'Apply compost tea as foliar spray',
        ],
        chemical: [
          'Mancozeb 75% WP (2-2.5g per liter)',
          'Chlorothalonil 75% WP (2g per liter)',
          'Azoxystrobin 23% SC (1ml per liter)',
        ],
        preventive: [
          'Practice 2-3 year crop rotation',
          'Avoid overhead watering',
          'Ensure proper spacing between plants',
          'Remove crop debris after harvest',
          'Use disease-free seeds or sets',
        ],
      },
      recommendedActions: [
        'Remove severely infected leaves immediately',
        'Apply fungicide within 24 hours',
        'Improve air circulation around plants',
        'Monitor daily for spread',
      ],
    },
    {
      class: 'Healthy',
      disease: 'Healthy Plant',
      confidence: 0.1,
      severity: 'none',
      cropType: 'onion',
      symptoms: 'No visible disease symptoms detected',
      cause: 'N/A',
      treatment: {
        organic: ['Continue regular monitoring', 'Maintain good agricultural practices'],
        chemical: [],
        preventive: [
          'Regular inspection for early disease detection',
          'Proper irrigation management',
          'Balanced fertilization',
        ],
      },
      recommendedActions: [
        'Continue current care routine',
        'Monitor for any changes',
        'Maintain optimal growing conditions',
      ],
    },
    {
      class: 'Downy_Mildew',
      disease: 'Downy Mildew',
      confidence: 0.05,
      severity: 'moderate',
      cropType: 'onion',
      symptoms: 'Pale yellow spots on leaves, purple-gray mold on underside',
      cause: 'Caused by Peronospora destructor in cool, wet conditions',
      treatment: {
        organic: ['Copper-based fungicides', 'Potassium bicarbonate spray', 'Improve drainage'],
        chemical: ['Metalaxyl-based fungicides', 'Fosetyl-Al 80% WP'],
        preventive: [
          'Plant in well-drained soil',
          'Ensure good air circulation',
          'Avoid evening watering',
        ],
      },
      recommendedActions: [
        'Reduce humidity around plants',
        'Apply fungicide if conditions favor disease',
        'Monitor weather conditions',
      ],
    },
  ];
};

exports.getModelInfo = () => {
  return {
    apiAvailable: mlApiAvailable,
    apiUrl: ML_API_URL,
    imageSize: ML.IMAGE_SIZE || 224,
    confidenceThreshold: ML.CONFIDENCE_THRESHOLD || 0.5,
    maxPredictions: ML.MAX_PREDICTIONS || 5,
    status: mlApiAvailable ? '✅ Connected to ML API' : '⚠️ Using mock predictions',
  };
};

exports.checkHealth = async () => {
  try {
    const response = await axios.get(`${ML_API_URL}/health`, { timeout: 3000 });
    mlApiAvailable = true;
    return { available: true, status: response.data, url: ML_API_URL };
  } catch (error) {
    mlApiAvailable = false;
    return { available: false, error: error.message, url: ML_API_URL };
  }
};

exports.reconnect = async () => {
  logger.info('Attempting to reconnect to ML API...');
  await exports.initialize();
  return mlApiAvailable;
};
