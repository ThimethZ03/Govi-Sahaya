const axios = require('axios');
const sharp = require('sharp');
const FormData = require('form-data');
const logger = require('../utils/logger');
const { ML } = require('../config/constants');

let mlApiAvailable = false;
const ML_API_URL = process.env.ML_API_URL || 'http://127.0.0.1:5001';

// Disease class names
const DISEASE_CLASSES = {
  onion: [
    'Alternaria',
    'Anthracnose', 
    'Bacterial_Blight',
    'Basal_Rot',
    'Downy_Mildew',
    'Healthy',
    'Leaf_Blight',
    'Purple_Blotch',
    'Rust',
    'Smudge',
    'Smut',
    'Stemphylium_Blight',
    'White_Rot',
    'bacterial_soft_rot',
    'pink_root'
  ],
  tomato: [
    'Bacterial_spot',
    'Early_blight',
    'Late_blight',
    'Leaf_Mold',
    'Septoria_leaf_spot',
    'Spider_mites',
    'Target_Spot',
    'Yellow_Leaf_Curl_Virus',
    'Tomato_mosaic_virus',
    'healthy'
  ],
  potato: [
    'Early_blight',
    'Late_blight',
    'healthy'
  ]
};

// Initialize ML service
exports.initialize = async () => {
  try {
    logger.info('Initializing ML service...');
    
    // Check if Python ML API is available
    try {
      const response = await axios.get(`${ML_API_URL}/health`, { timeout: 3000 });
      if (response.data.status === 'ok' || response.data.status === 'healthy') {
        mlApiAvailable = true;
        logger.info('✅ ML API Status: Connected');
        logger.info(`📡 ML API URL: ${ML_API_URL}`);
      }
    } catch (error) {
      mlApiAvailable = false;
      logger.warn('⚠️  ML API Status: Offline');
      logger.info('💡 To enable ML predictions:');
      logger.info('   1. cd ../ml_model');
      logger.info('   2. .\\venv\\Scripts\\Activate');
      logger.info('   3. python ml_api.py');
      logger.warn('📝 Using mock predictions until ML API is started');
    }
  } catch (error) {
    logger.error('ML service initialization error:', error.message);
    logger.warn('⚠️  ML service will use mock predictions');
  }
};

// Preprocess image
exports.preprocessImage = async (imageBuffer) => {
  try {
    // Resize image to model's expected size
    const processedImage = await sharp(imageBuffer)
      .resize(ML.IMAGE_SIZE || 224, ML.IMAGE_SIZE || 224)
      .jpeg({ quality: 90 })
      .toBuffer();

    return processedImage;
  } catch (error) {
    logger.error('Image preprocessing error:', error);
    throw new Error('Failed to process image');
  }
};

// Detect disease from image using Python ML API
exports.detectDisease = async (imageBuffer) => {
  try {
    const startTime = Date.now();

    if (mlApiAvailable) {
      // Preprocess image
      const processedImage = await this.preprocessImage(imageBuffer);

      // Send to Python ML API
      const form = new FormData();
      form.append('file', processedImage, {
        filename: 'image.jpg',
        contentType: 'image/jpeg'
      });

      const response = await axios.post(`${ML_API_URL}/predict`, form, {
        headers: {
          ...form.getHeaders(),
        },
        timeout: 30000, // 30 seconds
        maxContentLength: Infinity,
        maxBodyLength: Infinity
      });

      const processingTime = Date.now() - startTime;
      logger.info(`✅ Disease detection completed in ${processingTime}ms`);

      return response.data.predictions || response.data;
    } else {
      // Use mock predictions
      logger.warn('Using mock predictions - ML API not available');
      const predictions = await this.getMockPredictions();
      
      const processingTime = Date.now() - startTime;
      logger.info(`Mock detection completed in ${processingTime}ms`);

      return predictions;
    }
  } catch (error) {
    logger.error('Disease detection error:', error.message);
    
    // Fallback to mock predictions on error
    logger.warn('Falling back to mock predictions due to error');
    return await this.getMockPredictions();
  }
};

