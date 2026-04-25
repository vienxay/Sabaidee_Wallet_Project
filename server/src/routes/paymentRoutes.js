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
    getLaoQRLimitStatus,
} = require('../controllers/paymentController');

const router = express.Router();

router.use(protect);

router.post('/pay', validatePayInvoice, pay);
router.post('/decode', validateDecodeInvoice, decodeInvoice);
router.post('/laoqr/pay', validateLaoQRPay, payLaoQR);
router.get('/laoqr/limit-status', getLaoQRLimitStatus);

module.exports = router;
