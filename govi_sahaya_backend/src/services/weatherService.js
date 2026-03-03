const axios = require('axios');
const logger = require('../utils/logger');
const { WEATHER } = require('../config/constants');

// Weather API base configuration
const weatherAPI = axios.create({
  baseURL: WEATHER.BASE_URL,
  timeout: 10000,
});

// ── Sri Lanka time helper ─────────────────────────────────────────────────────
const SL_OFFSET_MINUTES = 330;

// ✅ FIXED: uses getUTCHours/getUTCMinutes after manual shift
// to avoid server timezone being applied on top of the +330 min offset
function formatTimeSriLanka(date) {
  if (!date) return '';
  const d = new Date(date);
  const shifted = new Date(d.getTime() + SL_OFFSET_MINUTES * 60 * 1000);
  const h24 = shifted.getUTCHours();
  const min = String(shifted.getUTCMinutes()).padStart(2, '0');
  const ampm = h24 >= 12 ? 'PM' : 'AM';
  const h12 = h24 % 12 === 0 ? 12 : h24 % 12;
  return `${h12}:${min} ${ampm}`;
}

// ✅ Normalize city for OpenWeather (your app sends "Colombo Sri-Lanka")
function normalizeCity(city) {
  if (!city) return city;

  let c = String(city).trim();

  // "Colombo Sri-Lanka" / "Colombo Sri Lanka" -> "Colombo,LK"
  c = c.replace(/Sri-?Lanka/gi, 'Sri Lanka');

  if (c.toLowerCase().includes('sri lanka')) {
    const first = c.split(' ')[0];
    return `${first},LK`;
  }

  // If user typed "Colombo" -> add country
  if (!c.includes(',') && c.length > 0) {
    return `${c},LK`;
  }

  return c;
}

// Convert wind degree to direction
exports.getWindDirection = (degree) => {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  const index = Math.round(Number(degree || 0) / 45) % 8;
  return directions[index];
};

// Categorize weather alert
exports.categorizeAlert = (eventName) => {
  const event = (eventName || '').toLowerCase();
  if (event.includes('storm') || event.includes('thunder')) return 'storm';
  if (event.includes('rain') || event.includes('shower')) return 'rain';
  if (event.includes('flood')) return 'flood';
  if (event.includes('drought')) return 'drought';
  if (event.includes('heat')) return 'heatwave';
  if (event.includes('cold') || event.includes('freeze')) return 'coldwave';
  return 'general';
};

// Determine alert severity
exports.determineSeverity = (tags = []) => {
  if (tags.includes('Extreme')) return 'extreme';
  if (tags.includes('Severe')) return 'high';
  if (tags.includes('Moderate')) return 'moderate';
  return 'low';
};

// ── Export formatTimeSriLanka so weatherController can use it ─────────────────
exports.formatTimeSriLanka = formatTimeSriLanka;

// ✅ Get current weather data
exports.getWeatherData = async ({ city, lat, lon }) => {
  try {
    const params = {
      appid: WEATHER.API_KEY,
      units: 'metric',
    };

    if (!WEATHER.API_KEY) {
      throw new Error('WEATHER.API_KEY is missing. Check your .env / constants.');
    }

    if (city) {
      params.q = normalizeCity(city);
    } else if (lat && lon) {
      params.lat = lat;
      params.lon = lon;
    } else {
      throw new Error('Either city name or coordinates must be provided');
    }

    const response = await weatherAPI.get('/weather', { params });
    const data = response.data;

    return {
      location: {
        city: data.name,
        coordinates: {
          latitude: data.coord.lat,
          longitude: data.coord.lon,
        },
      },
      current: {
        temperature: {
          value: Math.round(data.main.temp),
          unit: 'celsius',
        },
        feelsLike: Math.round(data.main.feels_like),
        humidity: data.main.humidity,
        pressure: data.main.pressure,
        windSpeed: data.wind.speed, // m/s
        windDirection: exports.getWindDirection(data.wind.deg),
        cloudCover: data.clouds.all,
        visibility: data.visibility, // meters
        uvIndex: 0,
        condition: data.weather?.[0]?.main || '',
        description: data.weather?.[0]?.description || '',
        icon: data.weather?.[0]?.icon || '',
      },
      // ✅ Store raw UTC Date — formatTimeSriLanka() called in controller
      sunrise: new Date(data.sys.sunrise * 1000),
      sunset: new Date(data.sys.sunset * 1000),
      dataSource: 'openweathermap',
      lastUpdated: new Date(),
      cacheExpiry: new Date(
        Date.now() + (WEATHER.CACHE_DURATION || 30 * 60 * 1000)
      ),
    };
  } catch (error) {
    logger.error('Get weather data error:', {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data,
      baseURL: WEATHER.BASE_URL,
      hasApiKey: Boolean(WEATHER.API_KEY),
    });
    throw new Error('Failed to fetch weather data');
  }
};

