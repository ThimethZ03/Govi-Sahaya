/**
 * Crop Recommendation System
 * Recommends suitable crops based on environmental conditions
 * Currently optimized for Sri Lankan agricultural context
 */
class CropRecommendation {
  constructor() {
    this.cropDatabase = this.loadCropDatabase();
  }

  /**
   * Load crop requirements database
   * @returns {Array<Object>} Crop database
   */
  loadCropDatabase() {
    return [
      {
        name: 'Rice',
        scientificName: 'Oryza sativa',
        category: 'cereal',
        optimalConditions: {
          temperature: { min: 20, max: 35, optimal: 25 },
          rainfall: { min: 1000, max: 2000, optimal: 1500 },
          humidity: { min: 60, max: 90, optimal: 75 },
          soilPH: { min: 5.5, max: 7.0, optimal: 6.0 },
          soilType: ['clay', 'loam', 'clay loam']
        },
        season: ['yala', 'maha'],
        growthDuration: 120,
        waterRequirement: 'high',
        suitableDistricts: ['Ampara', 'Polonnaruwa', 'Anuradhapura', 'Kurunegala', 'Hambantota'],
        economicValue: 'high',
        marketDemand: 'very high',
        nutritionalValue: {
          calories: 130,
          protein: 2.7,
          carbs: 28,
          fiber: 0.4
        }
      },
      {
        name: 'Onion',
        scientificName: 'Allium cepa',
        category: 'vegetable',
        optimalConditions: {
          temperature: { min: 15, max: 25, optimal: 20 },
          rainfall: { min: 500, max: 800, optimal: 650 },
          humidity: { min: 50, max: 70, optimal: 60 },
          soilPH: { min: 6.0, max: 7.0, optimal: 6.5 },
          soilType: ['loam', 'sandy loam', 'well-drained']
        },
        season: ['yala', 'maha', 'year-round with irrigation'],
        growthDuration: 120,
        waterRequirement: 'moderate',
        suitableDistricts: ['Jaffna', 'Hambantota', 'Puttalam', 'Mannar', 'Anuradhapura'],
        economicValue: 'high',
        marketDemand: 'high',
        nutritionalValue: {
          calories: 40,
          protein: 1.1,
          carbs: 9.3,
          fiber: 1.7
        }
      },
      {
        name: 'Tomato',
        scientificName: 'Solanum lycopersicum',
        category: 'vegetable',
        optimalConditions: {
          temperature: { min: 20, max: 30, optimal: 25 },
          rainfall: { min: 600, max: 1000, optimal: 800 },
          humidity: { min: 60, max: 80, optimal: 70 },
          soilPH: { min: 6.0, max: 6.8, optimal: 6.5 },
          soilType: ['loam', 'sandy loam', 'well-drained']
        },
        season: ['year-round'],
        growthDuration: 80,
        waterRequirement: 'moderate',
        suitableDistricts: ['Nuwara Eliya', 'Badulla', 'Matale', 'Kandy', 'Bandarawela'],
        economicValue: 'high',
        marketDemand: 'very high',
        nutritionalValue: {
          calories: 18,
          protein: 0.9,
          carbs: 3.9,
          fiber: 1.2
        }
      },
      {
        name: 'Potato',
        scientificName: 'Solanum tuberosum',
        category: 'vegetable',
        optimalConditions: {
          temperature: { min: 15, max: 20, optimal: 18 },
          rainfall: { min: 500, max: 700, optimal: 600 },
          humidity: { min: 70, max: 90, optimal: 80 },
          soilPH: { min: 5.0, max: 6.5, optimal: 5.5 },
          soilType: ['loam', 'sandy loam', 'well-drained']
        },
        season: ['maha'],
        growthDuration: 90,
        waterRequirement: 'high',
        suitableDistricts: ['Nuwara Eliya', 'Badulla', 'Welimada', 'Bandarawela'],
        economicValue: 'high',
        marketDemand: 'high',
        nutritionalValue: {
          calories: 77,
          protein: 2.0,
          carbs: 17,
          fiber: 2.1
        }
      },
      {
        name: 'Corn (Maize)',
        scientificName: 'Zea mays',
        category: 'cereal',
        optimalConditions: {
          temperature: { min: 21, max: 30, optimal: 25 },
          rainfall: { min: 600, max: 1000, optimal: 800 },
          humidity: { min: 60, max: 80, optimal: 70 },
          soilPH: { min: 5.8, max: 7.0, optimal: 6.5 },
          soilType: ['loam', 'clay loam', 'well-drained']
        },
        season: ['yala', 'maha'],
        growthDuration: 90,
        waterRequirement: 'moderate',
        suitableDistricts: ['Ampara', 'Monaragala', 'Kurunegala', 'Anuradhapura'],
        economicValue: 'moderate',
        marketDemand: 'high',
        nutritionalValue: {
          calories: 86,
          protein: 3.3,
          carbs: 19,
          fiber: 2.0
        }
      },
      {
        name: 'Chili (Pepper)',
        scientificName: 'Capsicum annuum',
        category: 'vegetable',
        optimalConditions: {
          temperature: { min: 20, max: 30, optimal: 25 },
          rainfall: { min: 600, max: 1250, optimal: 900 },
          humidity: { min: 50, max: 70, optimal: 60 },
          soilPH: { min: 6.0, max: 7.0, optimal: 6.5 },
          soilType: ['loam', 'sandy loam', 'well-drained']
        },
        season: ['yala', 'maha'],
        growthDuration: 120,
        waterRequirement: 'moderate',
        suitableDistricts: ['Matale', 'Kurunegala', 'Polonnaruwa', 'Anuradhapura'],
        economicValue: 'high',
        marketDemand: 'very high',
        nutritionalValue: {
          calories: 40,
          protein: 1.9,
          carbs: 8.8,
          fiber: 1.5
        }
      },
      {
        name: 'Carrot',
        scientificName: 'Daucus carota',
        category: 'vegetable',
        optimalConditions: {
          temperature: { min: 16, max: 21, optimal: 18 },
          rainfall: { min: 500, max: 750, optimal: 625 },
          humidity: { min: 60, max: 80, optimal: 70 },
          soilPH: { min: 5.5, max: 7.0, optimal: 6.0 },
          soilType: ['sandy loam', 'loam', 'deep well-drained']
        },
        season: ['maha'],
        growthDuration: 90,
        waterRequirement: 'moderate',
        suitableDistricts: ['Nuwara Eliya', 'Badulla', 'Kandy'],
        economicValue: 'moderate',
        marketDemand: 'high',
        nutritionalValue: {
          calories: 41,
          protein: 0.9,
          carbs: 10,
          fiber: 2.8
        }
      },
      {
        name: 'Cabbage',
        scientificName: 'Brassica oleracea var. capitata',
        category: 'vegetable',
        optimalConditions: {
          temperature: { min: 15, max: 20, optimal: 17 },
          rainfall: { min: 600, max: 800, optimal: 700 },
          humidity: { min: 60, max: 80, optimal: 70 },
          soilPH: { min: 6.0, max: 7.5, optimal: 6.5 },
          soilType: ['loam', 'clay loam', 'well-drained']
        },
        season: ['maha', 'year-round in highlands'],
        growthDuration: 75,
        waterRequirement: 'moderate to high',
        suitableDistricts: ['Nuwara Eliya', 'Badulla', 'Bandarawela', 'Welimada'],
        economicValue: 'moderate',
        marketDemand: 'high',
        nutritionalValue: {
          calories: 25,
          protein: 1.3,
          carbs: 5.8,
          fiber: 2.5
        }
      },
      {
        name: 'Beans',
        scientificName: 'Phaseolus vulgaris',
        category: 'vegetable',
        optimalConditions: {
          temperature: { min: 18, max: 25, optimal: 21 },
          rainfall: { min: 600, max: 1000, optimal: 800 },
          humidity: { min: 60, max: 80, optimal: 70 },
          soilPH: { min: 6.0, max: 7.0, optimal: 6.5 },
          soilType: ['loam', 'sandy loam', 'well-drained']
        },
        season: ['yala', 'maha'],
        growthDuration: 60,
        waterRequirement: 'moderate',
        suitableDistricts: ['Nuwara Eliya', 'Badulla', 'Matale', 'Kandy'],
        economicValue: 'moderate',
        marketDemand: 'high',
        nutritionalValue: {
          calories: 31,
          protein: 1.8,
          carbs: 7.0,
          fiber: 3.4
        }
      },
      {
        name: 'Banana',
        scientificName: 'Musa spp.',
        category: 'fruit',
        optimalConditions: {
          temperature: { min: 20, max: 35, optimal: 27 },
          rainfall: { min: 1000, max: 2500, optimal: 1750 },
          humidity: { min: 70, max: 90, optimal: 80 },
          soilPH: { min: 5.5, max: 7.0, optimal: 6.0 },
          soilType: ['loam', 'clay loam', 'deep well-drained']
        },
        season: ['year-round'],
        growthDuration: 365,
        waterRequirement: 'high',
        suitableDistricts: ['Gampaha', 'Kalutara', 'Kegalle', 'Kurunegala', 'Matale'],
        economicValue: 'high',
        marketDemand: 'very high',
        nutritionalValue: {
          calories: 89,
          protein: 1.1,
          carbs: 23,
          fiber: 2.6
        }
      }
    ];
  }

