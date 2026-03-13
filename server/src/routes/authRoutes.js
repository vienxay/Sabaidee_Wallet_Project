const express = require('express');
const passport = require('passport');
const { protect } = require('../middleware/authMiddleware');

const {
    register,
    login,
    getMe,
    logout,
    updateProfile,
    googleCallback,
    googleFailed,
} = require('../controllers/authController');

const {
    forgotPassword,
    verifyOTP,
    resetPassword,
    changePassword,
} = require('../controllers/passwordController');

const router = express.Router();

// ─── Auth ─────────────────────────────────────────────────────────────────────
router.post('/register',       register);
router.post('/login',          login);
router.get('/me',    protect,  getMe);
router.post('/logout', protect, logout);

// ─── Profile ──────────────────────────────────────────────────────────────────
router.put('/profile',  protect, updateProfile);
router.put('/password', protect, changePassword);

// ─── Password Reset ───────────────────────────────────────────────────────────
router.post('/forgot-password', forgotPassword);
router.post('/verify-otp',      verifyOTP);
router.post('/reset-password',  resetPassword);

// ─── Google OAuth ─────────────────────────────────────────────────────────────
router.get('/google',
    passport.authenticate('google', { scope: ['profile', 'email'], session: false })
);
router.get('/google/callback',
    passport.authenticate('google', { session: false, failureRedirect: '/api/auth/google/failed' }),
    googleCallback
);
router.get('/google/failed', googleFailed);

module.exports = router;