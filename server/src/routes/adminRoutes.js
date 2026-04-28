const express  = require('express');
const router   = express.Router();
const User     = require('../models/User');
const Wallet   = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const { protect } = require('../middleware/authMiddleware');

// ✅ Middleware: ກວດ admin role
const adminOnly = (req, res, next) => {
    if (req.user?.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'Admin only' });
    }
    next();
};

const staffOrAdmin = (req, res, next) => {
    if (!['admin', 'staff'].includes(req.user?.role)) {
        return res.status(403).json({ success: false, message: 'Staff or Admin only'});
    }
    next();
}

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
                    _id:         u._id,
                    name:        u.name,
                    email:       u.email,
                    role:        u.role || 'user',
                    kycStatus:   u.kycStatus,
                    balanceSats: wallet?.balanceSats || 0,
                    balanceLAK:  wallet?.balanceLAK  || 0,
                    createdAt:   u.createdAt,
                };
            })
        );

        return res.json({ success: true, data: usersWithBalance });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// adminRoutes.js

// ── POST /api/admin/setup ─────────────────────────────────────────────────
// ✅ ສ້າງ Admin ຄັ້ງທຳອິດ (ໃຊ້ໄດ້ຄັ້ງດຽວ ຖ້າຍັງບໍ່ມີ admin)
router.post('/setup', async (req, res) => {
    try {
        const { name, email, password } = req.body

        // ✅ ກວດວ່າມີ admin ຢູ່ແລ້ວບໍ
        const existingAdmin = await User.findOne({ role: 'admin' })
        if (existingAdmin) {
            return res.status(403).json({
                success: false,
                message: 'ມີ Admin ຢູ່ແລ້ວ — ກະລຸນາ Login'
            })
        }

        const admin = await User.create({
            name, email, password,
            role:      'admin',
            kycStatus: 'verified',
        })

        // ສ້າງ Wallet
        await Wallet.create({ user: admin._id })

        return res.status(201).json({
            success: true,
            message: 'ສ້າງ Admin ສຳເລັດ'
        })
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message })
    }
})

// ── GET /api/admin/has-admin ──────────────────────────────────────────────
// ✅ ກວດວ່າມີ admin ຢູ່ແລ້ວບໍ (ສຳລັບ UI)
router.get('/has-admin', async (req, res) => {
    const count = await User.countDocuments({ role: 'admin' })
    return res.json({ success: true, hasAdmin: count > 0 })
})

// ── POST /api/admin/create-staff ──────────────────────────────────────────
// ✅ Admin ສ້າງ Staff (ຕ້ອງ login ກ່ອນ)
router.post('/create-staff', protect, adminOnly, async (req, res) => {
    try {
        const { name, email, password } = req.body

        const existing = await User.findOne({ email })
        if (existing) {
            return res.status(400).json({
                success: false,
                message: 'Email ນີ້ໃຊ້ແລ້ວ'
            })
        }

        const staff = await User.create({
            name, email, password,
            role:      'staff',
            kycStatus: 'verified',
        })

        return res.status(201).json({
            success: true,
            message: 'ສ້າງ Staff ສຳເລັດ',
            data: { id: staff._id, name, email, role: 'staff' }
        })
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message })
    }
})

// ── PUT /api/admin/users/:id/role ────────────────────────────────────────
router.put('/users/:id/role', protect, adminOnly, async (req, res) => {
    try {
        const { role } = req.body;
        if (!['user', 'admin'].includes(role)) {
            return res.status(400).json({ success: false, message: 'Role ບໍ່ຖືກຕ້ອງ' });
        }
        const user = await User.findByIdAndUpdate(
            req.params.id,
            { role },
            { new: true }
        ).select('-password');

        return res.json({ success: true, data: user });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── DELETE /api/admin/users/:id ──────────────────────────────────────────
router.delete('/users/:id', protect, adminOnly, async (req, res) => {
    try {
        if (req.params.id === req.user._id.toString()) {
            return res.status(400).json({ success: false, message: 'ບໍ່ສາມາດລຶບຕົວເອງໄດ້' });
        }
        await User.findByIdAndDelete(req.params.id);
        return res.json({ success: true, message: 'ລຶບ user ສຳເລັດ' });
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

        // ຍອດ sats ທັງໝົດ
        const wallets = await Wallet.find({});
        const totalSats = wallets.reduce((sum, w) => sum + (w.balanceSats || 0), 0);

        return res.json({
            success: true,
            data: { totalUsers, totalTx, pendingKyc, totalSats },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;