  /**
   * Recommend crops based on conditions
   * @param {Object} conditions - Environmental conditions
   * @returns {Array<Object>} Recommended crops with scores
   */
  recommend(conditions) {
    const {
      temperature,
      rainfall,
      humidity,
      soilPH,
      soilType,
      season,
      district,
      waterAvailability
    } = conditions;

    console.log('🌾 Calculating crop recommendations...');

    // Calculate suitability score for each crop
    const recommendations = this.cropDatabase.map(crop => {
      const score = this.calculateSuitabilityScore(crop, {
        temperature,
        rainfall,
        humidity,
        soilPH,
        soilType,
        season,
        district,
        waterAvailability
      });

      return {
        ...crop,
        suitabilityScore: score,
        matchDetails: this.getMatchDetails(crop, conditions)
      };
    });

    // Sort by suitability score (descending)
    recommendations.sort((a, b) => b.suitabilityScore - a.suitabilityScore);

    return recommendations.map((crop, index) => ({
      rank: index + 1,
      name: crop.name,
      scientificName: crop.scientificName,
      category: crop.category,
      suitabilityScore: Math.round(crop.suitabilityScore * 100),
      suitabilityLevel: this.getSuitabilityLevel(crop.suitabilityScore),
      growthDuration: crop.growthDuration,
      growthDurationText: this.getGrowthDurationText(crop.growthDuration),
      waterRequirement: crop.waterRequirement,
      optimalConditions: crop.optimalConditions,
      season: crop.season,
      suitableDistricts: crop.suitableDistricts,
      economicValue: crop.economicValue,
      marketDemand: crop.marketDemand,
      nutritionalValue: crop.nutritionalValue,
      matchDetails: crop.matchDetails,
      recommendations: this.getCropRecommendations(crop, conditions)
    }));
  }

