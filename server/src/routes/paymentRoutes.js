const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const { validateLaoQRPay } = require('../middleware/validateMiddleware'); // ✅ ເພີ່ມ
const {
    pay,
    decodeInvoice,
    payLaoQR,              // ✅ ເພີ່ມ
    getLaoQRLimitStatus,   // ✅ ເພີ່ມ
} = require('../controllers/paymentController');

const router = express.Router();

router.use(protect);

// ── Lightning (ຄືເດີມ) ──────────────────────────────────────────────────────
router.post('/pay',    pay);           // POST /api/payment/pay
router.post('/decode', decodeInvoice); // POST /api/payment/decode

// ── ✅ LAO QR (ໃໝ່) ─────────────────────────────────────────────────────────
router.post('/laoqr/pay',          validateLaoQRPay, payLaoQR);      // POST /api/payment/laoqr/pay
router.get ('/laoqr/limit-status', getLaoQRLimitStatus);             // GET  /api/payment/laoqr/limit-status

module.exports = router;