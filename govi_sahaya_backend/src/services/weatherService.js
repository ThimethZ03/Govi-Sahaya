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