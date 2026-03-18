// routes/kycRoutes.js
const express     = require('express');
const router      = express.Router();
const multer      = require('multer');
const controller  = require('../controllers/kycController');
const { protect, adminOnly } = require('../middleware/authMiddleware'); // ✅

const upload = multer({
    storage: multer.memoryStorage(),
    fileFilter: (req, file, cb) => {
        const allowed = /jpeg|jpg|png|webp/;
        const ok = allowed.test(file.originalname.toLowerCase())
                && allowed.test(file.mimetype);
        ok ? cb(null, true) : cb(new Error('ອະນຸຍາດສະເພາະ jpg, png, webp'));
    },
    limits: { fileSize: 10 * 1024 * 1024 },
}).fields([
    { name: 'idFront', maxCount: 1 },
    { name: 'selfie',  maxCount: 1 },
]);

// ── User routes ───────────────────────────────────────────────────────────────
router.get('/',        protect,              controller.getMyKycStatus);
router.post('/submit', protect, upload,      controller.submitKyc);

// ── Admin routes ──────────────────────────────────────────────────────────────
router.put('/verify/:userId', protect, adminOnly, controller.reviewKyc); // ✅
router.get('/list',           protect, adminOnly, controller.listKyc);   // ✅

// ── Dev only ──────────────────────────────────────────────────────────────────
// kycRoutes.js — dev reset
if (process.env.NODE_ENV === 'development') {
    const Kyc = require('../models/Kyc');
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