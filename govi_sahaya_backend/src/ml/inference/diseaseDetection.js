const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const ImagePreprocessor = require('../preprocessing/imagePreprocessor');

/**
 * Disease Detection Inference
 * Handles ML model inference for crop disease detection
 * Specialized for Onion crop diseases (expandable to other crops)
 */
class DiseaseDetection {
  constructor(config = {}) {
    this.mlApiUrl = config.mlApiUrl || process.env.ML_API_URL || 'http://localhost:5001';
    this.preprocessor = new ImagePreprocessor();
    this.modelMetadata = this.loadModelMetadata();
    this.diseaseInfo = this.loadDiseaseInfo();
    this.confidenceThreshold = config.confidenceThreshold || 0.6;
  }

  /**
   * Load model metadata
   * @returns {Object} Model metadata
   */
  loadModelMetadata() {
    try {
      const metadataPath = path.join(__dirname, '../models/model_metadata.json');
      const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
      return metadata;
    } catch (error) {
      console.warn('Could not load model metadata:', error.message);
      return {
        classes: [],
        num_classes: 0,
        crop: 'unknown'
      };
    }
  }

  /**
   * Load disease information
   * @returns {Object} Disease information
   */
  loadDiseaseInfo() {
    try {
      const infoPath = path.join(__dirname, '../models/onion_disease_info.json');
      const diseaseInfo = JSON.parse(fs.readFileSync(infoPath, 'utf8'));
      return diseaseInfo;
    } catch (error) {
      console.warn('Could not load disease info:', error.message);
      return { diseases: [] };
    }
  }

