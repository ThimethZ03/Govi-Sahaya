const mongoose = require('mongoose');

const diseaseSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Disease name is required'],
      trim: true,
      unique: true,
    },
    scientificName: {
      type: String,
      trim: true,
    },
    category: {
      type: String,
      enum: ['potato', 'tomato', 'pumpkin', 'onion', 'general'],
      required: true,
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      minlength: [20, 'Description must be at least 20 characters'],
    },
    symptoms: [
      {
        type: String,
        required: true,
      },
    ],
    causes: [
      {
        type: String,
      },
    ],
    severity: {
      type: String,
      enum: ['low', 'moderate', 'high', 'critical'],
      default: 'moderate',
    },
    affectedCrops: [
      {
        type: String,
        enum: ['potato', 'tomato', 'pumpkin', 'onion'],
      },
    ],
    treatment: {
      organic: [String],
      chemical: [String],
      preventive: [String],
    },
    images: [
      {
        url: String,
        caption: String,
      },
    ],
    seasonalOccurrence: [
      {
        type: String,
        enum: ['spring', 'summer', 'autumn', 'winter', 'year-round'],
      },
    ],
    spreadRate: {
      type: String,
      enum: ['slow', 'moderate', 'fast', 'very-fast'],
      default: 'moderate',
    },
    economicImpact: {
      type: String,
      enum: ['low', 'moderate', 'high', 'severe'],
    },
    additionalInfo: {
      type: String,
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

// Index for search
diseaseSchema.index({ name: 'text', description: 'text', symptoms: 'text' });
diseaseSchema.index({ category: 1, severity: 1 });

module.exports = mongoose.model('Disease', diseaseSchema);
