const mongoose = require('mongoose');

const fieldSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: [true, 'Field name is required'],
      trim: true,
      maxlength: [100, 'Field name cannot exceed 100 characters'],
    },
    location: {
      address: String,
      district: String,
      city: String,
      coordinates: {
        latitude: Number,
        longitude: Number,
      },
    },
    area: {
      value: {
        type: Number,
        required: [true, 'Field area is required'],
        min: [0, 'Area cannot be negative'],
      },
      unit: {
        type: String,
        required: true,
        enum: ['acres', 'hectares', 'perches', 'square_meters'],
        default: 'acres',
      },
    },
    // ✅ BUDGET FIELD
    budget: {
      type: Number,
      default: 0,
      min: [0, 'Budget cannot be negative'],
    },
    soilType: {
      type: String,
      enum: ['clay', 'sandy', 'loamy', 'silt', 'peaty', 'chalky', 'mixed'],
    },
    irrigationType: {
      type: String,
      enum: ['rainfed', 'drip', 'sprinkler', 'flood', 'manual', 'mixed'],
    },
    currentCrop: {
      cropName: String,
      plantedDate: Date,
      expectedHarvestDate: Date,
      variety: String,
      status: {
        type: String,
        enum: ['planted', 'growing', 'harvesting', 'fallow'],
      },
    },
    cropHistory: [
      {
        cropName: String,
        plantedDate: Date,
        harvestDate: Date,
        yield: {
          value: Number,
          unit: String,
        },
        notes: String,
      },
    ],
    images: [
      {
        url: String,
        caption: String,
        date: Date,
      },
    ],
    waterSource: {
      type: String,
      enum: ['well', 'river', 'canal', 'tank', 'rainwater', 'municipal'],
    },
    ownership: {
      type: String,
      enum: ['owned', 'leased', 'shared'],
      default: 'owned',
    },
    notes: {
      type: String,
      maxlength: 1000,
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

// Index for queries
fieldSchema.index({ user: 1, isActive: 1 });

// ✅ Cascade delete expenses when a field is deleted (using deleteOne on document)
fieldSchema.pre('deleteOne', { document: true, query: false }, async function (next) {
  try {
    const Expense = mongoose.model('Expense');
    const result = await Expense.deleteMany({ field: this._id });
    console.log(`✅ Cascade delete: Removed ${result.deletedCount} expenses for field ${this._id}`);
    next();
  } catch (error) {
    console.error('❌ Error in cascade delete (deleteOne):', error);
    next(error);
  }
});

// ✅ Cascade delete for findOneAndDelete
fieldSchema.pre('findOneAndDelete', async function (next) {
  try {
    const doc = await this.model.findOne(this.getFilter());
    if (doc) {
      const Expense = mongoose.model('Expense');
      const result = await Expense.deleteMany({ field: doc._id });
      console.log(`✅ Cascade delete: Removed ${result.deletedCount} expenses for field ${doc._id}`);
    }
    next();
  } catch (error) {
    console.error('❌ Error in cascade delete (findOneAndDelete):', error);
    next(error);
  }
});

// ✅ Cascade delete for remove (legacy method)
fieldSchema.pre('remove', async function (next) {
  try {
    const Expense = mongoose.model('Expense');
    const result = await Expense.deleteMany({ field: this._id });
    console.log(`✅ Cascade delete: Removed ${result.deletedCount} expenses for field ${this._id}`);
    next();
  } catch (error) {
    console.error('❌ Error in cascade delete (remove):', error);
    next(error);
  }
});

module.exports = mongoose.model('Field', fieldSchema);