// ✅ Forecast using FREE endpoint: /forecast (3-hour data) -> convert to daily
exports.getWeatherForecast = async ({ city, lat, lon }, days = 5) => {
  try {
    const params = {
      appid: WEATHER.API_KEY,
      units: 'metric',
    };

    if (!WEATHER.API_KEY) {
      throw new Error('WEATHER.API_KEY is missing. Check your .env / constants.');
    }

    if (city) {
      params.q = normalizeCity(city);
    } else if (lat && lon) {
      params.lat = lat;
      params.lon = lon;
    } else {
      throw new Error('Either city name or coordinates must be provided');
    }

    const response = await weatherAPI.get('/forecast', { params });
    const data = response.data;

    // Group by day (YYYY-MM-DD)
    const byDay = {};
    for (const item of data.list || []) {
      const dt = new Date(item.dt * 1000);
      const dayKey = dt.toISOString().slice(0, 10);

      if (!byDay[dayKey]) {
        byDay[dayKey] = {
          date: dt,
          tempMax: -999,
          tempMin: 999,
          humidity: item.main.humidity,
          windSpeed: item.wind.speed,
          condition: item.weather?.[0]?.main || '',
          description: item.weather?.[0]?.description || '',
          icon: item.weather?.[0]?.icon || '',
        };
      }

      byDay[dayKey].tempMax = Math.max(
        byDay[dayKey].tempMax,
        item.main.temp_max
      );
      byDay[dayKey].tempMin = Math.min(
        byDay[dayKey].tempMin,
        item.main.temp_min
      );
    }

    const keys = Object.keys(byDay).sort().slice(0, days);
    const forecast = keys.map((k) => {
      const f = byDay[k];
      return {
        date: f.date,
        // ✅ Use UTC day name to avoid server TZ shifting the date
        day: new Date(f.date).toLocaleDateString('en-US', {
          weekday: 'short',
          timeZone: 'Asia/Colombo',
        }),
        tempMax: Math.round(f.tempMax),
        tempMin: Math.round(f.tempMin),
        humidity: f.humidity,
        precipitation: 0,
        precipitationProbability: 0,
        windSpeed: f.windSpeed,
        condition: f.condition,
        description: f.description,
        icon: f.icon,
      };
    });

    return {
      location: {
        city: data.city?.name || city || 'Colombo',
        coordinates: {
          latitude: data.city?.coord?.lat,
          longitude: data.city?.coord?.lon,
        },
      },
      forecast,
      lastUpdated: new Date(),
    };
  } catch (error) {
    logger.error('Get weather forecast error:', {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data,
      baseURL: WEATHER.BASE_URL,
      hasApiKey: Boolean(WEATHER.API_KEY),
    });
    throw new Error('Failed to fetch weather forecast');
  }
};

// Get weather alerts (optional)
exports.getWeatherAlerts = async ({ lat, lon }) => {
  try {
    if (!lat || !lon)
      throw new Error('Coordinates are required for weather alerts');

    const params = { lat, lon, appid: WEATHER.API_KEY };
    const response = await weatherAPI.get('/onecall', { params });

    const alerts = response.data.alerts || [];
    return alerts.map((alert) => ({
      type: exports.categorizeAlert(alert.event),
      severity: exports.determineSeverity(alert.tags),
      title: alert.event,
      description: alert.description,
      startTime: new Date(alert.start * 1000),
      endTime: new Date(alert.end * 1000),
    }));
  } catch (error) {
    logger.error('Get weather alerts error:', {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data,
    });
    return [];
  }
};
