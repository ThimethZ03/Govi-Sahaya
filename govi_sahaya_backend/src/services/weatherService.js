const axios = require('axios');
const logger = require('../utils/logger');
const { WEATHER } = require('../config/constants');

// Weather API base configuration
const weatherAPI = axios.create({
  baseURL: WEATHER.BASE_URL,
  timeout: 10000,
});

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

const axios = require('axios');
const logger = require('../utils/logger');
const { WEATHER } = require('../config/constants');

const weatherAPI = axios.create({
  baseURL: WEATHER.BASE_URL,
  timeout: 10000,
});

function normalizeCity(city) {
  if (!city) return city;
  let c = String(city).trim();
  c = c.replace(/Sri-?Lanka/gi, 'Sri Lanka');
  if (c.toLowerCase().includes('sri lanka')) {
    const first = c.split(' ')[0];
    return `${first},LK`;
  }
  if (!c.includes(',') && c.length > 0) {
    return `${c},LK`;
  }
  return c;
}

exports.getWindDirection = (degree) => {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  const index = Math.round(Number(degree || 0) / 45) % 8;
  return directions[index];
};

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

exports.determineSeverity = (tags = []) => {
  if (tags.includes('Extreme')) return 'extreme';
  if (tags.includes('Severe')) return 'high';
  if (tags.includes('Moderate')) return 'moderate';
  return 'low';
};

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
        windSpeed: data.wind.speed,
        windDirection: exports.getWindDirection(data.wind.deg),
        cloudCover: data.clouds.all,
        visibility: data.visibility,
        uvIndex: 0,
        condition: data.weather?.[0]?.main || '',
        description: data.weather?.[0]?.description || '',
        icon: data.weather?.[0]?.icon || '',
      },
      sunrise: new Date(data.sys.sunrise * 1000),
      sunset: new Date(data.sys.sunset * 1000),
      dataSource: 'openweathermap',
      lastUpdated: new Date(),
      cacheExpiry: new Date(Date.now() + (WEATHER.CACHE_DURATION || 30 * 60 * 1000)),
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