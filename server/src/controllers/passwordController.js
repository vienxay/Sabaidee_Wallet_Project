const crypto = require('crypto');
const User = require('../models/User');
const { sendOTPEmail } = require('../services/emailService');

// ─── Helper ───────────────────────────────────────────────────────────────────

const generateOTP = () =>
    Math.floor(100000 + Math.random() * 900000).toString();

// ─── POST /api/auth/forgot-password ──────────────────────────────────────────

exports.forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນອີເມວ' });
        }

        const user = await User.findOne({ email: email.toLowerCase() });

        // ສົ່ງ message ດຽວກັນ ບໍ່ວ່າ user ຈະມີ ຫຼື ບໍ່ (ປ້ອງກັນ Email Enumeration)
        if (!user) {
            return res.status(200).json({ success: true, message: 'ຖ້າອີເມວນີ້ມີໃນລະບົບ, ລະຫັດ OTP ຈະຖືກສົ່ງໄປ' });
        }

        const otp = generateOTP();
        user.resetPasswordOTP = crypto.createHash('sha256').update(otp).digest('hex');
        user.resetPasswordOTPExpiry = Date.now() + 10 * 60 * 1000; // 10 ນາທີ
        user.resetPasswordOTPVerified = false;
        await user.save({ validateBeforeSave: false });

        const emailResult = await sendOTPEmail(user.email, otp, user.name);

        if (!emailResult.success) {
            user.resetPasswordOTP = undefined;
            user.resetPasswordOTPExpiry = undefined;
            await user.save({ validateBeforeSave: false });
            return res.status(500).json({ success: false, message: 'ສົ່ງ OTP ບໍ່ສຳເລັດ, ກະລຸນາລອງໃໝ່' });
        }

        res.status(200).json({ success: true, message: 'ຖ້າອີເມວນີ້ມີໃນລະບົບ, ລະຫັດ OTP ຈະຖືກສົ່ງໄປ' });
    } catch (error) {
        console.error('Forgot Password Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── POST /api/auth/verify-otp ───────────────────────────────────────────────

exports.verifyOTP = async (req, res) => {
    try {
        const { email, otp } = req.body;

        if (!email || !otp) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນອີເມວ ແລະ OTP' });
        }

        const user = await User.findOne({ email: email.toLowerCase() })
            .select('+resetPasswordOTP +resetPasswordOTPExpiry +resetPasswordOTPVerified');

        if (!user) {
            return res.status(400).json({ success: false, message: 'OTP ບໍ່ຖືກຕ້ອງ ຫຼື ໝົດອາຍຸ' });
        }
        if (!user.resetPasswordOTPExpiry || user.resetPasswordOTPExpiry < Date.now()) {
            return res.status(400).json({ success: false, message: 'OTP ໝົດອາຍຸແລ້ວ' });
        }

        const hashedOTP = crypto.createHash('sha256').update(otp).digest('hex');
        if (hashedOTP !== user.resetPasswordOTP) {
            return res.status(400).json({ success: false, message: 'OTP ບໍ່ຖືກຕ້ອງ' });
        }

        user.resetPasswordOTPVerified = true;
        await user.save({ validateBeforeSave: false });

        res.status(200).json({ success: true, message: 'OTP ຖືກຕ້ອງ', verified: true });
    } catch (error) {
        console.error('Verify OTP Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── POST /api/auth/reset-password ───────────────────────────────────────────

exports.resetPassword = async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;

        if (!email || !otp || !newPassword) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນຂໍ້ມູນໃຫ້ຄົບ' });
        }
        if (newPassword.length < 6) {
            return res.status(400).json({ success: false, message: 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງນ້ອຍ 6 ຕົວອັກສອນ' });
        }

        const user = await User.findOne({ email: email.toLowerCase() })
            .select('+resetPasswordOTP +resetPasswordOTPExpiry +resetPasswordOTPVerified');

        if (!user) {
            return res.status(400).json({ success: false, message: 'ບໍ່ພົບຜູ້ໃຊ້' });
        }
        if (!user.resetPasswordOTPVerified) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາຢືນຢັນ OTP ກ່ອນ' });
        }

        const hashedOTP = crypto.createHash('sha256').update(otp).digest('hex');
        if (hashedOTP !== user.resetPasswordOTP || !user.resetPasswordOTPExpiry || user.resetPasswordOTPExpiry < Date.now()) {
            return res.status(400).json({ success: false, message: 'OTP ບໍ່ຖືກຕ້ອງ ຫຼື ໝົດອາຍຸ' });
        }

        // ລ້າງ OTP fields ຫຼັງ reset ສຳເລັດ
        user.password = newPassword;
        user.resetPasswordOTP = undefined;
        user.resetPasswordOTPExpiry = undefined;
        user.resetPasswordOTPVerified = undefined;
        await user.save();

        res.status(200).json({ success: true, message: 'ຣີເຊັດລະຫັດຜ່ານສຳເລັດ' });
    } catch (error) {
        console.error('Reset Password Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── PUT /api/auth/password ───────────────────────────────────────────────────

exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນຂໍ້ມູນໃຫ້ຄົບ' });
        }
        if (newPassword.length < 6) {
            return res.status(400).json({ success: false, message: 'ລະຫັດໃໝ່ຕ້ອງມີຢ່າງນ້ອຍ 6 ຕົວ' });
        }

        const user = await User.findById(req.user.id).select('+password');
        if (!(await user.comparePassword(currentPassword))) {
            return res.status(401).json({ success: false, message: 'ລະຫັດຜ່ານປະຈຸບັນບໍ່ຖືກຕ້ອງ' });
        }

        user.password = newPassword;
        await user.save();

        res.json({ success: true, message: 'ປ່ຽນລະຫັດຜ່ານສຳເລັດ' });
    } catch (error) {
        console.error('Change Password Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};