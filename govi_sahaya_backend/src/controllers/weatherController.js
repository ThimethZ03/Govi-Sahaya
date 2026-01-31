const Weather = require('../models/Weather');
const { getWeatherData, getWeatherForecast } = require('../services/weatherService');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// @desc    Get current weather
// @route   GET /api/weather/current
// @access  Public
exports.getCurrentWeather = async (req, res) => {
  try {
    const { city, lat, lon } = req.query;

    if (!city && (!lat || !lon)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Please provide city name or coordinates (lat, lon)',
      });
    }

    // Check if weather data exists in cache
    const cacheExpiry = new Date(Date.now() - 30 * 60 * 1000); // 30 minutes
    let weather = null;

    if (city) {
      weather = await Weather.findOne({
        'location.city': city,
        lastUpdated: { $gte: cacheExpiry },
      });
    }

    // If not in cache or expired, fetch from API
    if (!weather) {
      const weatherData = await getWeatherData({ city, lat, lon });

      // Save to database
      weather = await Weather.findOneAndUpdate(
        { 'location.city': weatherData.location.city },
        weatherData,
        { upsert: true, new: true }
      );
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: weather,
    });
  } catch (error) {
    logger.error('Get current weather error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch weather data',
      error: error.message,
    });
  }
};

// @desc    Get weather forecast
// @route   GET /api/weather/forecast
// @access  Public
exports.getWeatherForecast = async (req, res) => {
  try {
    const { city, lat, lon, days } = req.query;

    if (!city && (!lat || !lon)) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Please provide city name or coordinates (lat, lon)',
      });
    }

    const forecastDays = parseInt(days) || 7;
    const forecast = await getWeatherForecast({ city, lat, lon }, forecastDays);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: forecast,
    });
  } catch (error) {
    logger.error('Get weather forecast error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch weather forecast',
      error: error.message,
    });
  }
};

// @desc    Get weather alerts
// @route   GET /api/weather/alerts
// @access  Public
exports.getWeatherAlerts = async (req, res) => {
  try {
    const { city, district } = req.query;

    const query = { 'alerts.0': { $exists: true } };
    if (city) query['location.city'] = city;
    if (district) query['location.district'] = district;

    const alerts = await Weather.find(query)
      .select('location alerts')
      .sort({ 'alerts.severity': -1 });

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: alerts,
    });
  } catch (error) {
    logger.error('Get weather alerts error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch weather alerts',
    });
  }
};

// @desc    Get weather by location
// @route   GET /api/weather/location
// @access  Public
exports.getWeatherByLocation = async (req, res) => {
  try {
    const { lat, lon, radius } = req.query;

    if (!lat || !lon) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Latitude and longitude are required',
      });
    }

    const radiusInMeters = parseInt(radius) || 50000; // Default 50km

    const weather = await Weather.find({
      'location.coordinates': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lon), parseFloat(lat)],
          },
          $maxDistance: radiusInMeters,
        },
      },
    }).limit(10);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: weather,
    });
  } catch (error) {
    logger.error('Get weather by location error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch weather data',
    });
  }
};

// @desc    Get popular cities weather
// @route   GET /api/weather/cities
// @access  Public
exports.getPopularCitiesWeather = async (req, res) => {
  try {
    const cities = [
      'Colombo',
      'Kandy',
      'Galle',
      'Jaffna',
      'Anuradhapura',
      'Trincomalee',
      'Batticaloa',
      'Kurunegala',
    ];

    const weatherPromises = cities.map((city) =>
      getWeatherData({ city }).catch((err) => {
        logger.warn(`Failed to fetch weather for ${city}:`, err);
        return null;
      })
    );

    const weatherData = await Promise.all(weatherPromises);
    const validWeather = weatherData.filter((w) => w !== null);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: validWeather,
    });
  } catch (error) {
    logger.error('Get popular cities weather error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch weather data',
    });
  }
};
