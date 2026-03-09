const mongoose = require('mongoose');

const weatherSchema = new mongoose.Schema(
  {
    location: {
      city: {
        type: String,
        required: true,
      },
      district: String,
      coordinates: {
        latitude: {
          type: Number,
          required: true,
        },
        longitude: {
          type: Number,
          required: true,
        },
      },
    },
    current: {
      temperature: {
        value: Number,
        unit: {
          type: String,
          default: 'celsius',
        },
      },
      feelsLike: Number,
      humidity: Number,
      pressure: Number,
      windSpeed: Number,
      windDirection: String,
      cloudCover: Number,
      visibility: Number,
      uvIndex: Number,
      condition: String,
      description: String,
      icon: String,
    },
    forecast: [
      {
        date: Date,
        day: String,
        tempMax: Number,
        tempMin: Number,
        humidity: Number,
        precipitation: Number,
        precipitationProbability: Number,
        windSpeed: Number,
        condition: String,
        description: String,
        icon: String,
      },
    ],
    alerts: [
      {
        type: {
          type: String,
          enum: ['storm', 'rain', 'flood', 'drought', 'heatwave', 'coldwave'],
        },
        severity: {
          type: String,
          enum: ['low', 'moderate', 'high', 'extreme'],
        },
        title: String,
        description: String,
        startTime: Date,
        endTime: Date,
      },
    ],
    sunrise: Date,
    sunset: Date,
    dataSource: {
      type: String,
      default: 'openweathermap',
    },
    lastUpdated: {
      type: Date,
      default: Date.now,
    },
    cacheExpiry: {
      type: Date,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Index for location-based queries
weatherSchema.index({ 'location.coordinates': '2dsphere' });
weatherSchema.index({ 'location.city': 1, lastUpdated: -1 });

module.exports = mongoose.model('Weather', weatherSchema);
