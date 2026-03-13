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
            required: true,
        },
        type: {
            type: String,
            enum: ['topup', 'withdraw', 'pay', 'receive'],
            required: true,
        },
        status: {
            type: String,
            enum: ['pending', 'success', 'failed'],
            default: 'pending',
        },
        // ຈຳນວນເງິນ
        amountSats:  { type: Number, required: true },    // BTC sats
        amountLAK:   { type: Number, default: 0 },        // ກີບລາວ
        feeSats:     { type: Number, default: 0 },        // ຄ່າທຳນຽມ sats

        // ອັດຕາແລກປ່ຽນ ณ ເວລາທຸລະກຳ
        exchangeRate: {
            btcToLAK: { type: Number, default: 0 },       // 1 BTC = ? LAK
            btcToUSD: { type: Number, default: 0 },       // 1 BTC = ? USD
            usdToLAK: { type: Number, default: 0 },       // 1 USD = ? LAK
            fetchedAt: { type: Date, default: null },
        },

        // Lightning Network
        paymentHash:    { type: String, default: null, index: true },
        paymentRequest: { type: String, default: null }, // bolt11
        memo:           { type: String, default: '' },

        // ຂໍ້ມູນ TopUp BTC
        topup: {
            btcAddress:  { type: String, default: null },
            txid:        { type: String, default: null },
            confirmations: { type: Number, default: 0 },
        },

        // ຂໍ້ມູນ KYC (ສຳລັບ ຈ່າຍເງິນຖິ່ນ)
        kycRequired:  { type: Boolean, default: false },
        kycVerified:  { type: Boolean, default: false },
    },
    { timestamps: true }
);

// index ສຳລັບດຶງປະຫວັດ
transactionSchema.index({ user: 1, createdAt: -1 });
transactionSchema.index({ status: 1, type: 1 });

const Transaction = mongoose.model('Transaction', transactionSchema);
module.exports = Transaction;