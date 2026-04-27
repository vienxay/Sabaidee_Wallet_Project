const express  = require('express');
const router   = express.Router();
const multer   = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../config/cloudinary');
const { protect } = require('../middleware/authMiddleware');
const {
    getMyProfile,
    updateMyProfile,
    uploadAvatar,
    deleteAvatar,
} = require('../controllers/profileController');

// ─── Cloudinary Storage ───────────────────────────────────────────
const storage = new CloudinaryStorage({
    cloudinary,
    params: {
        folder:         'avatars',
        allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
        transformation: [{ width: 400, height: 400, crop: 'fill' }], // ✅ resize อัตโนมัติ
        public_id: (req, file) => `avatar_${req.user.id}`, // ✅ overwrite รูปเก่าอัตโนมัติ
    },
});

const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

// ─── Multer Error Handler ─────────────────────────────────────────
const handleMulterError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ success: false, message: 'ຂະໜາດຮູບຕ້ອງບໍ່ເກີນ 5MB' });
        }
    }
    if (err) {
        return res.status(400).json({ success: false, message: err.message });
    }
    next();
};

// ─── Routes ───────────────────────────────────────────────────────
router.get   ('/me',     protect, getMyProfile);
router.put   ('/me',     protect, updateMyProfile);
router.post  ('/avatar', protect, upload.single('avatar'), handleMulterError, uploadAvatar);
router.delete('/avatar', protect, deleteAvatar);


module.exports = router;