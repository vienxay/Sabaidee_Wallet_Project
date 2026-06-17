const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
    {
        user: {
            type:     mongoose.Schema.Types.ObjectId,
            ref:      'User',
            required: true,
            index:    true,
        },
        title:         { type: String, required: true },
        body:          { type: String, required: true },
        type:          { type: String, enum: ['topup', 'pay', 'laoQR', 'withdraw', 'kyc', 'system'], default: 'system' },
        read:          { type: Boolean, default: false },
        transactionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Transaction', default: null },
    },
    { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);
