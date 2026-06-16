const mongoose = require('mongoose');

const rateSchema = new mongoose.Schema(
    {
        usdToLAK      : { type: Number, default: 0 },
        btcToUSD      : { type: Number, default: 0 },
        btcToLAK      : { type: Number, default: 0 },
        spreadPercent    : { type: Number, default: 0 },
        laoQrFeePercent  : { type: Number, default: 0 }, // ຄ່າທຳນຽມ LAO QR ທຸກຄັ້ງທີ່ຈ່າຍ
    },
    { timestamps: true }
);

module.exports = mongoose.model('Rate', rateSchema);