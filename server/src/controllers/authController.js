const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Wallet = require('../models/Wallet');
const lnbits = require('../services/lnbitsService');

// ─── Helpers ────────────────────────────────────────────────────────────────

const generateToken = (id) =>
    jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });
    

// ─── POST /api/auth/register ─────────────────────────────────────────────────
exports.register = async (req, res) => {
    try {
        const { walletName, email, password } = req.body;
        const name = walletName;

        if (!name || !email || !password) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນຂໍ້ມູນໃຫ້ຄົບ' });
        }

        const existingUser = await User.findOne({ email: email.toLowerCase() });
        if (existingUser) {
            return res.status(409).json({ success: false, message: 'Email ນີ້ຖືກໃຊ້ງານແລ້ວ' });
        }

        // ── Step 3: ສ້າງ LNbits Wallet ──
        let walletResult;
        try {
            walletResult = await lnbits.createWallet(name);

            // 🔴 ກວດສອບ invoiceKey ດ້ວຍ (ບໍ່ແມ່ນແຕ່ walletId/adminKey)
            if (
                !walletResult ||
                !walletResult.walletId ||
                !walletResult.adminKey ||
                !walletResult.invoiceKey  // ເພີ່ມ
            ) {
                throw new Error('LNbits response is incomplete');
            }
        } catch (walletError) {
            console.error('❌ LNbits Connection Error:', walletError.message);
            return res.status(503).json({
                success: false,
                message: 'ບໍ່ສາມາດສ້າງ Wallet ໄດ້ໃນຂະນະນີ້, ກະລຸນາລອງໃໝ່ພາຍຫຼັງ',
            });
        }

        // ── Steps 4-6: DB Operations ພາຍໃນ try/catch ດຽວ ──
        let user, wallet;
        try {
            user = await User.create({
                name,
                email: email.toLowerCase(),
                password,
            });

            wallet = await Wallet.create({
                user:       user._id,
                walletId:   walletResult.walletId,
                walletName: walletResult.walletName || name,
                adminKey:   walletResult.adminKey,
                invoiceKey: walletResult.invoiceKey,
            });

            user.wallet = wallet._id;
            await user.save({ validateBeforeSave: false });

        } catch (dbError) {
            console.error('❌ DB Error after wallet created:', dbError.message);

            // 🔴 Rollback: ພະຍາຍາມລຶບ Wallet ໃນ LNbits (ຖ້າ API ຮອງຮັບ)
            try {
                await lnbits.deleteWallet(walletResult.walletId, walletResult.adminKey);
                console.log('🔄 LNbits wallet rolled back successfully');
            } catch (rollbackError) {
                // ຖ້າ rollback ບໍ່ສຳເລັດ → log ໄວ້ສຳລັບ manual cleanup
                console.error(
                    '⚠️ MANUAL CLEANUP NEEDED - Orphaned LNbits Wallet:',
                    walletResult.walletId
                );
            }

            // ພະຍາຍາມລຶບ User ທີ່ອາດຖືກສ້າງໄປແລ້ວ
            if (user?._id) {
                await User.findByIdAndDelete(user._id).catch((e) =>
                    console.error('⚠️ Failed to cleanup user:', e.message)
                );
            }

            return res.status(500).json({
                success: false,
                message: 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ, ກະລຸນາລອງໃໝ່',
            });
        }

        const token = generateToken(user._id);
        console.log(`✅ Register ສຳເລັດ: ${user.email} | Wallet: ${wallet.walletId}`);

        return res.status(201).json({
            success: true,
            message: 'ສະໝັກສະມາຊິກ ແລະ ສ້າງ Wallet ສຳເລັດ',
            token,
            user: {
                id:        user._id,
                name:      user.name,
                email:     user.email,
                kycStatus: user.kycStatus || 'pending',
                wallet: {
                    walletId:    wallet.walletId,
                    walletName:  wallet.walletName,
                    invoiceKey:  wallet.invoiceKey,
                    balanceSats: wallet.balanceSats,
                },
            },
        });

    } catch (error) {
        if (error.name === 'ValidationError') {
            const messages = Object.values(error.errors).map((e) => e.message);
            return res.status(400).json({ success: false, message: messages.join(', ') });
        }
        console.error('❌ Register Critical Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── POST /api/auth/login ─────────────────────────────────────────────────────

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນອີເມວ ແລະ ລະຫັດຜ່ານ' });
        }

        const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
        if (!user || !(await user.comparePassword(password))) {
            return res.status(401).json({ success: false, message: 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ' });
        }

        const token = generateToken(user._id);

        res.status(200).json({
            success: true,
            message: 'ເຂົ້າສູ່ລະບົບສຳເລັດ',
            token,
            user: {
                id:        user._id,
                name:      user.name,
                email:     user.email,
                kycStatus: user.kycStatus,
            },
        });
    } catch (error) {
        console.error('Login Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── GET /api/auth/me ─────────────────────────────────────────────────────────

exports.getMe = async (req, res) => {
    try {
        const user = await User.findById(req.user._id).populate('wallet');
        res.status(200).json({
            success: true,
            user: {
                id:        user._id,
                name:      user.name,
                email:     user.email,
                kycStatus: user.kycStatus,
                wallet:    user.wallet,
                createdAt: user.createdAt,
            },
        });
    } catch (error) {
        console.error('Get Me Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── POST /api/auth/logout ────────────────────────────────────────────────────

exports.logout = (req, res) => {
    res.status(200).json({ success: true, message: 'ອອກຈາກລະບົບສຳເລັດ' });
};

// ─── PUT /api/auth/profile ────────────────────────────────────────────────────

exports.updateProfile = async (req, res) => {
    try {
        const { name } = req.body;
        if (!name || name.trim() === '') {
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນຊື່' });
        }
        const user = await User.findByIdAndUpdate(
            req.user.id,
            { name: name.trim() },
            { new: true, runValidators: true }
        );
        res.json({ success: true, user });
    } catch (error) {
        console.error('Update Profile Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── GET /api/auth/google/callback ───────────────────────────────────────────

exports.googleCallback = async (req, res) => {
    try {
        const token = generateToken(req.user._id);
        const redirectUrl = `${process.env.FRONTEND_URL}/auth/callback?token=${token}`;
        res.redirect(redirectUrl);
    } catch (error) {
        console.error('Google Callback Error:', error);
        res.redirect(`${process.env.FRONTEND_URL}/login?error=google_auth_failed`);
    }
};

// ─── GET /api/auth/google/failed ─────────────────────────────────────────────

exports.googleFailed = (req, res) => {
    res.status(401).json({ success: false, message: 'Google authentication failed' });
};