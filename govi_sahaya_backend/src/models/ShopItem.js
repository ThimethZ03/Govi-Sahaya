const mongoose = require('mongoose');

const shopItemSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Product name is required'],
      trim: true,
      maxlength: [200, 'Product name cannot exceed 200 characters'],
    },
    slug: {
      type: String,
      unique: true,
      lowercase: true,
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      maxlength: [2000, 'Description cannot exceed 2000 characters'],
    },
    shortDescription: {
      type: String,
      maxlength: [500, 'Short description cannot exceed 500 characters'],
    },
    category: {
      type: String,
      required: true,
      enum: [
        'seeds',
        'fertilizers',
        'pesticides',
        'tools',
        'equipment',
        'irrigation',
        'organic_products',
      ],
    },
    subcategory: {
      type: String,
      trim: true,
    },
    vendor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    images: [
      {
        url: {
          type: String,
          required: true,
        },
        isPrimary: {
          type: Boolean,
          default: false,
        },
        alt: String,
      },
    ],
    price: {
      original: {
        type: Number,
        required: [true, 'Price is required'],
        min: [0, 'Price cannot be negative'],
      },
      discounted: {
        type: Number,
        min: 0,
      },
      currency: {
        type: String,
        default: 'LKR',
      },
    },
    stock: {
      quantity: {
        type: Number,
        required: true,
        min: [0, 'Stock cannot be negative'],
        default: 0,
      },
      unit: {
        type: String,
        required: true,
        enum: ['kg', 'g', 'l', 'ml', 'pieces', 'packets', 'bags'],
      },
      lowStockThreshold: {
        type: Number,
        default: 10,
      },
    },
    specifications: {
      brand: String,
      manufacturer: String,
      weight: {
        value: Number,
        unit: String,
      },
      dimensions: {
        length: Number,
        width: Number,
        height: Number,
        unit: String,
      },
      expiryDate: Date,
      batchNumber: String,
    },
    suitableFor: [String],
    features: [String],
    usage: {
      instructions: String,
      dosage: String,
      precautions: [String],
    },
    ratings: {
      average: {
        type: Number,
        default: 0,
        min: 0,
        max: 5,
      },
      count: {
        type: Number,
        default: 0,
      },
    },
    reviews: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        },
        rating: {
          type: Number,
          required: true,
          min: 1,
          max: 5,
        },
        comment: String,
        date: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    tags: [String],
    isOrganic: {
      type: Boolean,
      default: false,
    },
    isFeatured: {
      type: Boolean,
      default: false,
    },
    isAvailable: {
      type: Boolean,
      default: true,
    },
    views: {
      type: Number,
      default: 0,
    },
    sales: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
shopItemSchema.index({ name: 'text', description: 'text', tags: 'text' });
shopItemSchema.index({ category: 1, isAvailable: 1 });
shopItemSchema.index({ vendor: 1 });
shopItemSchema.index({ slug: 1 });

// Generate slug
shopItemSchema.pre('save', function (next) {
  if (this.isModified('name')) {
    this.slug = this.name
      .toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/--+/g, '-')
      .trim();
  }
  next();
});

module.exports = mongoose.model('ShopItem', shopItemSchema);
