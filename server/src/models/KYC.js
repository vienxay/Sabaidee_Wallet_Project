// models/Kyc.js
const mongoose = require('mongoose');

const kycSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            unique: true, // 1 user = 1 kyc document
            index: true,
        },

        // ── ຂໍ້ມູນສ່ວນຕົວ ─────────────────────────────────────────────────────
        fullName:       { type: String, required: true },
        gender:         { type: String, enum: ['M', 'F'], required: true },
        dob:            { type: Date,   required: true },
        email:          { type: String, required: true },

        // ── Passport / ID ─────────────────────────────────────────────────────
        passportNumber: { type: String, required: true },
        expiryDate:     { type: Date,   required: true },

        // ── ຮູບພາບ (Cloudinary URLs) ──────────────────────────────────────────
        idFrontUrl:     { type: String, required: true },
        selfieUrl:      { type: String, required: true },

        
        // ── Consent ───────────────────────────────────────────────────────────
        consentData:    { type: Boolean, required: true },
        consentPdpa:    { type: Boolean, default: false },

        // ── Status ────────────────────────────────────────────────────────────
        status: {
            type: String,
            enum: ['pending', 'verified', 'rejected'],
            default: 'pending',
        },
        referenceId:    { type: String, required: true },
        reviewNote:     { type: String, default: null },
        reviewedBy:     { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
        reviewedAt:     { type: Date,   default: null },
        submittedAt:    { type: Date,   default: Date.now },
    },
    { timestamps: true }
);

const Kyc = mongoose.models.Kyc || mongoose.model('Kyc', kycSchema);
module.exports = Kyc;