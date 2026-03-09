const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            index: true
        },

        field: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Field',
            index: true
        },

        category: {
            type: String,
            required: true,
            enum: [
                'seeds',
                'fertilizers',
                'pesticides',
                'labor',
                'equipment',
                'irrigation',
                'transportation',
                'other'
            ]
        },

        description: {
            type: String,
            required: true,
            trim: true,
            maxlength: 500
        },

        amount: {
            type: Number,
            required: true,
            min: 0
        },

        currency: {
            type: String,
            default: 'LKR'
        },

        date: {
            type: Date,
            required: true,
            default: Date.now,
            index: true
        },

        /* ------------------ NEW FIELDS ------------------ */

        supplier: {
            type: String,
            trim: true
        },

        paymentMethod: {
            type: String,
            enum: ['cash', 'bank_transfer', 'mobile_payment', 'credit'],
            default: 'cash'
        },

        quantity: {
            value: {
                type: Number,
                default: 0
            },
            unit: {
                type: String,
                default: 'kg'
            }
        },

        recurring: {
            interval: {
                type: Number
            },
            unit: {
                type: String,
                enum: ['days', 'weeks', 'months', 'years']
            }
        },

        receiptUrl: {
            type: String
        },

        notes: {
            type: String,
            maxlength: 1000
        }
    },
    {
        timestamps: true
    }
);

/* indexes */
expenseSchema.index({ user: 1, date: -1 });
expenseSchema.index({ category: 1, date: -1 });
expenseSchema.index({ field: 1, date: -1 });

module.exports = mongoose.model('Expense', expenseSchema);
