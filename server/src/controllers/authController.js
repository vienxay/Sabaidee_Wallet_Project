const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Wallet = require('../models/Wallet');
const lnbits = require('../services/lnbitsService');
const { cloudinary } = require('../services/cloudinaryService');

const generateToken = (id) =>
    jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

// ─── POST /api/auth/register ──────────────────────────────────────────────────
exports.register = async (req, res) => {
    try {
        const { walletName, email, password } = req.body;
        const name = walletName;

        if (!name || !email || !password)
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນຂໍ້ມູນໃຫ້ຄົບ' });

        const existingUser = await User.findOne({ email: email.toLowerCase() });
        if (existingUser)
            return res.status(409).json({ success: false, message: 'Email ນີ້ຖືກໃຊ້ງານແລ້ວ' });

        let walletResult;
        try {
            walletResult = await lnbits.createWallet(name);
            if (!walletResult?.walletId || !walletResult?.adminKey || !walletResult?.invoiceKey)
                throw new Error('LNbits response is incomplete');
        } catch (walletError) {
            console.error('❌ LNbits Connection Error:', walletError.message);
            return res.status(503).json({ success: false, message: 'ບໍ່ສາມາດສ້າງ Wallet ໄດ້' });
        }

        let user, wallet;
        try {
            user = await User.create({ name, email: email.toLowerCase(), password });
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
            console.error('❌ DB Error:', dbError.message);
            try { await lnbits.deleteWallet(walletResult.walletId, walletResult.adminKey); } catch (_) {}
            if (user?._id) await User.findByIdAndDelete(user._id).catch(() => {});
            return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ' });
        }

        const token = generateToken(user._id);
        return res.status(201).json({
            success: true,
            message: 'ສ້າງ Wallet ສຳເລັດ',
            token,
            user: {
                id: user._id, name: user.name, email: user.email,
                profileImage: user.profileImage,
                kycStatus: user.kycStatus || 'pending',
                wallet: { walletId: wallet.walletId, walletName: wallet.walletName, invoiceKey: wallet.invoiceKey, balanceSats: wallet.balanceSats },
            },
        });
    } catch (error) {
        console.error('❌ Register Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── POST /api/auth/login ─────────────────────────────────────────────────────
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password)
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນອີເມວ ແລະ ລະຫັດຜ່ານ' });

        const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
        if (!user || !(await user.comparePassword(password)))
            return res.status(401).json({ success: false, message: 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ' });

        const token = generateToken(user._id);
        res.status(200).json({
            success: true,
            message: 'ເຂົ້າສູ່ລະບົບສຳເລັດ',
            token,
            user: {
                id: user._id, name: user.name, email: user.email,
                profileImage: user.profileImage, // ✅
                kycStatus: user.kycStatus,
                role: user.role,
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
                id: user._id, name: user.name, email: user.email,
                profileImage: user.profileImage, // ✅
                kycStatus: user.kycStatus,
                wallet: user.wallet,
                createdAt: user.createdAt,
                
            },
        });
    } catch (error) {
        console.error('Get Me Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── PUT /api/auth/profile ────────────────────────────────────────────────────
exports.updateProfile = async (req, res) => {
    try {
        const { name } = req.body;
        if (!name?.trim())
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນຊື່' });

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

// ─── PUT /api/auth/profile/image ✅ ───────────────────────────────────────────
exports.updateProfileImage = async (req, res) => {
    try {
        if (!req.file)
            return res.status(400).json({ success: false, message: 'ກະລຸນາເລືອກຮູບ' });

        // ລົບຮູບເກົ່າຈາກ Cloudinary
        const user = await User.findById(req.user._id);
        if (user.profileImage) {
            const publicId = user.profileImage.split('/').slice(-2).join('/').split('.')[0];
            await cloudinary.uploader.destroy(publicId).catch(() => {});
        }

        const imageUrl = req.file.path; // Cloudinary URL
        const updated = await User.findByIdAndUpdate(
            req.user._id,
            { profileImage: imageUrl },
            { new: true }
        );

        res.status(200).json({
            success: true,
            message: 'ອັບເດດຮູບໂປຣໄຟລ໌ສຳເລັດ',
            profileImage: updated.profileImage,
        });
    } catch (error) {
        console.error('Update Profile Image Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── POST /api/auth/logout ────────────────────────────────────────────────────
exports.logout = (req, res) => {
    res.status(200).json({ success: true, message: 'ອອກຈາກລະບົບສຳເລັດ' });
};

// ─── Google OAuth ─────────────────────────────────────────────────────────────
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

exports.googleFailed = (req, res) => {
    res.status(401).json({ success: false, message: 'Google authentication failed' });
};