const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
    getTransactions,
    getTransaction,
    checkPaymentStatus,
    getSummary,
} = require('../controllers/transactionController');

const router = express.Router();

router.use(protect);

router.get('/',                   getTransactions);    // GET /api/transactions
router.get('/summary',            getSummary);         // GET /api/transactions/summary
router.get('/check/:paymentHash', checkPaymentStatus); // GET /api/transactions/check/:hash
router.get('/:id',                getTransaction);     // GET /api/transactions/:id

module.exports = router;