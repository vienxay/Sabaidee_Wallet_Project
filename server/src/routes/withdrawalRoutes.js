// Withdrawal Routes — ຖອນ sats ຜ່ານ Lightning Network
// Flow: limit-status → preview (ກວດ+ຄຳນວນ) → send (ຖອນຈິງ)
// ─── routes/withdrawalRoutes.js ─────────────────────────────────────────────
const express    = require('express');
const { protect } = require('../middleware/authMiddleware');
const withdrawal = require('../controllers/withdrawalController');

const router = express.Router();

router.use(protect);

// GET  /api/withdrawal/limit-status
router.get('/limit-status', withdrawal.getLimitStatus);

// POST /api/withdrawal/preview
router.post('/preview', withdrawal.previewWithdrawal);

// POST /api/withdrawal/send
router.post('/send', withdrawal.sendWithdrawal);

module.exports = router;