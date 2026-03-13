const mongoose = require('mongoose');

const kycSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            unique: true,
            index: true,
        },
        status: {
            type: String,
            enum: ['pending', 'submitted', 'verified', 'rejected'],
            default: 'pending',
        },
        // ຂໍ້ມູນສ່ວນຕົວ
        fullName:     { type: String, default: null },
        idNumber:     { type: String, default: null },   // ເລກທີ່ບັດ
        idType: {
            type: String,
            enum: ['national_id', 'passport', 'driving_license'],
            default: 'national_id',
        },
        dateOfBirth:  { type: Date,   default: null },
        phone:        { type: String, default: null },
        address:      { type: String, default: null },

        // ເອກະສານ (URL ຮູບ)
        documents: {
            idFront:  { type: String, default: null },   // ດ້ານໜ້າ
            idBack:   { type: String, default: null },   // ດ້ານຫຼັງ
            selfie:   { type: String, default: null },   // ຖ່າຍຄຽງບັດ
        },

        // ກຳນົດ limit ຈ່າຍເງິນ (sats)
        dailyLimitSats:   { type: Number, default: 100000 },   // ກ່ອນ KYC
        monthlyLimitSats: { type: Number, default: 1000000 },

        rejectedReason: { type: String, default: null },
        verifiedAt:     { type: Date,   default: null },
        submittedAt:    { type: Date,   default: null },
    },
    { timestamps: true }
);

const KYC = mongoose.model('KYC', kycSchema);
module.exports = KYC;