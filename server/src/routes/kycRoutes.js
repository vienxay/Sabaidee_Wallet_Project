// routes/kycRoutes.js
const express    = require('express');
const router     = express.Router();
const multer     = require('multer');
const path       = require('path');
const controller = require('../controllers/kycController');
const { protect, adminOrStaff } = require('../middleware/authMiddleware'); // ✅ ຕັດ adminOnly ອອກ

const upload = multer({
    storage: multer.memoryStorage(),
    fileFilter: (req, file, cb) => {
        console.log('📁 Upload file:', {
            originalname: file.originalname,
            mimetype:     file.mimetype,
            fieldname:    file.fieldname,
        });

        const allowedExts = ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'];
        const ext = path.extname(file.originalname).toLowerCase();

        if (allowedExts.includes(ext)) {
            console.log('✅ File accepted');
            return cb(null, true);
        }

        console.log('❌ File rejected. Ext:', ext, 'Mime:', file.mimetype);
        cb(new Error(`ອະນຸຍາດສະເພາະ ${allowedExts.join(', ')}`));
    },
    limits: { fileSize: 10 * 1024 * 1024 },
}).fields([
    { name: 'idFront',  maxCount: 1 },
    { name: 'passport', maxCount: 1 },
    { name: 'selfie',   maxCount: 1 },
]);

// ── Error handling middleware ─────────────────────────────────────────────────
const handleUploadError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({
                success: false,
                message: 'ຮູບໃຫຍ່ເກີນ 10MB',
            });
        }
        if (err.code === 'LIMIT_UNEXPECTED_FILE') {
            return res.status(400).json({
                success: false,
                message: 'ຊື່ field ບໍ່ຖືກຕ້ອງ (ຕ້ອງແມ່ນ idFront, passport ຫຼື selfie)',
            });
        }
    }
    if (err) {
        return res.status(400).json({ success: false, message: err.message });
    }
    next();
};

// ── User routes ───────────────────────────────────────────────────────────────
router.get('/',        protect, controller.getMyKycStatus);
router.post('/submit', protect, upload, handleUploadError, controller.submitKyc);

// ── Admin / Staff routes ──────────────────────────────────────────────────────
router.put('/verify/:userId', protect, adminOrStaff, controller.reviewKyc);
router.get('/list',           protect, adminOrStaff, controller.listKyc);

// ── Dev only ──────────────────────────────────────────────────────────────────
if (process.env.NODE_ENV === 'development') {
    const Kyc  = require('../models/Kyc');
    const User = require('../models/User');
    router.delete('/reset', protect, async (req, res) => {
        await Kyc.deleteOne({ user: req.user._id });
        await User.findByIdAndUpdate(req.user._id, { kycStatus: 'none', kyc: null });
        res.json({ success: true, message: 'KYC reset ແລ້ວ' });
    });
}

module.exports = router;