// Mock predictions for testing
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
          'Apply compost tea as foliar spray'
        ],
        chemical: [
          'Mancozeb 75% WP (2-2.5g per liter)',
          'Chlorothalonil 75% WP (2g per liter)',
          'Azoxystrobin 23% SC (1ml per liter)'
        ],
        preventive: [
          'Practice 2-3 year crop rotation',
          'Avoid overhead watering',
          'Ensure proper spacing between plants',
          'Remove crop debris after harvest',
          'Use disease-free seeds or sets'
        ]
      },
      recommendedActions: [
        'Remove severely infected leaves immediately',
        'Apply fungicide within 24 hours',
        'Improve air circulation around plants',
        'Monitor daily for spread'
      ]
    },
    {
      class: 'Healthy',
      disease: 'Healthy Plant',
      confidence: 0.10,
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
          'Balanced fertilization'
        ]
      },
      recommendedActions: [
        'Continue current care routine',
        'Monitor for any changes',
        'Maintain optimal growing conditions'
      ]
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
        organic: [
          'Copper-based fungicides',
          'Potassium bicarbonate spray',
          'Improve drainage'
        ],
        chemical: [
          'Metalaxyl-based fungicides',
          'Fosetyl-Al 80% WP'
        ],
        preventive: [
          'Plant in well-drained soil',
          'Ensure good air circulation',
          'Avoid evening watering'
        ]
      },
      recommendedActions: [
        'Reduce humidity around plants',
        'Apply fungicide if conditions favor disease',
        'Monitor weather conditions'
      ]
    }
  ];
};

// Analyze disease severity
exports.analyzeSeverity = async (diseaseName, confidence) => {
  try {
    if (confidence >= 0.9) return 'critical';
    if (confidence >= 0.7) return 'high';
    if (confidence >= 0.5) return 'moderate';
    return 'low';
  } catch (error) {
    logger.error('Severity analysis error:', error);
    return 'moderate';
  }
};

// Get treatment recommendations
exports.getTreatmentRecommendations = async (diseaseId) => {
  try {
    const Disease = require('../models/Disease');
    const disease = await Disease.findById(diseaseId);

    if (!disease) {
      return {
        organic: [],
        chemical: [],
        preventive: [],
      };
    }

    return disease.treatment;
  } catch (error) {
    logger.error('Get treatment recommendations error:', error);
    throw error;
  }
};

// Batch process multiple images
exports.batchDetectDiseases = async (imageBuffers) => {
  try {
    const results = await Promise.all(
      imageBuffers.map((buffer) => this.detectDisease(buffer))
    );

    return results;
  } catch (error) {
    logger.error('Batch disease detection error:', error);
    throw error;
  }
};

// Get model info
exports.getModelInfo = () => {
  return {
    apiAvailable: mlApiAvailable,
    apiUrl: ML_API_URL,
    imageSize: ML.IMAGE_SIZE || 224,
    confidenceThreshold: ML.CONFIDENCE_THRESHOLD || 0.5,
    maxPredictions: ML.MAX_PREDICTIONS || 5,
    supportedCrops: Object.keys(DISEASE_CLASSES),
    diseaseClasses: DISEASE_CLASSES,
    status: mlApiAvailable ? '✅ Connected to ML API' : '⚠️ Using mock predictions'
  };
};

// Check ML API health
exports.checkHealth = async () => {
  try {
    const response = await axios.get(`${ML_API_URL}/health`, { timeout: 3000 });
    mlApiAvailable = true;
    return {
      available: true,
      status: response.data,
      url: ML_API_URL
    };
  } catch (error) {
    mlApiAvailable = false;
    return {
      available: false,
      error: error.message,
      url: ML_API_URL
    };
  }
};

// Reconnect to ML API
exports.reconnect = async () => {
  logger.info('Attempting to reconnect to ML API...');
  await this.initialize();
  return mlApiAvailable;
};