  /**
   * Calculate suitability score
   * @param {Object} crop - Crop data
   * @param {Object} conditions - Environmental conditions
   * @returns {number} Suitability score (0-1)
   */
  calculateSuitabilityScore(crop, conditions) {
    let totalScore = 0;
    let totalWeight = 0;

    // Temperature score (weight: 0.25)
    if (conditions.temperature !== undefined && conditions.temperature !== null) {
      const tempScore = this.calculateParameterScore(
        conditions.temperature,
        crop.optimalConditions.temperature
      );
      totalScore += tempScore * 0.25;
      totalWeight += 0.25;
    }

    // Rainfall score (weight: 0.20)
    if (conditions.rainfall !== undefined && conditions.rainfall !== null) {
      const rainScore = this.calculateParameterScore(
        conditions.rainfall,
        crop.optimalConditions.rainfall
      );
      totalScore += rainScore * 0.20;
      totalWeight += 0.20;
    }

    // Humidity score (weight: 0.15)
    if (conditions.humidity !== undefined && conditions.humidity !== null) {
      const humidityScore = this.calculateParameterScore(
        conditions.humidity,
        crop.optimalConditions.humidity
      );
      totalScore += humidityScore * 0.15;
      totalWeight += 0.15;
    }

    // Soil pH score (weight: 0.20)
    if (conditions.soilPH !== undefined && conditions.soilPH !== null) {
      const phScore = this.calculateParameterScore(
        conditions.soilPH,
        crop.optimalConditions.soilPH
      );
      totalScore += phScore * 0.20;
      totalWeight += 0.20;
    }

    // Soil type score (weight: 0.10)
    if (conditions.soilType) {
      const soilScore = crop.optimalConditions.soilType.some(type => 
        type.toLowerCase().includes(conditions.soilType.toLowerCase()) ||
        conditions.soilType.toLowerCase().includes(type.toLowerCase())
      ) ? 1 : 0.5;
      totalScore += soilScore * 0.10;
      totalWeight += 0.10;
    }

    // District suitability (weight: 0.05)
    if (conditions.district && crop.suitableDistricts) {
      const districtScore = crop.suitableDistricts.some(d => 
        d.toLowerCase().includes(conditions.district.toLowerCase()) ||
        conditions.district.toLowerCase().includes(d.toLowerCase())
      ) ? 1 : 0.7;
      totalScore += districtScore * 0.05;
      totalWeight += 0.05;
    }

    // Water availability vs requirement (weight: 0.05)
    if (conditions.waterAvailability && crop.waterRequirement) {
      let waterScore = 0.5;
      if (conditions.waterAvailability === 'high' && crop.waterRequirement === 'high') waterScore = 1;
      else if (conditions.waterAvailability === 'moderate' && crop.waterRequirement === 'moderate') waterScore = 1;
      else if (conditions.waterAvailability === 'low' && crop.waterRequirement === 'low') waterScore = 1;
      else if (conditions.waterAvailability === 'high' && crop.waterRequirement !== 'high') waterScore = 0.9;
      
      totalScore += waterScore * 0.05;
      totalWeight += 0.05;
    }

    return totalWeight > 0 ? totalScore / totalWeight : 0;
  }

