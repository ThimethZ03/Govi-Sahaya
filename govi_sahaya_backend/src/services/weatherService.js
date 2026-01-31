const axios = require('axios');
const logger = require('../utils/logger');
const { WEATHER } = require('../config/constants');

// Weather API base configuration
const weatherAPI = axios.create({
  baseURL: WEATHER.BASE_URL,
  timeout: 10000,
});

// Get current weather data
exports.getWeatherData = async ({ city, lat, lon }) => {
  try {
    let url = '/weather';
    const params = {
      appid: WEATHER.API_KEY,
      units: 'metric',
    };

    if (city) {
      params.q = city;
    } else if (lat && lon) {
      params.lat = lat;
      params.lon = lon;
    } else {
      throw new Error('Either city name or coordinates must be provided');
    }

    const response = await weatherAPI.get(url, { params });
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
        windDirection: this.getWindDirection(data.wind.deg),
        cloudCover: data.clouds.all,
        visibility: data.visibility,
        uvIndex: data.uvi || 0,
        condition: data.weather[0].main,
        description: data.weather[0].description,
        icon: data.weather[0].icon,
      },
      sunrise: new Date(data.sys.sunrise * 1000),
      sunset: new Date(data.sys.sunset * 1000),
      dataSource: 'openweathermap',
      lastUpdated: new Date(),
      cacheExpiry: new Date(Date.now() + WEATHER.CACHE_DURATION),
    };
  } catch (error) {
    logger.error('Get weather data error:', error.message);
    throw new Error('Failed to fetch weather data');
  }
};

// Get weather forecast
exports.getWeatherForecast = async ({ city, lat, lon }, days = 7) => {
  try {
    const params = {
      appid: WEATHER.API_KEY,
      units: 'metric',
      cnt: days,
    };

    if (city) {
      params.q = city;
    } else if (lat && lon) {
      params.lat = lat;
      params.lon = lon;
    } else {
      throw new Error('Either city name or coordinates must be provided');
    }

    const response = await weatherAPI.get('/forecast/daily', { params });
    const data = response.data;

    const forecast = data.list.map((item) => ({
      date: new Date(item.dt * 1000),
      day: new Date(item.dt * 1000).toLocaleDateString('en-US', { weekday: 'short' }),
      tempMax: Math.round(item.temp.max),
      tempMin: Math.round(item.temp.min),
      humidity: item.humidity,
      precipitation: item.rain || 0,
      precipitationProbability: item.pop * 100,
      windSpeed: item.speed,
      condition: item.weather[0].main,
      description: item.weather[0].description,
      icon: item.weather[0].icon,
    }));

    return {
      location: {
        city: data.city.name,
        coordinates: {
          latitude: data.city.coord.lat,
          longitude: data.city.coord.lon,
        },
      },
      forecast,
      lastUpdated: new Date(),
    };
  } catch (error) {
    logger.error('Get weather forecast error:', error.message);
    throw new Error('Failed to fetch weather forecast');
  }
};

// Get weather alerts
exports.getWeatherAlerts = async ({ lat, lon }) => {
  try {
    if (!lat || !lon) {
      throw new Error('Coordinates are required for weather alerts');
    }

    const params = {
      lat,
      lon,
      appid: WEATHER.API_KEY,
    };

    const response = await weatherAPI.get('/onecall', { params });
    const alerts = response.data.alerts || [];

    return alerts.map((alert) => ({
      type: this.categorizeAlert(alert.event),
      severity: this.determineSeverity(alert.tags),
      title: alert.event,
      description: alert.description,
      startTime: new Date(alert.start * 1000),
      endTime: new Date(alert.end * 1000),
    }));
  } catch (error) {
    logger.error('Get weather alerts error:', error.message);
    return [];
  }
};

// Convert wind degree to direction
exports.getWindDirection = (degree) => {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  const index = Math.round(degree / 45) % 8;
  return directions[index];
};

// Categorize weather alert
exports.categorizeAlert = (eventName) => {
  const event = eventName.toLowerCase();
  
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

// Get agriculture-specific recommendations
exports.getAgricultureRecommendations = (weatherData) => {
  const recommendations = [];
  const temp = weatherData.current.temperature.value;
  const humidity = weatherData.current.humidity;
  const rain = weatherData.current.condition.toLowerCase().includes('rain');

  // Temperature-based recommendations
  if (temp > 35) {
    recommendations.push({
      type: 'warning',
      message: 'High temperature alert. Increase irrigation and provide shade for sensitive crops.',
    });
  } else if (temp < 10) {
    recommendations.push({
      type: 'warning',
      message: 'Low temperature alert. Protect frost-sensitive crops.',
    });
  }

  // Humidity-based recommendations
  if (humidity > 80) {
    recommendations.push({
      type: 'info',
      message: 'High humidity may increase disease risk. Monitor crops for fungal infections.',
    });
  }

  // Rain recommendations
  if (rain) {
    recommendations.push({
      type: 'info',
      message: 'Rainy conditions. Postpone spraying and check field drainage.',
    });
  }

  // General good conditions
  if (temp >= 20 && temp <= 30 && humidity >= 40 && humidity <= 70 && !rain) {
    recommendations.push({
      type: 'success',
      message: 'Favorable weather conditions for farming activities.',
    });
  }

  return recommendations;
};

// Calculate heat index
exports.calculateHeatIndex = (temperature, humidity) => {
  const T = temperature;
  const RH = humidity;

  const HI =
    -8.78469475556 +
    1.61139411 * T +
    2.33854883889 * RH +
    -0.14611605 * T * RH +
    -0.012308094 * T * T +
    -0.0164248277778 * RH * RH +
    0.002211732 * T * T * RH +
    0.00072546 * T * RH * RH +
    -0.000003582 * T * T * RH * RH;

  return Math.round(HI);
};

// Get moon phase (for agricultural planning)
exports.getMoonPhase = (date = new Date()) => {
  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  const day = date.getDate();

  let c = 0;
  let e = 0;
  let jd = 0;
  let b = 0;

  if (month < 3) {
    year--;
    month += 12;
  }

  ++month;
  c = 365.25 * year;
  e = 30.6 * month;
  jd = c + e + day - 694039.09;
  jd /= 29.5305882;
  b = parseInt(jd);
  jd -= b;
  b = Math.round(jd * 8);

  if (b >= 8) b = 0;

  const phases = [
    'New Moon',
    'Waxing Crescent',
    'First Quarter',
    'Waxing Gibbous',
    'Full Moon',
    'Waning Gibbous',
    'Last Quarter',
    'Waning Crescent',
  ];

  return phases[b];
};
