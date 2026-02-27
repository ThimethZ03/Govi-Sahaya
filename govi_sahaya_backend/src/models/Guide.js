const mongoose = require('mongoose');

const guideSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      maxlength: [200, 'Title cannot exceed 200 characters'],
    },
    slug: {
      type: String,
      unique: true,
      lowercase: true,
    },
    category: {
      type: String,
      required: true,
      enum: [
        'crop_management',
        'pest_control',
        'fertilizers',
        'irrigation',
        'harvesting',
        'storage',
        'marketing',
        'organic_farming',
        'modern_techniques',
      ],
    },
    subcategory: {
      type: String,
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      maxlength: [500, 'Description cannot exceed 500 characters'],
    },
    content: {
      type: String,
      required: [true, 'Content is required'],
    },
    coverImage: {
      type: String,
    },
    images: [
      {
        url: String,
        caption: String,
      },
    ],
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    crops: [
      {
        type: String,
        trim: true,
      },
    ],
    tags: [
      {
        type: String,
        trim: true,
        lowercase: true,
      },
    ],
    difficulty: {
      type: String,
      enum: ['beginner', 'intermediate', 'advanced'],
      default: 'beginner',
    },
    estimatedTime: {
      value: Number,
      unit: {
        type: String,
        enum: ['minutes', 'hours', 'days', 'weeks'],
      },
    },
    steps: [
      {
        stepNumber: Number,
        title: String,
        description: String,
        image: String,
        tips: [String],
      },
    ],
    materials: [
      {
        name: String,
        quantity: String,
        optional: {
          type: Boolean,
          default: false,
        },
      },
    ],
    benefits: [String],
    warnings: [String],
    relatedGuides: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Guide',
      },
    ],
    views: {
      type: Number,
      default: 0,
    },
    likes: {
      type: Number,
      default: 0,
    },
    isPublished: {
      type: Boolean,
      default: true,
    },
    isFeatured: {
      type: Boolean,
      default: false,
    },
    language: {
      type: String,
      default: 'en',
    },
  },
  {
    timestamps: true,
  }
);

// Index for search and filtering
guideSchema.index({ title: 'text', description: 'text', content: 'text', tags: 'text' });
guideSchema.index({ category: 1, isPublished: 1 });
guideSchema.index({ slug: 1 });
guideSchema.index({ author: 1 });

// Generate slug before saving
guideSchema.pre('save', function (next) {
  if (this.isModified('title')) {
    this.slug = this.title
      .toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/--+/g, '-')
      .trim();
  }
  next();
});

module.exports = mongoose.model('Guide', guideSchema);
