// models/User.js
const mongoose = require('mongoose');
const bcrypt   = require('bcryptjs');

const userSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: [true, 'ກະລຸນາໃສ່ຊື່'],
            trim: true,
        },
        email: {
            type: String,
            required: [true, 'ກະລຸນາໃສ່ອີເມວ'],
            unique: true,
            lowercase: true,
            trim: true,
            index: true,
            match: [/^\S+@\S+\.\S+$/, 'ກະລຸນາໃສ່ອີເມວທີ່ຖືກຕ້ອງ'],
        },
        password: {
            type: String,
            required: [true, 'ກະລຸນາໃສ່ລະຫັດ'],
            minlength: [6, 'ລະຫັດຕ້ອງມີຢ່າງນ້ອຍ 6 ຕົວອັກສອນ'],
            select: false,
        },
        profileImage:    { type: String,  default: null },
        googleId:        { type: String,  default: null, sparse: true, index: true },
        isGoogleAccount: { type: Boolean, default: false },
        role: {
            type: String,
            enum: ['user', 'admin'],
            default: 'user',
        },

        // ✅ ເກັບແຕ່ status + ref — ລາຍລະອຽດຢູ່ kycs collection
        kycStatus: {
            type: String,
            enum: ['none', 'pending', 'verified', 'rejected'],
            default: 'none',
        },
        kyc: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Kyc',
            default: null,
        },

        wallet: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Wallet',
            default: null,
        },
        resetPasswordOTP:         { type: String,  select: false },
        resetPasswordOTPExpiry:   { type: Date,    select: false },
        resetPasswordOTPVerified: { type: Boolean, default: false, select: false },
    },
    { timestamps: true }
);

userSchema.pre('save', async function () {
    if (!this.isModified('password')) return;
    this.password = await bcrypt.hash(this.password, 10);
});

userSchema.methods.comparePassword = async function (candidatePassword) {
    if (!this.password) throw new Error('Password not selected');
    return bcrypt.compare(candidatePassword, this.password);
};

userSchema.methods.hasWallet = function () {
    return this.wallet !== null;
};

const User = mongoose.model('User', userSchema);
module.exports = User;