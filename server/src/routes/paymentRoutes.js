// Payment Routes — ຈ່າຍ Lightning, LNURL, LAO QR
// ທຸກ route ຜ່ານ protect middleware (line router.use(protect))
// validateMiddleware ກວດ input ກ່ອນ controller
const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
    validateDecodeInvoice,
    validatePayInvoice,
    validateLaoQRPay,
} = require('../middleware/validateMiddleware');
const {
    pay,
    decodeInvoice,
    payLaoQR,
    payLNURL,
    getLaoQRLimitStatus,
} = require('../controllers/paymentController');

const router = express.Router();

router.use(protect);

router.post('/pay', validatePayInvoice, pay);
router.post('/decode', validateDecodeInvoice, decodeInvoice);
router.post('/laoqr/pay', validateLaoQRPay, payLaoQR);
router.get('/laoqr/limit-status', getLaoQRLimitStatus);
router.post('/pay-lnurl', payLNURL);

module.exports = router;
