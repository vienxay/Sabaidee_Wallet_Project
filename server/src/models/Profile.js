const mongoose = require('mongoose');

const profileSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            unique: true,
        },
        name:        { type: String, default: null, trim: true },
        lastName:    { type: String, default: null, trim: true },
        phone: {
            type: String,
            default: null,
            trim: true,
            validate: {
                validator: v => v === null || /^\d{8,15}$/.test(v),
                message: 'ເບີໂທລະສັບຕ້ອງມີ 8-15 ຕົວເລກ',
            },
        },
        dateOfBirth: { type: Date,   default: null },
        gender: {
            type: String,
            enum: {
                values: ['male', 'female', 'other'],
                message: 'gender ຕ້ອງເປັນ male, female ຫຼື other',
            },
            default: null,
        },
        profileImage: { type: String, default: null },
    },
    { timestamps: true }
);

module.exports = mongoose.model('Profile', profileSchema);