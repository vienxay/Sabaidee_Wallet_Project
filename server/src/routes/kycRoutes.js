const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
    getKYCStatus,
    submitKYC,
    verifyKYC,
} = require('../controllers/kycController');

const router = express.Router();

router.use(protect);

router.get('/',                getKYCStatus); // GET  /api/kyc
router.post('/submit',         submitKYC);    // POST /api/kyc/submit
router.put('/verify/:userId',  verifyKYC);    // PUT  /api/kyc/verify/:userId (admin)

module.exports = router;