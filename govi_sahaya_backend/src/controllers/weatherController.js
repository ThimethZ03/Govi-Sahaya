const Weather = require('../models/Weather');
const {
  getWeatherData,
  getWeatherForecast,
  getWeatherAlerts: fetchWeatherAlerts,
} = require('../services/weatherService');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// ✅ Sri Lanka time offset +05:30
const SL_OFFSET_MINUTES = 330;

// ✅ Convert Date -> ISO with +05:30 (not Z)
function toSriLankaISO(date = new Date()) {
  const d = new Date(date);
  const shifted = new Date(d.getTime() + SL_OFFSET_MINUTES * 60 * 1000);
  return shifted.toISOString().replace('Z', '+05:30');
}

function formatTimeSriLanka(date) {
  if (!date) return '';
  const d = new Date(date);
  const shifted = new Date(d.getTime() + SL_OFFSET_MINUTES * 60 * 1000);
  return shifted.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

// ✅ Make cache lookup stable for "Colombo Sri-Lanka" etc.
function normalizeCityForCache(city) {
  if (!city) return city;
  let c = String(city).trim();
  c = c.replace(/Sri-?Lanka/gi, '').trim();
  if (c.includes(',')) c = c.split(',')[0].trim();
  if (c.includes(' ')) c = c.split(' ')[0].trim();
  return c;
}

// ✅ Convert DB document to Flutter-friendly JSON
function toFlutterWeather(weatherDoc) {
  const w = weatherDoc?.toObject ? weatherDoc.toObject() : weatherDoc;

  const city = w?.location?.city || 'Colombo';
  const current = w?.current || {};
  const tempObj = current.temperature || {};

  const visibilityKm =
    current.visibility != null ? Math.round(Number(current.visibility) / 1000) : 0;

  // wind m/s -> km/h
  const windKmh =
    current.windSpeed != null ? Math.round(Number(current.windSpeed) * 3.6 * 10) / 10 : 0;

  const firstForecast = (w?.forecast && w.forecast.length > 0) ? w.forecast[0] : null;

  const baseDate = w?.lastUpdated ? new Date(w.lastUpdated) : new Date();

  return {
    location: city,
    date: toSriLankaISO(baseDate),

    temperature: Number(tempObj.value ?? 0),
    min_temp: Number(firstForecast?.tempMin ?? tempObj.value ?? 0),
    max_temp: Number(firstForecast?.tempMax ?? tempObj.value ?? 0),

    condition: current.condition ?? '',
    description:
      current.feelsLike != null
        ? `Feels like ${current.feelsLike}°`
        : (current.description ?? ''),

    humidity: Number(current.humidity ?? 0),
    wind_speed: windKmh,
    uv_index: Number(current.uvIndex ?? 0),
    visibility: visibilityKm,

    sunrise_time: w?.sunrise ? formatTimeSriLanka(w.sunrise) : '',
    sunset_time: w?.sunset ? formatTimeSriLanka(w.sunset) : '',

    forecast: (w?.forecast || []).map((f) => ({
      day: f.day || 'Day',
      date: toSriLankaISO(f.date ? new Date(f.date) : new Date()),
      temperature: Number(f.tempMax ?? f.tempMin ?? 0),
      condition: f.condition ?? '',
      icon: f.icon ? f.icon : '🌤️',
    })),
  };
}

// @desc    Get current weather
// @route   GET /api/v1/weather/current
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

    const cacheExpiry = new Date(Date.now() - 30 * 60 * 1000);
    let weather = null;

    if (city) {
      const cacheCity = normalizeCityForCache(city);
      weather = await Weather.findOne({
        'location.city': new RegExp(`^${cacheCity}$`, 'i'),
        lastUpdated: { $gte: cacheExpiry },
      });
    }

    if (!weather) {
      const weatherData = await getWeatherData({ city, lat, lon });

      let forecastData = null;
      try {
        forecastData = await getWeatherForecast(
          { city: weatherData.location.city, lat, lon },
          5
        );
      } catch (e) {
        forecastData = null;
      }

      const merged = {
        ...weatherData,
        forecast: forecastData?.forecast || [],
      };

      weather = await Weather.findOneAndUpdate(
        { 'location.city': weatherData.location.city },
        merged,
        { upsert: true, new: true }
      );
    }

    return res.status(HTTP_STATUS.OK).json(toFlutterWeather(weather));
  } catch (error) {
    logger.error('Get current weather error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch weather data',
      error: error.message,
    });
  }
};

// @desc    Get weather forecast
// @route   GET /api/v1/weather/forecast
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

    const forecastDays = parseInt(days) || 5;
    const forecast = await getWeatherForecast({ city, lat, lon }, forecastDays);

    return res.status(HTTP_STATUS.OK).json({
      location: forecast.location?.city || city || 'Colombo',
      forecast: (forecast.forecast || []).map((f) => ({
        day: f.day || 'Day',
        date: toSriLankaISO(f.date ? new Date(f.date) : new Date()),
        temperature: Number(f.tempMax ?? f.tempMin ?? 0),
        condition: f.condition ?? '',
        icon: f.icon ? f.icon : '🌤️',
      })),
    });
  } catch (error) {
    logger.error('Get weather forecast error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch weather forecast',
      error: error.message,
    });
  }
};

// ✅ REQUIRED by your routes: /alerts
exports.getWeatherAlerts = async (req, res) => {
  try {
    const { lat, lon } = req.query;

    if (!lat || !lon) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Coordinates are required (lat, lon)',
      });
    }

    const alerts = await fetchWeatherAlerts({ lat, lon });

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: alerts,
    });
  } catch (error) {
    logger.error('Get weather alerts error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch weather alerts',
      error: error.message,
    });
  }
};

// ✅ REQUIRED by your routes: /location
exports.getWeatherByLocation = async (req, res) => {
  try {
    const { lat, lon, radius } = req.query;

    if (!lat || !lon) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Latitude and longitude are required',
      });
    }

    const radiusInMeters = parseInt(radius) || 50000;

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

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: weather,
    });
  } catch (error) {
    logger.error('Get weather by location error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch weather data',
      error: error.message,
    });
  }
};

// ✅ REQUIRED by your routes: /cities
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

    const weatherPromises = cities.map((c) =>
      getWeatherData({ city: c }).catch((err) => {
        logger.warn(`Failed to fetch weather for ${c}:`, err);
        return null;
      })
    );

    const weatherData = await Promise.all(weatherPromises);
    const validWeather = weatherData.filter((w) => w !== null);

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      data: validWeather,
    });
  } catch (error) {
    logger.error('Get popular cities weather error:', error);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch weather data',
      error: error.message,
    });
  }
};
