const mongoose = require('mongoose');

const newsSchema = new mongoose.Schema(
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
      index: true,
      trim: true,
    },

    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
      maxlength: [500, 'Description cannot exceed 500 characters'],
    },

    content: {
      type: String,
      required: [true, 'Content is required'],
    },

    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: [
        'general',
        'market_prices',
        'government_policy',
        'technology',
        'weather',
        'success_stories',
        'events',
      ],
      default: 'general',
    },

    tags: {
      type: [String],
      default: [],
    },

    author: {
      name: String,
      source: String,
    },

    coverImage: {
      url: String,
      alt: String,
    },

    images: [
      {
        url: String,
        caption: String,
      },
    ],

    sourceUrl: {
      type: String,
      trim: true,
    },

    publishedDate: {
      type: Date,
      default: Date.now,
      index: true,
    },

    location: {
      district: String,
      country: {
        type: String,
        default: 'Sri Lanka',
      },
    },

    // Keep this for your app filtering (en/si/ta),
    // but DO NOT let MongoDB use it as text-index language override.
    language: {
      type: String,
      enum: ['en', 'si', 'ta'],
      default: 'en',
    },

    views: { type: Number, default: 0 },
    likes: { type: Number, default: 0 },
    shares: { type: Number, default: 0 },

    isFeatured: {
      type: Boolean,
      default: false,
      index: true,
    },

    isPublished: {
      type: Boolean,
      default: true,
      index: true,
    },

    externalSource: {
      name: String,
      apiId: String,
      fetchedAt: Date,
    },
  },
  { timestamps: true }
);

// ✅ Text index FIXED (prevents: language override unsupported: si)
newsSchema.index(
  {
    title: 'text',
    description: 'text',
    content: 'text',
    tags: 'text',
  },
  {
    name: 'news_text_search',
    weights: {
      title: 10,
      description: 5,
      content: 1,
      tags: 3,
    },
    default_language: 'none',

    // ✅ IMPORTANT: disable MongoDB default language override field ("language")
    // by pointing it to a field that DOES NOT exist.
    language_override: '__no_lang',
  }
);

// Other indexes
newsSchema.index({ category: 1, publishedDate: -1 });
newsSchema.index({ isFeatured: 1, publishedDate: -1 });
newsSchema.index({ isPublished: 1, publishedDate: -1 });

// ✅ Helper: slugify
function slugify(text) {
  return String(text || '')
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');
}

// ✅ Generate a unique slug (avoid duplicate key error)
async function generateUniqueSlug(doc) {
  const base = slugify(doc.title) || `news-${Date.now()}`;
  let slug = base;
  let counter = 1;

  // If same slug exists, add -2, -3, ...
  while (await doc.constructor.exists({ slug })) {
    counter += 1;
    slug = `${base}-${counter}`;
  }

  return slug;
}

// ✅ Pre-save: create/update slug only when needed
newsSchema.pre('save', async function (next) {
  try {
    if ((this.isNew && !this.slug) || this.isModified('title')) {
      this.slug = await generateUniqueSlug(this);
    }
    next();
  } catch (err) {
    next(err);
  }
});

// Virtual for URL
newsSchema.virtual('url').get(function () {
  return `/news/${this.slug}`;
});

newsSchema.set('toJSON', { virtuals: true });
newsSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('News', newsSchema);
