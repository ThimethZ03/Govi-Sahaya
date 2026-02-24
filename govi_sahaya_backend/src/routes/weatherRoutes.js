const express = require('express');
const router = express.Router();
const {
  getCurrentWeather,
  getWeatherForecast,
  getWeatherAlerts,
  getWeatherByLocation,
  getPopularCitiesWeather,
} = require('../controllers/weatherController');

// All routes are public
router.get('/current', getCurrentWeather);
router.get('/forecast', getWeatherForecast);
router.get('/alerts', getWeatherAlerts);
router.get('/location', getWeatherByLocation);
router.get('/cities', getPopularCitiesWeather);

module.exports = router;

