const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Middleware: ກວດສອບ JWT Token
const protect = async (req, res, next) => {
    try {
        // ກວດສອບ JWT_SECRET ກ່ອນ
        if (!process.env.JWT_SECRET) {
            console.error('JWT_SECRET ບໍ່ຖືກກຳນົດ');
            return res.status(500).json({
                success: false,
                message: 'ລະບົບມີຂໍ້ຜິດພາດ',
            });
        }

        let token;

        // ກວດສອບ Authorization header
        if (
            req.headers.authorization &&
            req.headers.authorization.startsWith('Bearer')
        ) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'ກະລຸນາເຂົ້າສູ່ລະບົບກ່ອນ',
            });
        }

        // Verify token
        let decoded;
        try {
            decoded = jwt.verify(token, process.env.JWT_SECRET);
        } catch (jwtError) {
            // ບໍ່ບອກລະອຽດວ່າ error ຍັງໃດ - ປ້ອງກັນ information leakage
            return res.status(401).json({
                success: false,
                message: 'ກະລຸນາເຂົ້າສູ່ລະບົບອີກຄັ້ງ',
            });
        }

        // ຄົ້ນຫາ user ໂດຍບໍ່ສົ່ງ password ແລະ sensitive fields
        const user = await User.findById(decoded.id)
            .select('-password -resetPasswordOTP -resetPasswordOTPExpiry -resetPasswordOTPVerified -wallet.adminKey');

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'ບັນຊີຜູ້ໃຊ້ບໍ່ມີໃນລະບົບ',
            });
        }

        req.user = user;
        next();
        
    } catch (error) {
        console.error('Protect Middleware Error:', error);
        return res.status(500).json({
            success: false,
            message: 'ລະບົບມີຂໍ້ຜິດພາດ',
        });
    }
};

module.exports = { protect };