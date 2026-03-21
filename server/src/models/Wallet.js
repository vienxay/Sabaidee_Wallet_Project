const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            unique: true,
            index: true,
        },
        walletId: {
            type: String,
            required: true,
            unique: true,
        },
        walletName: {
            type: String,
            required: true,
        },
        adminKey: {
            type: String,
            required: true,
            select: false,
        },
        invoiceKey: {
            type: String,
            required: true,
        },
        balanceSats: {
            type: Number,
            default: 0,
        },
        // ✅ ເພີ່ມ: ຍອດເງິນກີບ (ໃຊ້ກັບ Internal Transfer)
        balanceLAK: {
            type: Number,
            default: 0,
        },
    },
    { timestamps: true }
);

const Wallet = mongoose.model('Wallet', walletSchema);
module.exports = Wallet;