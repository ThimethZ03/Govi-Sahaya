const mongoose = require('mongoose');

const cropSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Crop name is required'],
      unique: true,
      trim: true,
    },
    scientificName: {
      type: String,
      trim: true,
    },
    localName: {
      type: String,
      trim: true,
    },
    category: {
      type: String,
      enum: ['vegetable', 'fruit', 'grain', 'legume', 'tuber', 'spice', 'other'],
      default: 'vegetable',
    },
    description: {
      type: String,
      required: true,
    },
    imageUrl: {
      type: String,
    },
    growingSeasons: [{
      type: String,
      enum: ['yala', 'maha', 'year-round'],
    }],
    idealClimate: {
      temperature: {
        min: Number,
        max: Number,
        unit: { type: String, default: 'Celsius' },
      },
      rainfall: {
        min: Number,
        max: Number,
        unit: { type: String, default: 'mm' },
      },
      humidity: {
        min: Number,
        max: Number,
        unit: { type: String, default: '%' },
      },
    },
    soilRequirements: {
      type: [String],
      default: [],
    },
    wateringSchedule: {
      frequency: String,
      amount: String,
    },
    growthDuration: {
      min: Number,
      max: Number,
      unit: { type: String, default: 'days' },
    },
    commonDiseases: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Disease',
    }],
    commonPests: [String],
    fertilizers: [{
      name: String,
      timing: String,
      amount: String,
    }],
    harvestingTips: [String],
    marketPrice: {
      min: Number,
      max: Number,
      unit: { type: String, default: 'LKR/kg' },
      lastUpdated: Date,
    },
    nutritionalValue: {
      calories: Number,
      protein: Number,
      carbohydrates: Number,
      fiber: Number,
      vitamins: [String],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Create text index for search
cropSchema.index({ name: 'text', scientificName: 'text', localName: 'text' });

const Crop = mongoose.model('Crop', cropSchema);

module.exports = Crop;
