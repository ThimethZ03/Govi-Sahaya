const Weather = require('../models/Weather');
const Notification = require('../models/Notification');
const {
  getWeatherData,
  getWeatherForecast,
  getWeatherAlerts: fetchWeatherAlerts,
} = require('../services/weatherService');
const notificationService = require('../services/notificationService');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// ── Sri Lanka time helpers ────────────────────────────────────────────────────
const SL_OFFSET_MINUTES = 330;

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

function normalizeCityForCache(city) {
  if (!city) return city;
  let c = String(city).trim();
  c = c.replace(/Sri-?Lanka/gi, '').trim();
  if (c.includes(',')) c = c.split(',')[0].trim();
  if (c.includes(' ')) c = c.split(' ')[0].trim();
  return c;
}

function toFlutterWeather(weatherDoc) {
  const w = weatherDoc?.toObject ? weatherDoc.toObject() : weatherDoc;

  const city    = w?.location?.city || 'Colombo';
  const current = w?.current || {};
  const tempObj = current.temperature || {};

  const visibilityKm =
    current.visibility != null
      ? Math.round(Number(current.visibility) / 1000)
      : 0;

  const windKmh =
    current.windSpeed != null
      ? Math.round(Number(current.windSpeed) * 3.6 * 10) / 10
      : 0;

  const firstForecast =
    w?.forecast && w.forecast.length > 0 ? w.forecast[0] : null;
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
    humidity:     Number(current.humidity ?? 0),
    wind_speed:   windKmh,
    uv_index:     Number(current.uvIndex ?? 0),
    visibility:   visibilityKm,
    sunrise_time: w?.sunrise ? formatTimeSriLanka(w.sunrise) : '',
    sunset_time:  w?.sunset  ? formatTimeSriLanka(w.sunset)  : '',
    forecast: (w?.forecast || []).map((f) => ({
      day:         f.day || 'Day',
      date:        toSriLankaISO(f.date ? new Date(f.date) : new Date()),
      temperature: Number(f.tempMax ?? f.tempMin ?? 0),
      condition:   f.condition ?? '',
      icon:        f.icon ? f.icon : '🌤️',
    })),
  };
}

// ── Dedup: only send each alert title once per user per day ───────────────────
async function alertAlreadySentToday(userId, title) {
  try {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const existing = await Notification.findOne({
      user:      userId,
      title,
      createdAt: { $gte: startOfDay },
    });

    return !!existing;
  } catch (e) {
    logger.error('alertAlreadySentToday error:', e);
    return false;
  }
}

// ── Build alerts — Sri Lanka realistic thresholds ─────────────────────────────
function buildWeatherAlerts(current, city) {
  const tempVal   = current.temperature?.value ?? 0;
  const humidity  = current.humidity  ?? 0;
  const windSpeed = current.windSpeed ?? 0; // m/s
  const uvIndex   = current.uvIndex   ?? 0;
  const condition = (current.condition ?? '').toLowerCase();
  const alerts    = [];

  // ── Debug log so you can see exact values in nodemon ─────────────
  logger.info(
    `🌤️ Alert check | city=${city} | condition="${condition}" | ` +
    `temp=${tempVal}°C | humidity=${humidity}% | ` +
    `wind=${windSpeed}m/s | uv=${uvIndex}`
  );

  // ── Condition-based (always fires for any weather type) ───────────
  if (condition.includes('thunderstorm') || condition.includes('storm')) {
    alerts.push({
      title:    '⛈️ Thunderstorm Warning',
      message:  `Thunderstorm detected in ${city}. Avoid fieldwork and protect crops immediately.`,
      priority: 'urgent',
    });
  } else if (condition.includes('rain') || condition.includes('drizzle')) {
    alerts.push({
      title:    '🌧️ Rain Alert',
      message:  `Rainfall expected in ${city}. Check drainage systems and protect sensitive crops.`,
      priority: 'high',
    });
  } else if (condition.includes('cloud')) {
    alerts.push({
      title:    '☁️ Cloudy Weather Today',
      message:  `Overcast skies in ${city}. Good conditions for planting and light fieldwork.`,
      priority: 'low',
    });
  } else if (condition.includes('clear') || condition.includes('sun')) {
    alerts.push({
      title:    '☀️ Clear Weather Today',
      message:  `Clear skies in ${city}. Great day for harvesting and field activities.`,
      priority: 'low',
    });
  } else if (condition.includes('mist') || condition.includes('fog') || condition.includes('haze')) {
    alerts.push({
      title:    '🌫️ Low Visibility Warning',
      message:  `Mist or fog in ${city}. Be cautious during early morning fieldwork.`,
      priority: 'low',
    });
  } else {
    // ✅ Fallback — always send a daily weather summary
    alerts.push({
      title:    '🌤️ Daily Weather Update',
      message:  `Today's weather in ${city}: ${current.condition || 'Partly cloudy'}, ${tempVal}°C. Plan your fieldwork accordingly.`,
      priority: 'low',
    });
  }

  // ── Threshold-based (Sri Lanka realistic values) ──────────────────
  if (tempVal >= 33) {
    alerts.push({
      title:    '🌡️ High Temperature Alert',
      message:  `Temperature is ${tempVal}°C in ${city}. Ensure crops are well irrigated.`,
      priority: 'medium',
    });
  }

  if (humidity >= 80) {
    alerts.push({
      title:    '💧 High Humidity Alert',
      message:  `Humidity is ${humidity}% in ${city}. Monitor crops closely for fungal disease risk.`,
      priority: 'medium',
    });
  }

  if (windSpeed >= 8) {
    alerts.push({
      title:    '💨 Windy Conditions Alert',
      message:  `Wind speed is ${Math.round(windSpeed * 3.6)} km/h in ${city}. Secure lightweight crop structures.`,
      priority: 'medium',
    });
  }

  if (uvIndex >= 6) {
    alerts.push({
      title:    '🔆 High UV Index Alert',
      message:  `UV index is ${uvIndex} in ${city}. Use sun protection during outdoor fieldwork.`,
      priority: 'low',
    });
  }

  logger.info(`🔔 Alerts to send: ${alerts.length} → [${alerts.map((a) => a.title).join(' | ')}]`);

  return alerts.map((a) => ({
    ...a,
    data: { city, temperature: tempVal, humidity, windSpeed, uvIndex, condition },
    sendVia: { push: true, email: false, sms: a.priority === 'urgent' },
  }));
}

