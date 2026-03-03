const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      unique: true,
      sparse: true,
    },
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        'Please provide a valid email',
      ],
    },
    phone: {
      type: String,
      trim: true,
    },
    password: {
      type: String,
      minlength: [8, 'Password must be at least 8 characters'],
      select: false,
    },
    role: {
      type: String,
      enum: ['admin', 'farmer', 'expert', 'vendor'],
      default: 'farmer',
    },
    profilePicture: {
      type: String,
      default: null,
    },

    // ── NEW: Profile fields ──────────────────────────────────────
    birthday: {
      type: String,
      trim: true,
      default: null,
    },
    gender: {
      type: String,
      enum: ['Male', 'Female', 'Other', 'Prefer not to say', ''],
      default: '',
    },
    farmLocation: {
      type: String,
      trim: true,
      default: null,
    },
    // ────────────────────────────────────────────────────────────

    location: {
      district: {
        type: String,
        trim: true,
        default: null,
      },
      province: {
        type: String,
        trim: true,
        default: null,
      },
    },
    farmDetails: {
      farmSize: {
        type: Number,
        default: null,
      },
      farmSizeUnit: {
        type: String,
        enum: ['acres', 'hectares', 'perches'],
        default: 'acres',
      },
      mainCrops: {
        type: [String],
        default: [],
      },
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    isPhoneVerified: {
      type: Boolean,
      default: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastLogin: {
      type: Date,
      default: null,
    },
    resetPasswordToken: String,
    resetPasswordExpire: Date,

    // ── App Settings ─────────────────────────────────────────────
    settings: {
      language: {
        type: String,
        enum: ['en', 'si', 'ta'],
        default: 'en',
      },
      pushNotifications: {
        type: Boolean,
        default: true,
      },
      emailNotifications: {
        type: Boolean,
        default: false,
      },
      darkMode: {
        type: Boolean,
        default: false,
      },
      locationAccess: {
        type: Boolean,
        default: true,
      },
      dataSync: {
        type: Boolean,
        default: true,
      },
    },
  },
  {
    timestamps: true,
  }
);

// ── Hash password before saving ───────────────────────────────────
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  if (!this.password) return next();
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// ── Compare password ──────────────────────────────────────────────
userSchema.methods.comparePassword = async function (candidatePassword) {
  if (!this.password) return false;
  return await bcrypt.compare(candidatePassword, this.password);
};

// ── Virtual: full location ────────────────────────────────────────
userSchema.virtual('fullLocation').get(function () {
  if (this.location?.district && this.location?.province) {
    return `${this.location.district}, ${this.location.province}`;
  }
  return this.location?.district ?? null;
});

// ── Virtual: app settings with defaults ──────────────────────────
userSchema.virtual('appSettings').get(function () {
  return {
    language:           this.settings?.language           ?? 'en',
    pushNotifications:  this.settings?.pushNotifications  ?? true,
    emailNotifications: this.settings?.emailNotifications ?? false,
    darkMode:           this.settings?.darkMode           ?? false,
    locationAccess:     this.settings?.locationAccess     ?? true,
    dataSync:           this.settings?.dataSync           ?? true,
  };
});

userSchema.set('toJSON', { virtuals: true });
userSchema.set('toObject', { virtuals: true });

const User = mongoose.model('User', userSchema);
module.exports = User;