  /**
   * Calculate parameter score
   * @param {number} value - Actual value
   * @param {Object} range - Optimal range {min, max, optimal}
   * @returns {number} Score (0-1)
   */
  calculateParameterScore(value, range) {
    const { min, max, optimal } = range;

    if (value === optimal) return 1.0;
    
    if (value >= min && value <= max) {
      // Within acceptable range
      const distanceFromOptimal = Math.abs(value - optimal);
      const maxDistance = Math.max(optimal - min, max - optimal);
      return 1.0 - (distanceFromOptimal / maxDistance) * 0.3;
    } else if (value < min) {
      // Below minimum
      const deficit = min - value;
      const tolerance = min * 0.2; // 20% tolerance
      return Math.max(0, 0.7 - (deficit / tolerance) * 0.7);
    } else {
      // Above maximum
      const excess = value - max;
      const tolerance = max * 0.2; // 20% tolerance
      return Math.max(0, 0.7 - (excess / tolerance) * 0.7);
    }
  }

  /**
   * Get match details
   * @param {Object} crop - Crop data
   * @param {Object} conditions - Environmental conditions
   * @returns {Object} Match details
   */
  getMatchDetails(crop, conditions) {
    return {
      temperature: conditions.temperature !== undefined ? 
        this.getMatchStatus(conditions.temperature, crop.optimalConditions.temperature) : null,
      rainfall: conditions.rainfall !== undefined ? 
        this.getMatchStatus(conditions.rainfall, crop.optimalConditions.rainfall) : null,
      humidity: conditions.humidity !== undefined ? 
        this.getMatchStatus(conditions.humidity, crop.optimalConditions.humidity) : null,
      soilPH: conditions.soilPH !== undefined ? 
        this.getMatchStatus(conditions.soilPH, crop.optimalConditions.soilPH) : null,
      soilType: conditions.soilType ? 
        (crop.optimalConditions.soilType.some(type => 
          type.toLowerCase().includes(conditions.soilType.toLowerCase())
        ) ? 'excellent' : 'acceptable') : null,
      district: conditions.district && crop.suitableDistricts ?
        (crop.suitableDistricts.some(d => 
          d.toLowerCase().includes(conditions.district.toLowerCase())
        ) ? 'highly_suitable' : 'suitable') : null
    };
  }

