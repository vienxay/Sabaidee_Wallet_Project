// routes/kycRoutes.js
const express     = require('express');
const router      = express.Router();
const multer      = require('multer');
const path        = require('path');
const controller  = require('../controllers/kycController');
const { protect, adminOnly } = require('../middleware/authMiddleware');

// ✅ ແກ້ໄຂ fileFilter ໃຫ້ຮັບ format ຫຼາຍຂຶ້ນ ແລະ debug ໄດ້
const upload = multer({
    storage: multer.memoryStorage(),
    fileFilter: (req, file, cb) => {
        console.log('📁 Upload file:', {
            originalname: file.originalname,
            mimetype: file.mimetype,
            fieldname: file.fieldname
        });
        
        // ✅ ເພີ່ມ heic/heif ແລະ ກວດສອບດີຂຶ້ນ
        const allowedExts = ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'];
        const allowedMimes = [
            'image/jpeg', 
            'image/jpg', 
            'image/png', 
            'image/webp',
            'image/heic',
            'image/heif',
            'application/octet-stream' // iOS ບາງຄັ້ງສົ່ງແບບນີ້
        ];
        
        const ext = path.extname(file.originalname).toLowerCase();
        const isAllowedExt = allowedExts.includes(ext);
        const isAllowedMime = allowedMimes.includes(file.mimetype);
        
        // ຮັບຖ້າ extension ຖືກ (ບໍ່ສົນ mimetype)
        if (isAllowedExt) {
            console.log('✅ File accepted');
            return cb(null, true);
        }
        
        console.log('❌ File rejected. Ext:', ext, 'Mime:', file.mimetype);
        cb(new Error(`ອະນຸຍາດສະເພາະ ${allowedExts.join(', ')}`));
    },
    limits: { fileSize: 10 * 1024 * 1024 },
}).fields([
    { name: 'idFront', maxCount: 1 },
    { name: 'passport', maxCount: 1 },  // ✅ ເພີ່ມຖ້າ Flutter ສົ່ງຊື່ນີ້
    { name: 'selfie', maxCount: 1 },     // ✅ ເພີ່ມຖ້າຕ້ອງການ
]);

// ✅ Error handling middleware
const handleUploadError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ 
                success: false,
                message: 'ຮູບໃຫຍ່ເກີນ 10MB' 
            });
        }
        if (err.code === 'LIMIT_UNEXPECTED_FILE') {
            return res.status(400).json({ 
                success: false,
                message: 'ຊື່ field ບໍ່ຖືກຕ້ອງ (ຕ້ອງແມ່ນ idFront, passport ຫຼື selfie)' 
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

// ── User routes ───────────────────────────────────────────────────────────────
router.get('/',        protect, controller.getMyKycStatus);

// ✅ ເພີ່ມ error handling
router.post('/submit', protect, upload, handleUploadError, controller.submitKyc);

// ── Admin routes ──────────────────────────────────────────────────────────────
router.put('/verify/:userId', protect, adminOnly, controller.reviewKyc);
router.get('/list',           protect, adminOnly, controller.listKyc);

// ── Dev only ──────────────────────────────────────────────────────────────────
if (process.env.NODE_ENV === 'development') {
    const Kyc  = require('../models/Kyc');
    const User = require('../models/User');
    router.delete('/reset', protect, async (req, res) => {
        await Kyc.deleteOne({ user: req.user._id });
        await User.findByIdAndUpdate(req.user._id, {
            kycStatus: 'none',
            kyc: null,
        });
        res.json({ success: true, message: 'KYC reset ແລ້ວ' });
    });
}

module.exports = router;