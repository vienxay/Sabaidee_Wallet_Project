// src/routes/profileRoutes.js
const express  = require('express');
const router   = express.Router();
const multer   = require('multer');
const path     = require('path');
const fs       = require('fs');
const { protect } = require('../middleware/authMiddleware');
const {
    getMyProfile,
    updateMyProfile,
    uploadAvatar,
    deleteAvatar,
} = require('../controllers/profileController');

// ─── ໂຟລເດີ uploads ─────────────────────────────────────────────
const avatarDir = path.join(__dirname, '../../uploads/avatars');
if (!fs.existsSync(avatarDir)) {
    fs.mkdirSync(avatarDir, { recursive: true }); // ✅ ສ້າງອັດຕະໂນມັດ
}

// ─── Multer Config ────────────────────────────────────────────────
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, avatarDir),
    filename:    (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        cb(null, `avatar_${req.user.id}_${Date.now()}${ext}`);
    },
});

const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
    fileFilter: (req, file, cb) => {
        const allowed = ['image/jpeg', 'image/png', 'image/webp'];
        if (allowed.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('ຮອງຮັບສະເພາະ JPG, PNG, WEBP'), false);
        }
    },
});

// ─── Multer Error Handler ─────────────────────────────────────────
const handleMulterError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ 
                success: false, 
                message: 'ຂະໜາດຮູບຕ້ອງບໍ່ເກີນ 5MB' 
            });
        }
    }
    if (err) {
        return res.status(400).json({ 
            success: false, 
            message: err.message 
        });
    }
    next();
};

// ─── Routes ───────────────────────────────────────────────────────
router.get   ('/me',     protect, getMyProfile);       // GET  /api/profile/me
router.put   ('/me',     protect, updateMyProfile);    // PUT  /api/profile/me
router.post  ('/avatar', protect, upload.single('avatar'), handleMulterError, uploadAvatar);
router.delete('/avatar', protect, deleteAvatar);       // DELETE /api/profile/avatar

module.exports = router;