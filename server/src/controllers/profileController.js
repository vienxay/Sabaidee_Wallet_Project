// src/controllers/profileController.js
const Profile = require('../models/Profile');
const path    = require('path');
const fs      = require('fs');

// ─── Helper: ລຶບຮູບເກົ່າໃນ disk ──────────────────────────────────
const deleteOldAvatar = (profileImage) => {
    if (!profileImage) return;
    try {
        // ✅ ແກ້ path ໃຫ້ຖືກ: server/uploads/avatars/xxx.jpg
        const oldPath = path.join(__dirname, '../../', profileImage);
        if (fs.existsSync(oldPath)) {
            fs.unlinkSync(oldPath);
            console.log('🗑️  ລຶບຮູບເກົ່າ:', oldPath);
        }
    } catch (e) {
        console.error('ລຶບຮູບເກົ່າບໍ່ໄດ້:', e.message);
    }
};

// ─── GET /api/profile/me ──────────────────────────────────────────
exports.getMyProfile = async (req, res) => {
    try {
        let profile = await Profile.findOne({ user: req.user.id });

        // ✅ ສ້າງ profile ຫວ່າງໆ ອັດຕະໂນມັດ ຖ້າຍັງບໍ່ມີ
        if (!profile) {
            profile = await Profile.create({ user: req.user.id });
        }

        res.status(200).json({
            success: true,
            data: profile,
        });
    } catch (err) {
        console.error('getMyProfile error:', err);
        res.status(500).json({ 
            success: false, 
            message: 'ເກີດຂໍ້ຜິດພາດ Server' 
        });
    }
};

// ─── PUT /api/profile/me ──────────────────────────────────────────
exports.updateMyProfile = async (req, res) => {
    try {
        const { name, lastName, phone, dateOfBirth, gender } = req.body;

        // ✅ Validate phone
        if (phone !== undefined && phone !== null && phone !== '') {
            if (!/^\d{8,15}$/.test(phone)) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'ເບີໂທລະສັບຕ້ອງມີ 8-15 ຕົວເລກ' 
                });
            }
        }

        // ✅ Validate gender
        const allowedGenders = ['male', 'female', 'other'];
        if (gender !== undefined && gender !== null && !allowedGenders.includes(gender)) {
            return res.status(400).json({ 
                success: false, 
                message: 'gender ຕ້ອງເປັນ male, female ຫຼື other' 
            });
        }

        // ✅ Validate dateOfBirth
        if (dateOfBirth && isNaN(new Date(dateOfBirth).getTime())) {
            return res.status(400).json({ 
                success: false, 
                message: 'ວັນເດືອນປີເກີດບໍ່ຖືກຕ້ອງ' 
            });
        }

        // ✅ ສ້າງ updateData ສະເພາະ field ທີ່ສົ່ງມາ
        const allowed = ['name', 'lastName', 'phone', 'dateOfBirth', 'gender'];
        const updateData = {};
        allowed.forEach(field => {
            if (req.body[field] !== undefined) {
                updateData[field] = req.body[field];
            }
        });

        if (Object.keys(updateData).length === 0) {
            return res.status(400).json({ 
                success: false, 
                message: 'ກະລຸນາສົ່ງຂໍ້ມູນທີ່ຕ້ອງການອັບເດດ' 
            });
        }

        const profile = await Profile.findOneAndUpdate(
            { user: req.user.id },
            { $set: updateData },
            { new: true, upsert: true, runValidators: true }
        );

        res.status(200).json({
            success: true,
            message: 'ອັບເດດຂໍ້ມູນສຳເລັດ',
            data: profile,
        });
    } catch (err) {
        console.error('updateMyProfile error:', err);
        // ✅ ຈັດການ Mongoose validation error
        if (err.name === 'ValidationError') {
            const messages = Object.values(err.errors).map(e => e.message);
            return res.status(400).json({ 
                success: false, 
                message: messages.join(', ')
            });
        }
        res.status(500).json({ 
            success: false, 
            message: 'ເກີດຂໍ້ຜິດພາດ Server' 
        });
    }
};

// ─── POST /api/profile/avatar ─────────────────────────────────────
exports.uploadAvatar = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ 
                success: false, 
                message: 'ກະລຸນາເລືອກຮູບ' 
            });
        }

        // ✅ ລຶບຮູບເກົ່າກ່ອນ
        const existing = await Profile.findOne({ user: req.user.id });
        if (existing?.profileImage) {
            deleteOldAvatar(existing.profileImage);
        }

        const imagePath = `/uploads/avatars/${req.file.filename}`;

        const profile = await Profile.findOneAndUpdate(
            { user: req.user.id },
            { $set: { profileImage: imagePath } },
            { new: true, upsert: true }
        );

        res.status(200).json({
            success: true,
            message: 'ອັບໂຫລດຮູບສຳເລັດ',
            data: { profileImage: profile.profileImage },
        });
    } catch (err) {
        console.error('uploadAvatar error:', err);
        res.status(500).json({ 
            success: false, 
            message: 'ເກີດຂໍ້ຜິດພາດ Server' 
        });
    }
};

// ─── DELETE /api/profile/avatar ───────────────────────────────────
exports.deleteAvatar = async (req, res) => {
    try {
        const profile = await Profile.findOne({ user: req.user.id });

        if (!profile?.profileImage) {
            return res.status(400).json({ 
                success: false, 
                message: 'ບໍ່ມີຮູບທີ່ຈະລຶບ' 
            });
        }

        deleteOldAvatar(profile.profileImage);

        profile.profileImage = null;
        await profile.save();

        res.status(200).json({ 
            success: true, 
            message: 'ລຶບຮູບສຳເລັດ' 
        });
    } catch (err) {
        console.error('deleteAvatar error:', err);
        res.status(500).json({ 
            success: false, 
            message: 'ເກີດຂໍ້ຜິດພາດ Server' 
        });
    }
};