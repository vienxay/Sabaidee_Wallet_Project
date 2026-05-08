// models/Kyc.js
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

        // ── ຂໍ້ມູນສ່ວນຕົວ ─────────────────────────────────────────────────────
        fullName:       { type: String, required: true },
        gender:         { type: String, enum: ['M', 'F'], required: true },
        dob:            { type: Date,   required: true },
        nationality:    { type: String, required: true },
        email:          { type: String, required: true },

        // ── Passport / ID ─────────────────────────────────────────────────────
        passportNumber: { type: String, required: true },
        expiryDate:     { type: Date,   required: true },

        // ── ຮູບພາບ (Cloudinary URLs) ──────────────────────────────────────────
        idFrontUrl:     { type: String, required: true },
        selfieUrl:      { type: String, default: null },

        // ── Consent ───────────────────────────────────────────────────────────
        consentData:    { type: Boolean, required: true },
        consentPdpa:    { type: Boolean, required: true },

        // ── Status ────────────────────────────────────────────────────────────
        status: {
            type: String,
            enum: ['pending', 'verified', 'rejected'],
            default: 'pending',
        },
        referenceId:    { type: String, required: true, unique: true },
        reviewNote:     { type: String, default: null },
        reviewedBy:     { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
        reviewedAt:     { type: Date,   default: null },
        submittedAt:    { type: Date,   default: Date.now },
    },
    { timestamps: true }
);

// ── Static Method: upsert KYC ─────────────────────────────────────────────────
// ໃຊ້ແທນ Kyc.create() ເພື່ອປ້ອງກັນ E11000 duplicate key error
// - ຖ້າ user ຍັງບໍ່ມີ KYC → ສ້າງໃໝ່
// - ຖ້າ user ມີ KYC ຢູ່ແລ້ວ (pending/rejected) → ອັບເດດ
// - ຖ້າ KYC ຖືກ verified ແລ້ວ → ບໍ່ອະນຸຍາດໃຫ້ submit ຄືນ
kycSchema.statics.submitKyc = async function (userId, kycData) {
    const existing = await this.findOne({ user: userId });

    if (existing && existing.status === 'verified') {
        const error = new Error('KYC ຂອງທ່ານໄດ້ຮັບການຢືນຢັນແລ້ວ ບໍ່ສາມາດສົ່ງຄືນໄດ້');
        error.code = 'KYC_ALREADY_VERIFIED';
        throw error;
    }

    if (existing) {
        // ── ມີ KYC ຢູ່ແລ້ວ (pending / rejected) → ອັບເດດ ─────────────────────
        // referenceId ໃຊ້ $setOnInsert ດຽວ ຈຶ່ງບໍ່ overwrite ຄ່າເກົ່າ
        // ຖ້າຕ້ອງການ referenceId ໃໝ່ທຸກຄັ້ງ ໃຫ້ຍ້າຍ referenceId ໄປໃສ່ $set
        const updated = await this.findOneAndUpdate(
            { user: userId },
            {
                $set: {
                    ...kycData,
                    status: 'pending',
                    reviewNote: null,
                    reviewedBy: null,
                    reviewedAt: null,
                    submittedAt: new Date(),
                },
            },
            { new: true, runValidators: true }
        );
        return updated;
    }

    // ── ຍັງບໍ່ມີ KYC → ສ້າງໃໝ່ ────────────────────────────────────────────────
    const created = await this.create({ user: userId, ...kycData });
    return created;
};

const Kyc = mongoose.models.Kyc || mongoose.model('Kyc', kycSchema);
module.exports = Kyc;