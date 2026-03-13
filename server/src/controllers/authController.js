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
        // 1. ຮັບຂໍ້ມູນຈາກ Body (ໃຊ້ walletName ໃຫ້ກົງກັບທີ່ Flutter ສົ່ງມາ)
        const { walletName, email, password } = req.body;
        const name = walletName; // ໃຊ້ walletName ເປັນຊື່ User ເລີຍ

        if (!name || !email || !password) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນຂໍ້ມູນໃຫ້ຄົບ' });
        }

        // 2. ກວດສອບ Email ຊ້ຳກ່ອນຈະໄປລົມກັບ LNbits (ເພື່ອປະຫຍັດ Resource)
        const existingUser = await User.findOne({ email: email.toLowerCase() });
        if (existingUser) {
            return res.status(409).json({ success: false, message: 'Email ນີ້ຖືກໃຊ້ງານແລ້ວ' });
        }

        // 3. 🔥 ຂັ້ນຕອນສຳຄັນ: ພະຍາຍາມສ້າງ Lightning Wallet ໃນ LNbits ກ່ອນ
        let walletResult;
        try {
            walletResult = await lnbits.createWallet(name);
            
            // ກວດສອບວ່າ LNbits ສົ່ງຂໍ້ມູນທີ່ຈຳເປັນມາຄົບຫຼືບໍ່
            if (!walletResult || !walletResult.walletId || !walletResult.adminKey) {
                throw new Error('LNbits response is incomplete');
            }
        } catch (walletError) {
            console.error('❌ LNbits Connection Error:', walletError.message);
            // ຖ້າສ້າງ Wallet ບໍ່ໄດ້ ໃຫ້ຕອບກັບ Error ທັນທີ ແລະ ຢຸດການເຮັດວຽກ
            return res.status(503).json({ 
                success: false, 
                message: 'ບໍ່ສາມາດສ້າງ Wallet ໄດ້ໃນຂະນະນີ້ (LNbits Offline), ກະລຸນາລອງໃໝ່ພາຍຫຼັງ' 
            });
        }

        // 4. ເມື່ອສ້າງ Wallet ສຳເລັດແລ້ວ ຈຶ່ງຄ່ອຍສ້າງ User ໃນ Database
        const user = await User.create({ 
            name, 
            email: email.toLowerCase(), 
            password 
        });

        // 5. ສ້າງ Record ໃນ Collection Wallet ຂອງເຮົາເອງ
        const wallet = await Wallet.create({
            user:       user._id,
            walletId:   walletResult.walletId,
            walletName: walletResult.walletName || name,
            adminKey:   walletResult.adminKey,
            invoiceKey: walletResult.invoiceKey,
        });

        // 6. ຜູກ Wallet ID ໃສ່ກັບ User
        user.wallet = wallet._id;
        await user.save({ validateBeforeSave: false });

        const token = generateToken(user._id);

        console.log(`✅ Register ສຳເລັດ: User ${user.email} ພ້ອມ Wallet ${wallet.walletId}`);

        res.status(201).json({
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