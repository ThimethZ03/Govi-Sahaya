const mongoose = require('mongoose');

const userSettingsSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    notifications: {
      push: { type: Boolean, default: true },
      email: { type: Boolean, default: false },
    },
    privacy: {
      locationAccess: { type: Boolean, default: true },
      dataSync: { type: Boolean, default: true },
    },
    appearance: {
      darkMode: { type: Boolean, default: false },
      language: { type: String, default: 'en' },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('UserSettings', userSettingsSchema);
