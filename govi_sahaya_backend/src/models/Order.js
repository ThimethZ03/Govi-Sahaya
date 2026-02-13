const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema(
  {
    orderNumber: {
      type: String,
      unique: true,
      required: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    items: [
      {
        product: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'ShopItem',
          required: true,
        },
        name: String,
        quantity: {
          type: Number,
          required: true,
          min: [1, 'Quantity must be at least 1'],
        },
        unit: String,
        price: {
          type: Number,
          required: true,
        },
        subtotal: {
          type: Number,
          required: true,
        },
      },
    ],
    totalAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    currency: {
      type: String,
      default: 'LKR',
    },
    shippingAddress: {
      name: String,
      phone: String,
      addressLine1: {
        type: String,
        required: true,
      },
      addressLine2: String,
      city: {
        type: String,
        required: true,
      },
      district: String,
      postalCode: String,
      coordinates: {
        latitude: Number,
        longitude: Number,
      },
    },
    paymentMethod: {
      type: String,
      required: true,
      enum: ['cash_on_delivery', 'card', 'bank_transfer', 'mobile_payment'],
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed', 'refunded'],
      default: 'pending',
    },
    paymentDetails: {
      transactionId: String,
      paidAt: Date,
      paymentProof: String,
    },
    status: {
      type: String,
      enum: ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'],
      default: 'pending',
      index: true,
    },
    statusHistory: [
      {
        status: String,
        timestamp: {
          type: Date,
          default: Date.now,
        },
        note: String,
      },
    ],
    shippingDetails: {
      carrier: String,
      trackingNumber: String,
      shippedAt: Date,
      estimatedDelivery: Date,
      deliveredAt: Date,
    },
    notes: {
      customerNote: String,
      adminNote: String,
    },
    cancellation: {
      reason: String,
      cancelledBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
      cancelledAt: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Index for queries
orderSchema.index({ user: 1, createdAt: -1 });
orderSchema.index({ orderNumber: 1 });
orderSchema.index({ status: 1, createdAt: -1 });

// Generate order number
orderSchema.pre('save', async function (next) {
  if (!this.orderNumber) {
    const date = new Date();
    const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
    this.orderNumber = `ORD-${date.getFullYear()}${(date.getMonth() + 1).toString().padStart(2, '0')}${date.getDate().toString().padStart(2, '0')}-${random}`;
  }
  next();
});

module.exports = mongoose.model('Order', orderSchema);
