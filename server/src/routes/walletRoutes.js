// Wallet Routes — ຈັດການ wallet: balance, rate, topup, withdraw
// ທຸກ route ຕ້ອງ login (protect middleware)
const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
    getWallet,
    getBalance,
    getRate,
    topUp,
    withdraw,
    checkPaymentStatus, // ✅ ເພີ່ມ
} = require('../controllers/walletController');

const router = express.Router();

router.use(protect); // ທຸກ route ຕ້ອງ login

router.get('/',                          getWallet);           // GET  /api/wallet
router.get('/balance',                   getBalance);          // GET  /api/wallet/balance
router.get('/rate',                      getRate);             // GET  /api/wallet/rate
router.post('/topup',                    topUp);               // POST /api/wallet/topup
router.post('/withdraw',                 withdraw);            // POST /api/wallet/withdraw
router.get('/topup/:paymentHash/status', checkPaymentStatus);  // GET  /api/wallet/topup/:hash/status ✅

module.exports = router;