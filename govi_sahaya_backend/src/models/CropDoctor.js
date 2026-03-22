const mongoose = require('mongoose');

const cropDoctorSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    image: {
      url: {
        type: String,
        required: [true, 'Image URL is required'],
      },
      path: String,
      size: Number,
      mimeType: String,
    },
    predictions: [
      {
        disease: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'Disease',
        },
        diseaseName: String,
        confidence: {
          type: Number,
          min: 0,
          max: 1,
        },
        severity: {
          type: String,
          enum: ['low', 'moderate', 'high', 'critical'],
        },
      },
    ],
    topPrediction: {
      disease: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Disease',
      },
      diseaseName: String,
      confidence: Number,
      severity: String,
    },
    cropType: {
      type: String,
      trim: true,
    },
    location: {
      district: String,
      city: String,
      coordinates: {
        latitude: Number,
        longitude: Number,
      },
    },
    modelVersion: {
      type: String,
      default: '1.0',
    },
    processingTime: {
      type: Number,
      default: 0,
    },
    status: {
      type: String,
      enum: ['pending', 'processing', 'completed', 'failed'],
      default: 'completed',
    },
    userFeedback: {
      isAccurate: Boolean,
      actualDisease: String,
      comments: String,
      rating: {
        type: Number,
        min: 1,
        max: 5,
      },
    },
    notes: {
      type: String,
      maxlength: 500,
    },
  },
  {
    timestamps: true,
  }
);

// Index for queries
cropDoctorSchema.index({ user: 1, createdAt: -1 });
cropDoctorSchema.index({ 'topPrediction.disease': 1 });
cropDoctorSchema.index({ status: 1 });

module.exports = mongoose.model('CropDoctor', cropDoctorSchema);
