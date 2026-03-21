const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            index: true,
        },
        wallet: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Wallet',
            required: false,          // ✅ laoQR ບໍ່ມີ wallet (demo)
        },
        type: {
            type: String,
            enum: ['topup', 'withdraw', 'pay', 'receive', 'laoQR'], // ✅ ເພີ່ມ laoQR
            required: true,
        },
        status: {
            type: String,
            enum: ['pending', 'success', 'failed'],
            default: 'pending',
        },

        // ── ຈຳນວນເງິນ ────────────────────────────────────────────────────────
        amountSats: { type: Number, default: 0 },   // ✅ required → default 0 (laoQR ບໍ່ມີ sats)
        amountLAK:  { type: Number, default: 0 },
        feeSats:    { type: Number, default: 0 },

        // ── ອັດຕາແລກປ່ຽນ ณ ເວລາທຸລະກຳ ──────────────────────────────────────
        exchangeRate: {
            btcToLAK:  { type: Number, default: 0 },
            btcToUSD:  { type: Number, default: 0 },
            usdToLAK:  { type: Number, default: 0 },
            fetchedAt: { type: Date,   default: null },
        },

        // ── Lightning Network ─────────────────────────────────────────────────
        paymentHash:    { type: String, default: null, index: true },
        paymentRequest: { type: String, default: null },
        memo:           { type: String, default: '' },

        // ── TopUp BTC ─────────────────────────────────────────────────────────
        topup: {
            btcAddress:    { type: String, default: null },
            txid:          { type: String, default: null },
            confirmations: { type: Number, default: 0 },
        },

        // ── KYC ──────────────────────────────────────────────────────────────
        kycRequired: { type: Boolean, default: false },
        kycVerified: { type: Boolean, default: false },

        // ── ✅ LAO QR specific fields ─────────────────────────────────────────
        merchantName: { type: String, default: '' },  // ຊື່ຮ້ານ
        bank:         { type: String, default: '' },  // BCEL / LDB / JDB / LAPNET
        qrRaw:        { type: String, default: '' },  // raw QR string (audit log)
    },
    { timestamps: true }
);

// ── Indexes (ຄືເດີມ) ──────────────────────────────────────────────────────────
transactionSchema.index({ user: 1, createdAt: -1 });
transactionSchema.index({ status: 1, type: 1 });

// ── ✅ Static method: ດຶງຍອດ laoQR ມື້ນີ້ (paymentController ເອີ້ນໃຊ້) ────────
transactionSchema.statics.getDailyLaoQRSpent = async function (userId) {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const result = await this.aggregate([
        {
            $match: {
                user:      new mongoose.Types.ObjectId(userId),
                type:      'laoQR',
                status:    'success',
                createdAt: { $gte: startOfDay },
            },
        },
        { $group: { _id: null, total: { $sum: '$amountLAK' } } },
    ]);

    return result[0]?.total || 0;
};

const Transaction = mongoose.model('Transaction', transactionSchema);
module.exports = Transaction;