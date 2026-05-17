const express = require('express');
const passport = require('passport');
const { protect } = require('../middleware/authMiddleware');
const { upload } = require('../services/cloudinaryService'); // ✅

const {
    register, login, getMe, logout,
    googleCallback, googleFailed,
} = require('../controllers/authController');

const {
    forgotPassword, verifyOTP, resetPassword,
} = require('../controllers/passwordController');

const router = express.Router();

// ─── Auth ─────────────────────────────────────────────────────────────────────
router.post('/register',  register);
router.post('/login',     login);
router.get('/me',         protect, getMe);
router.post('/logout',    protect, logout);

// ─── Password Reset ───────────────────────────────────────────────────────────
router.post('/forgot-password', forgotPassword);
router.post('/verify-otp',      verifyOTP);
router.post('/reset-password',  resetPassword);

// ─── Google OAuth ─────────────────────────────────────────────────────────────
// state=register → ຖ້າ email ມີຢູ່ແລ້ວ ຈະ redirect ໄປ login ພ້ອມ error
// state=login    → login ປົກກະຕິ
router.get('/google', (req, res, next) => {
    const state = req.query.state || 'login';
    passport.authenticate('google', {
        scope:   ['profile', 'email'],
        session: false,
        state,
    })(req, res, next);
});
router.get('/google/callback',
    passport.authenticate('google', { session: false, failureRedirect: '/api/auth/google/failed' }),
    googleCallback
);
router.get('/google/failed', googleFailed);

module.exports = router;