  /**
   * Get match status
   * @param {number} value - Actual value
   * @param {Object} range - Optimal range
   * @returns {string} Match status
   */
  getMatchStatus(value, range) {
    const score = this.calculateParameterScore(value, range);
    
    if (score >= 0.9) return 'excellent';
    if (score >= 0.7) return 'good';
    if (score >= 0.5) return 'fair';
    return 'poor';
  }

  /**
   * Get suitability level
   * @param {number} score - Suitability score
   * @returns {string} Suitability level
   */
  getSuitabilityLevel(score) {
    if (score >= 0.85) return 'highly_suitable';
    if (score >= 0.70) return 'suitable';
    if (score >= 0.50) return 'moderately_suitable';
    if (score >= 0.30) return 'marginally_suitable';
    return 'not_suitable';
  }

  /**
   * Get growth duration text
   * @param {number} days - Growth duration in days
   * @returns {string} Human-readable duration
   */
  getGrowthDurationText(days) {
    if (days >= 365) return `${Math.floor(days / 365)} year(s)`;
    if (days >= 30) return `${Math.floor(days / 30)} month(s)`;
    return `${days} days`;
  }

  /**
   * Get crop-specific recommendations
   * @param {Object} crop - Crop data
   * @param {Object} conditions - Environmental conditions
   * @returns {Array<string>} Recommendations
   */
  getCropRecommendations(crop, conditions) {
    const recommendations = [];

    // Temperature recommendations
    if (conditions.temperature !== undefined) {
      if (conditions.temperature < crop.optimalConditions.temperature.min) {
        recommendations.push(`🌡️ Temperature is ${conditions.temperature}°C - Consider protective measures against cold`);
        recommendations.push('• Use mulching to protect soil temperature');
        recommendations.push('• Consider greenhouse or poly tunnel cultivation');
      } else if (conditions.temperature > crop.optimalConditions.temperature.max) {
        recommendations.push(`🌡️ Temperature is ${conditions.temperature}°C - Provide cooling measures`);
        recommendations.push('• Provide shade during peak heat hours');
        recommendations.push('• Increase irrigation frequency');
      } else {
        recommendations.push(`✅ Temperature (${conditions.temperature}°C) is suitable for ${crop.name}`);
      }
    }

    // Rainfall/Water recommendations
    if (crop.waterRequirement === 'high') {
      recommendations.push('💧 High water requirement crop');
      recommendations.push('• Ensure consistent irrigation schedule');
      recommendations.push('• Install drip irrigation for water efficiency');
      recommendations.push('• Monitor soil moisture regularly');
    } else if (crop.waterRequirement === 'moderate') {
      recommendations.push('💧 Moderate water requirement');
      recommendations.push('• Regular irrigation needed but avoid waterlogging');
      recommendations.push('• Mulching helps retain soil moisture');
    }

    // Soil recommendations
    if (conditions.soilPH !== undefined) {
      if (conditions.soilPH < crop.optimalConditions.soilPH.min) {
        recommendations.push(`📊 Soil pH (${conditions.soilPH}) is too acidic`);
        recommendations.push('• Add agricultural lime to increase soil pH');
        recommendations.push('• Apply dolomite limestone if magnesium is also low');
      } else if (conditions.soilPH > crop.optimalConditions.soilPH.max) {
        recommendations.push(`📊 Soil pH (${conditions.soilPH}) is too alkaline`);
        recommendations.push('• Add sulfur or organic matter to lower soil pH');
        recommendations.push('• Use acidifying fertilizers like ammonium sulfate');
      } else {
        recommendations.push(`✅ Soil pH (${conditions.soilPH}) is suitable`);
      }
    }

    // Fertilization recommendations
    recommendations.push('🌱 Fertilization schedule:');
    if (crop.name === 'Rice') {
      recommendations.push('• Basal: Urea 50kg, TSP 50kg, MOP 25kg per acre');
      recommendations.push('• Top dressing: Urea 75kg (2-3 splits) per acre');
    } else if (crop.name === 'Onion') {
      recommendations.push('• Basal: Well-decomposed compost 5-7 tons per acre');
      recommendations.push('• NPK 17:17:17 @ 100kg per acre');
      recommendations.push('• Top dressing at 30 and 60 days');
    } else if (crop.name === 'Tomato') {
      recommendations.push('• Basal: Compost 3-5 tons + NPK per acre');
      recommendations.push('• Weekly fertigation during growth stage');
    } else {
      recommendations.push('• Apply balanced NPK fertilizer as per soil test');
      recommendations.push('• Use organic manure for soil health');
    }

    // General recommendations
    recommendations.push(`⏱️ Expected harvest: ${crop.growthDuration} days after planting`);
    recommendations.push('👀 Monitor for common pests and diseases');
    recommendations.push('📚 Consult agricultural extension officers for detailed guidance');
    
    // Economic information
    if (crop.economicValue === 'high' && crop.marketDemand === 'very high') {
      recommendations.push('💰 High economic value crop with strong market demand');
    } else if (crop.economicValue === 'high') {
      recommendations.push('💰 Good economic returns expected');
    }

    // District-specific advice
    if (conditions.district && crop.suitableDistricts) {
      const isHighlySuitable = crop.suitableDistricts.some(d => 
        d.toLowerCase().includes(conditions.district.toLowerCase())
      );
      if (isHighlySuitable) {
        recommendations.push(`📍 ${crop.name} is highly suitable for ${conditions.district} district`);
      }
    }

    return recommendations;
  }

  /**
   * Get crop by name
   * @param {string} cropName - Crop name
   * @returns {Object} Crop data
   */
  getCropByName(cropName) {
    return this.cropDatabase.find(crop => 
      crop.name.toLowerCase() === cropName.toLowerCase()
    );
  }

  /**
   * Get crops by category
   * @param {string} category - Category (vegetable, fruit, cereal)
   * @returns {Array<Object>} Crops in category
   */
  getCropsByCategory(category) {
    return this.cropDatabase.filter(crop => 
      crop.category.toLowerCase() === category.toLowerCase()
    );
  }

  /**
   * Get seasonal crops
   * @param {string} season - Season (yala, maha, year-round)
   * @returns {Array<Object>} Seasonal crops
   */
  getSeasonalCrops(season) {
    return this.cropDatabase.filter(crop => 
      crop.season.some(s => s.toLowerCase().includes(season.toLowerCase()))
    );
  }
}

module.exports = CropRecommendation;
