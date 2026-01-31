const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    field: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Field',
      index: true,
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: [
        'seeds',
        'fertilizers',
        'pesticides',
        'labor',
        'equipment',
        'irrigation',
        'transportation',
        'other',
      ],
    },
    subcategory: {
      type: String,
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
      maxlength: [500, 'Description cannot exceed 500 characters'],
    },
    amount: {
      type: Number,
      required: [true, 'Amount is required'],
      min: [0, 'Amount cannot be negative'],
    },
    currency: {
      type: String,
      default: 'LKR',
    },
    date: {
      type: Date,
      required: [true, 'Date is required'],
      default: Date.now,
      index: true,
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'card', 'bank_transfer', 'mobile_payment', 'credit'],
      default: 'cash',
    },
    vendor: {
      name: String,
      contact: String,
    },
    quantity: {
      value: Number,
      unit: String,
    },
    receipt: {
      url: String,
      number: String,
    },
    season: {
      type: String,
      trim: true,
    },
    cropType: {
      type: String,
      trim: true,
    },
    notes: {
      type: String,
      maxlength: 1000,
    },
    isRecurring: {
      type: Boolean,
      default: false,
    },
    recurringFrequency: {
      type: String,
      enum: ['daily', 'weekly', 'monthly', 'yearly'],
    },
    tags: [String],
  },
  {
    timestamps: true,
  }
);

// Index for queries
expenseSchema.index({ user: 1, date: -1 });
expenseSchema.index({ category: 1, date: -1 });
expenseSchema.index({ field: 1, date: -1 });

module.exports = mongoose.model('Expense', expenseSchema);
