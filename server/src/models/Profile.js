// Profile Model — ຂໍ້ມູນສ່ວນຕົວ user ທີ່ຢູ່ນອກ User model
// ແຍກຈາກ User ເພື່ອຄຸ້ມຄອງຂໍ້ມູນ optional profile ໂດຍບໍ່ mix ກັບ auth data
// relation: one-to-one (user → profile)
const mongoose = require('mongoose');

const profileSchema = new mongoose.Schema(
    {
        // reference ໄປ User collection (required, unique = 1 profile ຕໍ່ 1 user)
        user: {
            type:     mongoose.Schema.Types.ObjectId,
            ref:      'User',
            required: true,
            unique:   true,
        },
        name:     { type: String, default: null, trim: true },
        lastName: { type: String, default: null, trim: true },

        // phone: ຕ້ອງເປັນ 8-15 ຕົວເລກ, ຍອມຮັບ null (optional field)
        phone: {
            type:    String,
            default: null,
            trim:    true,
            validate: {
                validator: v => v === null || /^\d{8,15}$/.test(v),
                message:   'ເບີໂທລະສັບຕ້ອງມີ 8-15 ຕົວເລກ',
            },
        },
        dateOfBirth: { type: Date,   default: null },

        // gender enum — ຈຳກັດຄ່າ ກັນ invalid data
        gender: {
            type: String,
            enum: {
                values:  ['male', 'female', 'other'],
                message: 'gender ຕ້ອງເປັນ male, female ຫຼື other',
            },
            default: null,
        },
        // URL ຮູບ avatar (Cloudinary URL) — sync ກັບ User.profileImage
        profileImage: { type: String, default: null },
    },
    { timestamps: true }
);

module.exports = mongoose.model('Profile', profileSchema);
