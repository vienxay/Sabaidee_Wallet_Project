const mongoose = require('mongoose');

const rateSchema = new mongoose.Schema(
    {
        usdToLAK      : { type: Number, default: 0 },
        btcToUSD      : { type: Number, default: 0 },
        btcToLAK      : { type: Number, default: 0 },
        spreadPercent    : { type: Number, default: 0 },
        laoQrFeePercent  : { type: Number, default: 0 },

        // ── Payment Limits (LAK) ──
        payPerTxUnverified   : { type: Number, default: 500_000 },
        payDailyUnverified   : { type: Number, default: 1_000_000 },
        payPerTxVerified     : { type: Number, default: 5_000_000 },
        payDailyVerified     : { type: Number, default: 20_000_000 },
        qrDailyUnverified    : { type: Number, default: 2_000_000 },
        qrDailyVerified      : { type: Number, default: 100_000_000 },
    },
    { timestamps: true }
);

module.exports = mongoose.model('Rate', rateSchema);