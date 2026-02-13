const mongoose = require('mongoose');

const postSchema = new mongoose.Schema(
  {
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      maxlength: [200, 'Title cannot exceed 200 characters'],
    },
    content: {
      type: String,
      required: [true, 'Content is required'],
      maxlength: [5000, 'Content cannot exceed 5000 characters'],
    },
    category: {
      type: String,
      enum: [
        'general',
        'crop_advice',
        'pest_problem',
        'market_price',
        'equipment',
        'success_story',
        'question',
      ],
      default: 'general',
    },
    images: [
      {
        url: String,
        caption: String,
      },
    ],
    tags: {
      type: [String],
      validate: [arrayLimit, 'Cannot have more than 5 tags'],
    },
    location: {
      district: String,
      city: String,
    },
    likes: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    likesCount: {
      type: Number,
      default: 0,
    },
    commentsCount: {
      type: Number,
      default: 0,
    },
    views: {
      type: Number,
      default: 0,
    },
    isPinned: {
      type: Boolean,
      default: false,
    },
    isResolved: {
      type: Boolean,
      default: false,
    },
    isFeatured: {
      type: Boolean,
      default: false,
    },
    reportCount: {
      type: Number,
      default: 0,
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

// Validator for tags array length
function arrayLimit(val) {
  return val.length <= 5;
}

// Indexes
postSchema.index({ author: 1, createdAt: -1 });
postSchema.index({ title: 'text', content: 'text', tags: 'text' });
postSchema.index({ category: 1, createdAt: -1 });
postSchema.index({ isPinned: -1, createdAt: -1 });

module.exports = mongoose.model('Post', postSchema);
