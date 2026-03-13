const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
    pay,
    decodeInvoice,
} = require('../controllers/paymentController');

const router = express.Router();

router.use(protect);

router.post('/pay',    pay);           // POST /api/payment/pay
router.post('/decode', decodeInvoice); // POST /api/payment/decode

module.exports = router;