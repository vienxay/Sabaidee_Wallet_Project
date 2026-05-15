// ຈັດການ Profile ຂອງ user: ດຶງ, ອັບເດດ, upload/ລຶບຮູບ
// Profile ເປັນ collection ແຍກຈາກ User — ເກັບຂໍ້ມູນສ່ວນຕົວເພີ່ມເຕີມ
// ຮູບ avatar ຖືກ sync ໃນ 2 collection: Profile.profileImage ແລະ User.profileImage
const Profile  = require('../models/Profile');
const User     = require('../models/User');
const cloudinary = require('../config/cloudinary');

// ─── GET /api/profile/me ──────────────────────────────────────────
// ດຶງ profile ຂອງ user — ຖ້າຍັງບໍ່ມີ profile ຈະ auto-create ທັນທີ
exports.getMyProfile = async (req, res) => {
    try {
        let profile = await Profile.findOne({ user: req.user.id });
        if (!profile) {
            // ສ້າງ profile ເປົ່າສຳລັບ user ໃໝ່ (ໄດ້ register ແຕ່ຍັງບໍ່ fill profile)
            profile = await Profile.create({ user: req.user.id });
        }
        res.status(200).json({ success: true, data: profile });
    } catch (err) {
        console.error('getMyProfile error:', err);
        res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດ Server' });
    }
};

// ─── PUT /api/profile/me ──────────────────────────────────────────
// ອັບເດດ profile — ຮອງຮັບ partial update (ສົ່ງສະເພາະ fields ທີ່ຕ້ອງການ)
// validation: phone (8-15 digits), gender (male/female/other), dateOfBirth (ISO date)
exports.updateMyProfile = async (req, res) => {
    try {
        const { name, lastName, phone, dateOfBirth, gender } = req.body;

        // ກວດ phone format — ຍອມຮັບ null/empty (ສຳລັບ clear field)
        if (phone !== undefined && phone !== null && phone !== '') {
            if (!/^\d{8,15}$/.test(phone)) {
                return res.status(400).json({ success: false, message: 'ເບີໂທລະສັບຕ້ອງມີ 8-15 ຕົວເລກ' });
            }
        }

        const allowedGenders = ['male', 'female', 'other'];
        if (gender !== undefined && gender !== null && !allowedGenders.includes(gender)) {
            return res.status(400).json({ success: false, message: 'gender ຕ້ອງເປັນ male, female ຫຼື other' });
        }

        if (dateOfBirth && isNaN(new Date(dateOfBirth).getTime())) {
            return res.status(400).json({ success: false, message: 'ວັນເດືອນປີເກີດບໍ່ຖືກຕ້ອງ' });
        }

        // whitelist fields — ກັນ mass assignment attack
        const allowed = ['name', 'lastName', 'phone', 'dateOfBirth', 'gender'];
        const updateData = {};
        allowed.forEach(field => {
            if (req.body[field] !== undefined) updateData[field] = req.body[field];
        });

        if (Object.keys(updateData).length === 0) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາສົ່ງຂໍ້ມູນທີ່ຕ້ອງການອັບເດດ' });
        }

        // upsert: ຖ້າຍັງບໍ່ມີ profile ຈະສ້າງໃໝ່ທັນທີ
        const profile = await Profile.findOneAndUpdate(
            { user: req.user.id },
            { $set: updateData },
            { returnDocument: 'after', upsert: true, runValidators: true }
        );

        res.status(200).json({ success: true, message: 'ອັບເດດຂໍ້ມູນສຳເລັດ', data: profile });
    } catch (err) {
        console.error('updateMyProfile error:', err);
        if (err.name === 'ValidationError') {
            const messages = Object.values(err.errors).map(e => e.message);
            return res.status(400).json({ success: false, message: messages.join(', ') });
        }
        res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດ Server' });
    }
};

// ─── POST /api/profile/avatar ─────────────────────────────────────
// Upload ຮູບ avatar ໄປ Cloudinary ແລ້ວ sync URL ໃນ 2 collection ພ້ອມກັນ
// req.file ຖືກ inject ໂດຍ multer-storage-cloudinary middleware
exports.uploadAvatar = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາເລືອກຮູບ' });
        }

        // req.file.path = Cloudinary URL (ຫຼັງ upload ສຳເລັດ)
        const imageUrl = req.file.path;

        // sync ທັງ 2 collection ພ້ອມກັນ (parallel) — ກັນ inconsistent state
        const [profile] = await Promise.all([
            Profile.findOneAndUpdate(
                { user: req.user.id },
                { $set: { profileImage: imageUrl } },
                { returnDocument: 'after', upsert: true }
            ),
            User.findByIdAndUpdate(
                req.user.id,
                { profileImage: imageUrl },
                { returnDocument: 'after' }
            ),
        ]);

        res.status(200).json({
            success: true,
            message: 'ອັບໂຫລດຮູບສຳເລັດ',
            data:    { profileImage: profile.profileImage },
        });
    } catch (err) {
        console.error('❌ [uploadAvatar] error:', err);
        res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດ Server' });
    }
};

// ─── DELETE /api/profile/avatar ───────────────────────────────────
// ລຶບຮູບ avatar: ລຶບຈາກ Cloudinary ກ່ອນ ແລ້ວ clear URL ໃນ 2 collection ພ້ອມກັນ
exports.deleteAvatar = async (req, res) => {
    try {
        const profile = await Profile.findOne({ user: req.user.id });

        if (!profile?.profileImage) {
            return res.status(400).json({ success: false, message: 'ບໍ່ມີຮູບທີ່ຈະລຶບ' });
        }

        // ລຶບຮູບຈາກ Cloudinary ໂດຍໃຊ້ public_id ທີ່ build ຈາກ userId
        const publicId = `avatars/avatar_${req.user.id}`;
        await cloudinary.uploader.destroy(publicId);
        console.log('🗑️ ລຶບຮູບຈາກ Cloudinary:', publicId);

        // clear profileImage ໃນ 2 collection ພ້ອມກັນ (parallel)
        await Promise.all([
            profile.updateOne({ profileImage: null }),
            User.findByIdAndUpdate(req.user.id, { profileImage: null }),
        ]);

        res.status(200).json({ success: true, message: 'ລຶບຮູບສຳເລັດ' });
    } catch (err) {
        console.error('deleteAvatar error:', err);
        res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດ Server' });
    }
};
