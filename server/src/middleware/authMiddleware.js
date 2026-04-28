const jwt  = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
    try {
        if (!process.env.JWT_SECRET) {
            return res.status(500).json({ success: false, message: 'ລະບົບມີຂໍ້ຜິດພາດ' });
        }

        let token;
        if (req.headers.authorization?.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }
        if (!token) {
            return res.status(401).json({ success: false, message: 'ກະລຸນາເຂົ້າສູ່ລະບົບກ່ອນ' });
        }

        let decoded;
        try {
            decoded = jwt.verify(token, process.env.JWT_SECRET);
        } catch {
            return res.status(401).json({ success: false, message: 'ກະລຸນາເຂົ້າສູ່ລະບົບອີກຄັ້ງ' });
        }

        const user = await User.findById(decoded.id)
            .select('-password -resetPasswordOTP -resetPasswordOTPExpiry -resetPasswordOTPVerified');
        if (!user) {
            return res.status(401).json({ success: false, message: 'ບັນຊີຜູ້ໃຊ້ບໍ່ມີໃນລະບົບ' });
        }

        req.user = user;
        next();
    } catch (error) {
        console.error('Protect Middleware Error:', error);
        return res.status(500).json({ success: false, message: 'ລະບົບມີຂໍ້ຜິດພາດ' });
    }
};

const adminOnly = (req, res, next) => {
    if (req.user?.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'ສະເພາະ Admin ເທົ່ານັ້ນ' });
    }
    next();
};

// ✅ ເພີ່ມ — staff + admin ເຂົ້າໄດ້
const adminOrStaff = (req, res, next) => {
    if (!['admin', 'staff'].includes(req.user?.role)) {
        return res.status(403).json({ success: false, message: 'ບໍ່ມີສິດເຂົ້າເຖິງ' });
    }
    next();
};

module.exports = { protect, adminOnly, adminOrStaff }; // ✅ export ເພີ່ມ