// ── Main alert dispatcher ─────────────────────────────────────────────────────
async function checkAndSendWeatherAlert(weatherDoc, userId = null) {
  try {
    const w       = weatherDoc?.toObject ? weatherDoc.toObject() : weatherDoc;
    const current = w?.current || {};
    const city    = w?.location?.city ?? 'your area';
    const alerts  = buildWeatherAlerts(current, city);

    if (alerts.length === 0) return;

    if (userId) {
      // ── Logged-in user: personal alert, dedup per day ─────────────
      for (const alert of alerts) {
        const notificationData = {
          type:     'weather_alert',
          title:    alert.title,
          message:  alert.message,
          priority: alert.priority,
          data:     alert.data,
          sendVia:  alert.sendVia,
        };

        const alreadySent = await alertAlreadySentToday(userId, alert.title);
        if (!alreadySent) {
          await notificationService.createNotification(userId, notificationData);
          logger.info(`✅ Weather alert sent → user ${userId}: "${alert.title}"`);
        } else {
          logger.info(`⏭️ Skipped (already sent today): "${alert.title}"`);
        }
      }
    } else {
      // ── Public fetch: broadcast to all farmers in this city ────────
      const User  = require('../models/User');
      const users = await User.find({
        role:     'farmer',
        isActive: true,
        $or: [
          { 'location.city':     new RegExp(city, 'i') },
          { 'location.district': new RegExp(city, 'i') },
        ],
      }).select('_id');

      logger.info(`📢 Broadcasting to ${users.length} farmers in ${city}`);

      for (const alert of alerts) {
        const notificationData = {
          type:     'weather_alert',
          title:    alert.title,
          message:  alert.message,
          priority: alert.priority,
          data:     alert.data,
          sendVia:  alert.sendVia,
        };

        for (const user of users) {
          const alreadySent = await alertAlreadySentToday(user._id, alert.title);
          if (!alreadySent) {
            await notificationService.createNotification(user._id, notificationData);
          }
        }

        logger.info(`✅ Broadcast done: "${alert.title}" → ${users.length} users`);
      }
    }
  } catch (error) {
    logger.error('checkAndSendWeatherAlert error:', error);
  }
}

// ── Controllers ───────────────────────────────────────────────────────────────

// @desc    Get current weather
// @route   GET /api/v1/weather/current
// @access  Public (optionalAuth)
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
        lastUpdated:     { $gte: cacheExpiry },
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

    // ✅ ALWAYS check alerts on every request (dedup prevents spam)
    // Only sends if user is logged in (optionalAuth provides req.user)
    if (req.user?.id) {
      logger.info(`🔔 Checking weather alerts for user: ${req.user.id}`);
      await checkAndSendWeatherAlert(weather, req.user.id);
    } else {
      logger.info('⚠️ No user attached — skipping personal weather alert');
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
    const forecast     = await getWeatherForecast({ city, lat, lon }, forecastDays);

    return res.status(HTTP_STATUS.OK).json({
      location: forecast.location?.city || city || 'Colombo',
      forecast: (forecast.forecast || []).map((f) => ({
        day:         f.day || 'Day',
        date:        toSriLankaISO(f.date ? new Date(f.date) : new Date()),
        temperature: Number(f.tempMax ?? f.tempMin ?? 0),
        condition:   f.condition ?? '',
        icon:        f.icon ? f.icon : '🌤️',
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

// @desc    Get weather alerts
// @route   GET /api/v1/weather/alerts
// @access  Public
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

// @desc    Get weather by coordinates
// @route   GET /api/v1/weather/location
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

    const radiusInMeters = parseInt(radius) || 50000;

    const weather = await Weather.find({
      'location.coordinates': {
        $near: {
          $geometry: {
            type:        'Point',
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

// @desc    Get popular Sri Lanka cities weather
// @route   GET /api/v1/weather/cities
// @access  Public
exports.getPopularCitiesWeather = async (req, res) => {
  try {
    const cities = [
      'Colombo', 'Kandy', 'Galle', 'Jaffna',
      'Anuradhapura', 'Trincomalee', 'Batticaloa', 'Kurunegala',
    ];

    const weatherPromises = cities.map((c) =>
      getWeatherData({ city: c }).catch((err) => {
        logger.warn(`Failed to fetch weather for ${c}:`, err);
        return null;
      })
    );

    const weatherData  = await Promise.all(weatherPromises);
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

// ── TEMP TEST ROUTE — remove after confirming notifications work ──────────────
const { protect } = require('../middleware/authMiddleware');
exports.testWeatherAlert = async (req, res) => {
  try {
    await notificationService.createNotification(req.user.id, {
      type:     'weather_alert',
      title:    '🌧️ Rain Alert',
      message:  'Test: Heavy rain expected in Colombo. Check drainage and protect crops.',
      priority: 'high',
      data:     { city: 'Colombo', condition: 'rain' },
      sendVia:  { push: true, email: false, sms: false },
    });

    res.json({ success: true, message: '✅ Test notification created! Check your notifications screen.' });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
};
