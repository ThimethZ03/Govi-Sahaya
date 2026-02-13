const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    type: {
      type: String,
      required: true,
      enum: [
        'weather_alert',
        'disease_detection',
        'order_update',
        'forum_reply',
        'price_alert',
        'general',
      ],
    },
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      maxlength: [200, 'Title cannot exceed 200 characters'],
    },
    message: {
      type: String,
      required: [true, 'Message is required'],
      maxlength: [500, 'Message cannot exceed 500 characters'],
    },
    icon: {
      type: String,
    },
    data: {
      type: mongoose.Schema.Types.Mixed,
    },
    actionUrl: {
      type: String,
    },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high', 'urgent'],
      default: 'medium',
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
    readAt: {
      type: Date,
    },
    expiresAt: {
      type: Date,
    },
    sendVia: {
      push: {
        type: Boolean,
        default: true,
      },
      email: {
        type: Boolean,
        default: false,
      },
      sms: {
        type: Boolean,
        default: false,
      },
    },
    sentAt: {
      type: Date,
    },
    deliveryStatus: {
      push: {
        type: String,
        enum: ['pending', 'sent', 'failed'],
        default: 'pending',
      },
      email: {
        type: String,
        enum: ['pending', 'sent', 'failed'],
        default: 'pending',
      },
      sms: {
        type: String,
        enum: ['pending', 'sent', 'failed'],
        default: 'pending',
      },
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
notificationSchema.index({ user: 1, isRead: 1, createdAt: -1 });
notificationSchema.index({ user: 1, type: 1 });
notificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('Notification', notificationSchema);
