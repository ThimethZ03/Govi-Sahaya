const express = require('express');
const router  = express.Router();
const {
  getCurrentWeather,
  getWeatherForecast,
  getWeatherAlerts,
  getWeatherByLocation,
  getPopularCitiesWeather,
  testWeatherAlert,        // ✅ TEMP TEST
} = require('../controllers/weatherController');
const { optionalAuth, protect } = require('../middleware/authMiddleware');

router.get('/current',    optionalAuth, getCurrentWeather);
router.get('/forecast',   getWeatherForecast);
router.get('/alerts',     getWeatherAlerts);
router.get('/location',   getWeatherByLocation);
router.get('/cities',     getPopularCitiesWeather);
router.get('/test-alert', protect, testWeatherAlert); // ✅ TEMP TEST — remove after confirming

module.exports = router;
