const express     = require('express');
const router      = express.Router();
const User        = require('../models/User');
const Wallet      = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const Rate        = require('../models/Rate');
const Kyc         = require('../models/Kyc');
const axios       = require('axios');
const { protect } = require('../middleware/authMiddleware');
const exchangeRate = require('../services/exchangeRateService'); // ✅ ເພີ່ມ

// ── Middleware ───────────────────────────────────────────────────────────
const adminOnly = (req, res, next) => {
    if (req.user?.role !== 'admin')
        return res.status(403).json({ success: false, message: 'Admin only' });
    next();
};

const staffOrAdmin = (req, res, next) => {
    if (!['admin', 'staff'].includes(req.user?.role))
        return res.status(403).json({ success: false, message: 'Staff or Admin only' });
    next();
};

// ── GET /api/admin/users ─────────────────────────────────────────────────
router.get('/users', protect, adminOnly, async (req, res) => {
    try {
        const users = await User.find({})
            .select('-password')
            .sort({ createdAt: -1 });

        const usersWithBalance = await Promise.all(
            users.map(async (u) => {
                const wallet = await Wallet.findOne({ user: u._id });
                return {
                    _id        : u._id,
                    name       : u.name,
                    email      : u.email,
                    role       : u.role || 'user',
                    kycStatus  : u.kycStatus,
                    balanceSats: wallet?.balanceSats || 0,
                    balanceLAK : wallet?.balanceLAK  || 0,
                    createdAt  : u.createdAt,
                };
            })
        );

        return res.json({ success: true, data: usersWithBalance });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── POST /api/admin/setup ────────────────────────────────────────────────
router.post('/setup', async (req, res) => {
    try {
        const { name, email, password } = req.body;
        const existingAdmin = await User.findOne({ role: 'admin' });
        if (existingAdmin)
            return res.status(403).json({ success: false, message: 'ມີ Admin ຢູ່ແລ້ວ — ກະລຸນາ Login' });

        const admin = await User.create({ name, email, password, role: 'admin', kycStatus: 'verified' });
        await Wallet.create({ user: admin._id });

        return res.status(201).json({ success: true, message: 'ສ້າງ Admin ສຳເລັດ' });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── GET /api/admin/has-admin ─────────────────────────────────────────────
router.get('/has-admin', async (req, res) => {
    const count = await User.countDocuments({ role: 'admin' });
    return res.json({ success: true, hasAdmin: count > 0 });
});

// ── POST /api/admin/create-staff ─────────────────────────────────────────
router.post('/create-staff', protect, adminOnly, async (req, res) => {
    try {
        const { name, email, password } = req.body;
        const existing = await User.findOne({ email });
        if (existing)
            return res.status(400).json({ success: false, message: 'Email ນີ້ໃຊ້ແລ້ວ' });

        const staff = await User.create({ name, email, password, role: 'staff', kycStatus: 'verified' });
        return res.status(201).json({
            success: true, message: 'ສ້າງ Staff ສຳເລັດ',
            data: { id: staff._id, name, email, role: 'staff' },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── PUT /api/admin/users/:id/role ────────────────────────────────────────
router.put('/users/:id/role', protect, adminOnly, async (req, res) => {
    try {
        const { role } = req.body;
        if (!['user', 'admin'].includes(role))
            return res.status(400).json({ success: false, message: 'Role ບໍ່ຖືກຕ້ອງ' });

        const user = await User.findByIdAndUpdate(
            req.params.id, { role }, { new: true }
        ).select('-password');
        return res.json({ success: true, data: user });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── DELETE /api/admin/users/:id ──────────────────────────────────────────
router.delete('/users/:id', protect, adminOnly, async (req, res) => {
    try {
        if (req.params.id === req.user._id.toString())
            return res.status(400).json({ success: false, message: 'ບໍ່ສາມາດລຶບຕົວເອງໄດ້' });

        await User.findByIdAndDelete(req.params.id);
        return res.json({ success: true, message: 'ລຶບ user ສຳເລັດ' });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── POST /api/admin/users/role ───────────────────────────────────────────
router.post('/users/role', protect, adminOnly, async (req, res) => {
    try {
        const { userId, role } = req.body;
        if (!['user', 'staff', 'admin'].includes(role))
            return res.status(400).json({ success: false, message: 'Role ບໍ່ຖືກຕ້ອງ' });

        const user = await User.findByIdAndUpdate(
            userId, { role }, { new: true }
        ).select('-password');
        return res.json({ success: true, data: user });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── GET /api/admin/stats ─────────────────────────────────────────────────
router.get('/stats', protect, adminOnly, async (req, res) => {
    try {
        const [totalUsers, totalTx, pendingKyc] = await Promise.all([
            User.countDocuments({}),
            Transaction.countDocuments({ status: 'success' }),
            User.countDocuments({ kycStatus: 'pending' }),
        ]);
        const wallets   = await Wallet.find({});
        const totalSats = wallets.reduce((sum, w) => sum + (w.balanceSats || 0), 0);

        return res.json({ success: true, data: { totalUsers, totalTx, pendingKyc, totalSats } });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── GET /api/admin/kyc ───────────────────────────────────────────────────
router.get('/kyc', protect, staffOrAdmin, async (req, res) => {
    try {
        const { status = 'pending' } = req.query;
        const kycs = await Kyc.find({ status })
            .populate('user', 'name email profileImage')
            .sort({ createdAt: -1 });

        const list = kycs.map(k => ({
            _id         : k.user?._id,
            name        : k.user?.name,
            email       : k.user?.email,
            profileImage: k.user?.profileImage,
            kycStatus   : k.status,
            gender      : k.gender,
            dob         : k.dob,
            nationality : k.nationality,
            passportNo  : k.passportNumber,
            expiry      : k.expiryDate,
            refId       : k.referenceId,
            images      : [k.idFrontUrl, k.selfieUrl].filter(Boolean),
        }));

        return res.json({ success: true, kycs: list });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── POST /api/admin/kyc/review ───────────────────────────────────────────
router.post('/kyc/review', protect, staffOrAdmin, async (req, res) => {
    try {
        const { userId, status, note } = req.body;
        if (!['verified', 'rejected'].includes(status))
            return res.status(400).json({ success: false, message: 'Status ບໍ່ຖືກຕ້ອງ' });

        await User.findByIdAndUpdate(userId, { kycStatus: status });
        await Kyc.findOneAndUpdate({ user: userId }, { status, note });

        return res.json({ success: true, message: 'ອັບເດດ KYC ສຳເລັດ' });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── GET /api/admin/rate ──────────────────────────────────────────────────
router.get('/rate', protect, staffOrAdmin, async (req, res) => {
    try {
        const rate = await Rate.findOne();
        return res.json({ success: true, rate });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── POST /api/admin/rate/update ──────────────────────────────────────────
router.post('/rate/update', protect, adminOnly, async (req, res) => {
    try {
        const { usdToLAK } = req.body;
        if (!usdToLAK || usdToLAK <= 0)
            return res.status(400).json({ success: false, message: 'ໃສ່ຕົວເລກທີ່ຖືກຕ້ອງ' });

        const rounded = Math.round(usdToLAK);

        // ✅ ລອງ 3 API ຕາມລຳດັບ
        let btcToUSD = 0;
        try {
            // ລອງ Binance ກ່ອນ (ບໍ່ມີ rate limit)
            const { data } = await axios.get(
                'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT',
                { timeout: 5000 }
            );
            btcToUSD = parseFloat(data.price);
            console.log('✅ Binance BTC:', btcToUSD);
        } catch {
            try {
                // ລອງ CoinGecko
                const { data } = await axios.get(
                    'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
                    { timeout: 5000 }
                );
                btcToUSD = data?.bitcoin?.usd ?? 0;
                console.log('✅ CoinGecko BTC:', btcToUSD);
            } catch {
                // ໃຊ້ຄ່າເກົ່າຈາກ DB
                const existing = await Rate.findOne();
                btcToUSD = existing?.btcToUSD ?? 0;
                console.log('⚠️ ໃຊ້ btcToUSD ເກົ່າ:', btcToUSD);
            }
        }

        const btcToLAK = Math.round(btcToUSD * rounded);

        const rate = await Rate.findOneAndUpdate(
            {},
            { usdToLAK: rounded, btcToUSD, btcToLAK },
            { returnDocument: 'after', upsert: true }
        );

        exchangeRate.clearCache();

        console.log(`✅ Rate saved: 1USD=${rounded} | BTC=$${btcToUSD} | BTC=${btcToLAK.toLocaleString()}ກີບ`);
        return res.json({ success: true, message: 'ອັບເດດ Rate ສຳເລັດ', rate });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;