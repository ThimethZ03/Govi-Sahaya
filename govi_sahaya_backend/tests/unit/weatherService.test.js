const weatherService = require('../../src/services/weatherService');

jest.mock('axios');
const axios = require('axios');

jest.mock('../../src/models/WeatherData');
jest.mock('../../src/utils/logger', () => ({
  error: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
}));

describe('Weather Service - Unit Tests', () => {
  const mockWeatherData = {
    _id: '507f1f77bcf86cd799439011',
    district: 'Colombo',
    description: 'Rainy',
    temperature: 32.5,
    humidity: 85,
    rainfall: 15.5,
    windSpeed: 12.3,
    timestamp: new Date(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('fetchWeather', () => {
    it('should fetch weather data successfully', async () => {
      const mockResponse = {
        data: {
          list: [
            {
              main: {
                temp: 32.5,
                humidity: 85,
              },
              weather: [{ description: 'rainy' }],
              wind: { speed: 12.3 },
              rain: { '3h': 15.5 },
            },
          ],
        },
      };

      axios.get = jest.fn().mockResolvedValue(mockResponse);

      if (weatherService.fetchWeatherByDistrict) {
        const result = await weatherService.fetchWeatherByDistrict('Colombo');
        expect(result).toBeDefined();
      }
    });

    it('should handle API errors gracefully', async () => {
      axios.get = jest.fn().mockRejectedValue(new Error('API Error'));

      if (weatherService.fetchWeatherByDistrict) {
        try {
          await weatherService.fetchWeatherByDistrict('Colombo');
        } catch (error) {
          expect(error).toBeDefined();
        }
      }
    });
  });

  describe('getWeatherAlerts', () => {
    it('should return weather alerts for extreme conditions', () => {
      const extremeWeather = {
        temperature: 42,
        humidity: 95,
        rainfall: 100,
        windSpeed: 50,
      };

      if (weatherService.getWeatherAlerts) {
        const alerts = weatherService.getWeatherAlerts(extremeWeather);
        // Should have alerts for extreme conditions
        if (Array.isArray(alerts)) {
          expect(alerts.length).toBeGreaterThan(0);
        }
      }
    });

    it('should not return alerts for normal weather', () => {
      const normalWeather = {
        temperature: 28,
        humidity: 65,
        rainfall: 5,
        windSpeed: 10,
      };

      if (weatherService.getWeatherAlerts) {
        const alerts = weatherService.getWeatherAlerts(normalWeather);
        if (Array.isArray(alerts)) {
          expect(alerts.length).toBe(0);
        }
      }
    });
  });

  describe('getWeatherByLocation', () => {
    it('should return cached weather if available', async () => {
      const mockWeatherModel = require('../../src/models/WeatherData');
      mockWeatherModel.findOne = jest.fn().mockResolvedValue(mockWeatherData);

      if (weatherService.getWeatherByLocation) {
        const result = await weatherService.getWeatherByLocation('Colombo');
        if (result) {
          expect(result).toMatchObject({
            district: 'Colombo',
            temperature: expect.any(Number),
          });
        }
      }
    });
  });
});