  /**
   * Detect disease from image
   * @param {string} imagePath - Path to image file
   * @returns {Promise<Object>} Detection result
   */
  async detect(imagePath) {
    try {
      console.log('🔍 Starting disease detection...');
      
      // Validate image
      const validation = await this.preprocessor.validateImage(imagePath);
      
      if (!validation.isValid) {
        return {
          success: false,
          error: 'Invalid image',
          issues: validation.issues
        };
      }

      console.log('✅ Image validation passed');

      // Send to ML API
      const prediction = await this.callMLAPI(imagePath);

      // Process results
      const result = this.processDetection(prediction);

      // Get detailed disease information
      const diseaseDetails = this.getDiseaseDetails(result.rawPrediction);

      return {
        success: true,
        prediction: result,
        diseaseDetails: diseaseDetails,
        imageFeatures: validation.features,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('❌ Disease detection error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Call ML API for prediction
   * @param {string} imagePath - Path to image file
   * @returns {Promise<Object>} API response
   */
  async callMLAPI(imagePath) {
    try {
      console.log(`📡 Calling ML API at ${this.mlApiUrl}/predict`);
      
      const formData = new FormData();
      formData.append('file', fs.createReadStream(imagePath));

      const response = await axios.post(
        `${this.mlApiUrl}/predict`,
        formData,
        {
          headers: formData.getHeaders(),
          timeout: 30000 // 30 seconds
        }
      );

      console.log('✅ ML API response received');
      return response.data;
    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        // ML API is not available, return mock prediction
        console.warn('⚠️ ML API not available, using mock prediction');
        return this.getMockPrediction();
      }
      throw error;
    }
  }

  /**
   * Process detection results
   * @param {Object} prediction - Raw prediction from ML API
   * @returns {Object} Processed detection result
   */
  processDetection(prediction) {
    const { class: predictedClass, confidence, probabilities } = prediction;

    // Parse class name (format: Crop___Disease_Name)
    const parts = predictedClass.split('___');
    const crop = parts[0] || 'Unknown';
    const disease = parts.length > 1 ? parts.slice(1).join(' ').replace(/_/g, ' ') : 'Unknown';

    const isHealthy = disease.toLowerCase().includes('healthy') || 
                     disease.toLowerCase().includes('onion1');
    const isConfident = confidence >= this.confidenceThreshold;

    return {
      disease: disease,
      crop: crop,
      confidence: confidence,
      confidencePercentage: Math.round(confidence * 100),
      isHealthy: isHealthy,
      isConfident: isConfident,
      severity: this.calculateSeverity(confidence, isHealthy, disease),
      recommendations: this.getRecommendations(disease, crop, confidence),
      treatmentPlan: this.getTreatmentPlan(disease, isHealthy),
      topPredictions: this.getTopPredictions(probabilities),
      rawPrediction: predictedClass
    };
  }

  /**
   * Calculate disease severity
   * @param {number} confidence - Prediction confidence
   * @param {boolean} isHealthy - Is the crop healthy
   * @param {string} disease - Disease name
   * @returns {string} Severity level
   */
  calculateSeverity(confidence, isHealthy, disease) {
    if (isHealthy) return 'none';
    
    // Check disease database for severity
    const diseaseData = this.diseaseInfo.diseases?.find(d => 
      d.class_name.toLowerCase().includes(disease.toLowerCase().replace(/ /g, '_'))
    );

    if (diseaseData) {
      return diseaseData.severity.toLowerCase();
    }

    // Fallback to confidence-based severity
    if (confidence > 0.9) return 'high';
    if (confidence > 0.7) return 'moderate';
    return 'low';
  }

  /**
   * Get treatment recommendations
   * @param {string} disease - Disease name
   * @param {string} crop - Crop name
   * @param {number} confidence - Prediction confidence
   * @returns {Array<string>} Recommendations
   */
  getRecommendations(disease, crop, confidence) {
    const recommendations = [];

    // Healthy plant recommendations
    if (disease.toLowerCase().includes('healthy') || disease.toLowerCase().includes('onion1')) {
      recommendations.push('✅ Your onion crop is healthy!');
      recommendations.push('Continue regular monitoring and care');
      recommendations.push('Maintain current fertilization schedule');
      recommendations.push('Ensure proper irrigation (avoid over-watering)');
      recommendations.push('Scout field weekly for early disease detection');
      return recommendations;
    }

    // General high confidence recommendations
    if (confidence > 0.8) {
      recommendations.push('⚠️ High confidence detection - immediate action recommended');
      recommendations.push('Consult with agricultural expert for confirmation');
    } else if (confidence < 0.6) {
      recommendations.push('⚠️ Low confidence - consider retaking image or consulting expert');
    }

    // Onion-specific disease treatments
    const diseaseLower = disease.toLowerCase();

    if (diseaseLower.includes('purple') || diseaseLower.includes('blotch') || diseaseLower.includes('alternaria')) {
      recommendations.push('🔸 Purple Blotch (Alternaria porri) detected');
      recommendations.push('💊 Chemical: Apply Mancozeb 75% WP @ 2g/L or Chlorothalonil 75% WP @ 2g/L');
      recommendations.push('🌿 Organic: Neem oil spray (5ml/L) or Copper oxychloride 50% WP @ 3g/L');
      recommendations.push('✂️ Remove and destroy infected leaves immediately');
      recommendations.push('💧 Avoid overhead irrigation - use drip irrigation');
      recommendations.push('🌬️ Ensure proper plant spacing (15-20cm) for air circulation');
      recommendations.push('🔄 Practice crop rotation with non-allium crops');
    } 
    else if (diseaseLower.includes('downy') || diseaseLower.includes('mildew')) {
      recommendations.push('🔸 Downy Mildew (Peronospora destructor) detected');
      recommendations.push('💊 Chemical: Apply Metalaxyl 8% + Mancozeb 64% WP @ 2.5g/L');
      recommendations.push('💊 Alternative: Cymoxanil 8% + Mancozeb 64% WP @ 2g/L');
      recommendations.push('🌿 Organic: Copper hydroxide 77% WP @ 3g/L or Bordeaux mixture (1%)');
      recommendations.push('🚜 Improve field drainage to reduce moisture');
      recommendations.push('⏰ Reduce leaf wetness duration - avoid late evening irrigation');
      recommendations.push('🗑️ Destroy infected plants immediately');
      recommendations.push('📏 Use wide row spacing (30cm minimum)');
    } 
    else if (diseaseLower.includes('stemphylium') || diseaseLower.includes('leaf blight')) {
      recommendations.push('🔸 Stemphylium Leaf Blight detected');
      recommendations.push('💊 Chemical: Apply Azoxystrobin 23% SC @ 1ml/L');
      recommendations.push('💊 Alternative: Difenoconazole 25% EC @ 1ml/L or Tebuconazole 25.9% EC @ 1ml/L');
      recommendations.push('🌿 Organic: Bacillus subtilis @ 5g/L or Pseudomonas fluorescens @ 5g/L');
      recommendations.push('🗑️ Remove infected plant debris from field');
      recommendations.push('🔄 Practice 2-3 year crop rotation');
      recommendations.push('🌱 Avoid excess nitrogen fertilization');
      recommendations.push('⚖️ Apply balanced NPK fertilization');
    } 
    else if (diseaseLower.includes('botrytis')) {
      recommendations.push('🔸 Botrytis Leaf Blight (Botrytis squamosa) detected');
      recommendations.push('💊 Chemical: Apply Iprodione 50% WP @ 2g/L');
      recommendations.push('💊 Alternative: Fenhexamid 50% WG @ 1g/L');
      recommendations.push('🌿 Organic: Trichoderma harzianum @ 5g/L or Sulfur dust');
      recommendations.push('🌬️ Improve air circulation in the field');
      recommendations.push('💧 Reduce leaf wetness - avoid overhead irrigation');
      recommendations.push('✂️ Remove infected leaves promptly');
      recommendations.push('📏 Ensure proper plant spacing');
    } 
    else if (diseaseLower.includes('iris') || diseaseLower.includes('yellow') || diseaseLower.includes('virus')) {
      recommendations.push('🔸 Iris Yellow Spot Virus (IYSV) detected - No cure available');
      recommendations.push('🐛 Control thrips vectors with Imidacloprid 17.8% SL @ 0.3ml/L');
      recommendations.push('🐛 Alternative: Fipronil 5% SC @ 1.5ml/L or Spinosad 45% SC @ 0.3ml/L');
      recommendations.push('🌿 Organic thrips control: Neem oil spray');
      recommendations.push('🗑️ Remove and destroy infected plants immediately to prevent spread');
      recommendations.push('🟨 Use yellow sticky traps for thrips monitoring');
      recommendations.push('🌱 Use certified virus-free seeds/sets for next planting');
      recommendations.push('🪴 Avoid planting near infected onion fields');
      recommendations.push('🧹 Control weeds that may harbor the virus');
    } 
    else if (diseaseLower.includes('fusarium')) {
      recommendations.push('🔸 Fusarium Basal Rot (Fusarium oxysporum) detected');
      recommendations.push('💊 Chemical: Apply Carbendazim 50% WP @ 2g/L as soil drench');
      recommendations.push('💊 Seed treatment: Thiram 75% WS @ 3g/kg seeds');
      recommendations.push('🌿 Organic: Trichoderma viride @ 5g/L soil drench or Neem cake in soil');
      recommendations.push('🚜 Improve soil drainage - avoid waterlogging');
      recommendations.push('🔄 Practice 3-4 year crop rotation with non-host crops');
      recommendations.push('💧 Avoid over-irrigation');
      recommendations.push('🗑️ Remove and destroy infected plants and bulbs');
      recommendations.push('☀️ Consider soil solarization before next planting');
    } 
    else if (diseaseLower.includes('rust')) {
      recommendations.push('🔸 Onion Rust (Puccinia allii) detected');
      recommendations.push('💊 Chemical: Apply Mancozeb 75% WP @ 2g/L');
      recommendations.push('💊 Alternative: Propiconazole 25% EC @ 1ml/L or Hexaconazole 5% EC @ 2ml/L');
      recommendations.push('🌿 Organic: Sulfur dust application or Neem oil spray');
      recommendations.push('✂️ Remove infected leaves to reduce spore spread');
      recommendations.push('🌬️ Avoid dense planting - ensure air circulation');
      recommendations.push('💧 Proper irrigation management - avoid leaf wetness');
      recommendations.push('🧹 Field sanitation - remove crop debris');
    } 
    else if (diseaseLower.includes('bulb') && (diseaseLower.includes('rot') || diseaseLower.includes('blight'))) {
      recommendations.push('🔸 Bulb Rot/Blight detected');
      recommendations.push('🚜 Improve drainage and avoid waterlogging');
      recommendations.push('🗑️ Remove infected bulbs immediately to prevent spread');
      recommendations.push('🌿 Apply Trichoderma viride as soil treatment');
      recommendations.push('☀️ Ensure proper bulb curing (28-32°C, good ventilation)');
      recommendations.push('📦 Store in cool, dry, well-ventilated area');
      recommendations.push('🔪 Avoid mechanical injury during harvest');
      recommendations.push('💊 Pre-storage treatment with fungicide if needed');
    }
    else if (diseaseLower.includes('xanthomonas')) {
      recommendations.push('🔸 Xanthomonas Leaf Blight (Bacterial) detected');
      recommendations.push('💊 Chemical: Copper-based bactericides (Copper oxychloride 50% WP @ 3g/L)');
      recommendations.push('💊 Streptomycin sulfate @ 200ppm may help');
      recommendations.push('✂️ Remove and destroy infected plant parts');
      recommendations.push('💧 Avoid overhead irrigation and water splashing');
      recommendations.push('🧹 Practice strict field sanitation');
      recommendations.push('🌱 Use disease-free planting material');
      recommendations.push('🔄 Crop rotation with non-host crops');
    }
    else if (diseaseLower.includes('virosis')) {
      recommendations.push('🔸 Viral Disease detected');
      recommendations.push('🐛 Control insect vectors (aphids, thrips, whiteflies)');
      recommendations.push('💊 Apply systemic insecticides for vector control');
      recommendations.push('🗑️ Remove and destroy infected plants');
      recommendations.push('🌱 Use certified virus-free seeds/sets');
      recommendations.push('🧹 Control weeds that harbor viruses');
      recommendations.push('🪴 Avoid planting near infected fields');
    }
    else if (diseaseLower.includes('caterpillar')) {
      recommendations.push('🔸 Caterpillar Pest Infestation detected');
      recommendations.push('💊 Chemical: Apply Chlorpyrifos 20% EC @ 2ml/L');
      recommendations.push('💊 Alternative: Emamectin benzoate 5% SG @ 0.5g/L');
      recommendations.push('🌿 Organic: Neem oil spray or Bacillus thuringiensis (Bt)');
      recommendations.push('✋ Hand-pick and destroy visible caterpillars');
      recommendations.push('🪤 Use pheromone traps for monitoring');
      recommendations.push('🐦 Encourage natural predators (birds, parasitic wasps)');
    }
    else {
      // Generic onion disease recommendations
      recommendations.push('🔸 Onion disease detected - General treatment');
      recommendations.push('👨‍🌾 Monitor plant closely for symptom progression');
      recommendations.push('🏢 Consult with agricultural extension service');
      recommendations.push('🧹 Maintain field hygiene and sanitation');
      recommendations.push('💊 Consider applying broad-spectrum fungicide');
      recommendations.push('💧 Adjust irrigation based on disease type');
      recommendations.push('🌱 Ensure proper nutrition (avoid nitrogen excess)');
    }

    // General cultural practices for all diseases
    recommendations.push('');
    recommendations.push('📋 General Preventive Measures:');
    recommendations.push('• Maintain proper field sanitation');
    recommendations.push('• Monitor weather conditions regularly');
    recommendations.push('• Scout field 2-3 times per week');
    recommendations.push('• Use disease-resistant varieties when available');
    recommendations.push('• Maintain field records for future planning');

    return recommendations;
  }

  /**
   * Get treatment plan
   * @param {string} disease - Disease name
   * @param {boolean} isHealthy - Is healthy
   * @returns {Object} Treatment plan
   */
  getTreatmentPlan(disease, isHealthy) {
    if (isHealthy) {
      return {
        immediate: ['Continue monitoring', 'Maintain current practices'],
        shortTerm: ['Weekly scouting', 'Balanced fertilization'],
        longTerm: ['Soil health management', 'Crop rotation planning']
      };
    }

    // Find disease in database
    const diseaseData = this.diseaseInfo.diseases?.find(d => 
      d.class_name.toLowerCase().includes(disease.toLowerCase().replace(/ /g, '_'))
    );

    if (diseaseData && diseaseData.treatment) {
      return {
        immediate: [
          'Remove infected plant parts',
          'Isolate affected area if possible',
          ...(diseaseData.treatment.chemical?.slice(0, 2) || [])
        ],
        shortTerm: [
          ...(diseaseData.treatment.cultural?.slice(0, 3) || []),
          'Monitor disease progression daily'
        ],
        longTerm: [
          ...(diseaseData.prevention?.slice(0, 3) || []),
          'Implement crop rotation',
          'Improve field infrastructure'
        ],
        chemical: diseaseData.treatment.chemical || [],
        organic: diseaseData.treatment.organic || [],
        cultural: diseaseData.treatment.cultural || []
      };
    }

    return {
      immediate: ['Consult agricultural expert', 'Document symptoms'],
      shortTerm: ['Apply broad-spectrum treatment', 'Monitor closely'],
      longTerm: ['Improve field management', 'Use resistant varieties']
    };
  }

  /**
   * Get detailed disease information
   * @param {string} className - Class name
   * @returns {Object} Disease details
   */
  getDiseaseDetails(className) {
    const diseaseData = this.diseaseInfo.diseases?.find(d => 
      d.class_name === className || d.class_name.toLowerCase() === className.toLowerCase()
    );

    if (diseaseData) {
      return {
        commonName: diseaseData.common_name,
        scientificName: diseaseData.scientific_name,
        type: diseaseData.type,
        severity: diseaseData.severity,
        symptoms: diseaseData.symptoms,
        favorableConditions: diseaseData.favorable_conditions,
        treatment: diseaseData.treatment,
        prevention: diseaseData.prevention
      };
    }

    return null;
  }

  /**
   * Get top predictions
   * @param {Object} probabilities - Prediction probabilities
   * @returns {Array<Object>} Top predictions
   */
  getTopPredictions(probabilities) {
    if (!probabilities) return [];

    const predictions = Object.entries(probabilities)
      .map(([className, prob]) => {
        const parts = className.split('___');
        const crop = parts[0] || 'Unknown';
        const disease = parts.length > 1 ? parts.slice(1).join(' ').replace(/_/g, ' ') : 'Unknown';
        
        return {
          class: className,
          disease: disease,
          crop: crop,
          probability: prob,
          probabilityPercentage: Math.round(prob * 100)
        };
      })
      .sort((a, b) => b.probability - a.probability)
      .slice(0, 5);

    return predictions;
  }

  /**
   * Get mock prediction for testing (when ML API is offline)
   * @returns {Object} Mock prediction
   */
  getMockPrediction() {
    const mockClasses = [
      'Onion___Purple_blotch',
      'Onion___Downy_mildew',
      'Onion___Stemphylium_Leaf_Blight',
      'Onion___Botrytis_Leaf_Blight',
      'Onion___Iris_yellow_virus_augment',
      'Onion___Fusarium_D',
      'Onion___Rust',
      'Onion___Healthy_leaves',
      'Onion___Bulb_Rot',
      'Onion___Xanthomonas_Leaf_Blight'
    ];

    const selectedClass = mockClasses[Math.floor(Math.random() * mockClasses.length)];
    const confidence = 0.70 + Math.random() * 0.25; // 0.70 to 0.95

    // Create mock probabilities
    const probabilities = {};
    mockClasses.forEach(cls => {
      if (cls === selectedClass) {
        probabilities[cls] = confidence;
      } else {
        probabilities[cls] = (1 - confidence) / (mockClasses.length - 1) * Math.random();
      }
    });

    console.log(`🎭 Mock prediction: ${selectedClass} (${Math.round(confidence * 100)}%)`);

    return {
      class: selectedClass,
      confidence: confidence,
      probabilities: probabilities
    };
  }

  /**
   * Batch detect diseases from multiple images
   * @param {Array<string>} imagePaths - Array of image paths
   * @returns {Promise<Array<Object>>} Array of detection results
   */
  async batchDetect(imagePaths) {
    console.log(`📦 Starting batch detection for ${imagePaths.length} images`);
    const promises = imagePaths.map(path => this.detect(path));
    return Promise.all(promises);
  }

  /**
   * Get detection statistics
   * @param {Array<Object>} detections - Array of detection results
   * @returns {Object} Statistics
   */
  getStatistics(detections) {
    const total = detections.length;
    const successful = detections.filter(d => d.success).length;
    const healthy = detections.filter(d => d.success && d.prediction.isHealthy).length;
    const diseased = successful - healthy;

    const diseaseCount = {};
    detections.forEach(d => {
      if (d.success && !d.prediction.isHealthy) {
        const disease = d.prediction.disease;
        diseaseCount[disease] = (diseaseCount[disease] || 0) + 1;
      }
    });

    return {
      total,
      successful,
      failed: total - successful,
      healthy,
      diseased,
      healthyPercentage: Math.round((healthy / successful) * 100),
      diseasedPercentage: Math.round((diseased / successful) * 100),
      diseaseBreakdown: diseaseCount
    };
  }
}

module.exports = DiseaseDetection;
