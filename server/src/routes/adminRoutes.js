const express     = require('express');
const router      = express.Router();
const User        = require('../models/User');
const Wallet      = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const Rate        = require('../models/Rate');
const Kyc         = require('../models/Kyc');
const axios       = require('axios');
const { protect } = require('../middleware/authMiddleware');
const exchangeRate = require('../services/exchangeRateService'); 
const Expense = require('../models/Expense')

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
        if (!['user', 'staff', 'admin'].includes(role))  // ✅ ເພີ່ມ staff
            return res.status(400).json({ success: false, message: 'Role ບໍ່ຖືກຕ້ອງ' });

        const user = await User.findByIdAndUpdate(
            req.params.id, { role }, { returnDocument: 'after' }
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
            userId, { role }, { returnDocument: 'after' }
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
        const totalLAK  = wallets.reduce((sum, w) => sum + (w.balanceLAK  || 0), 0); // ✅

        return res.json({
            success: true,
            data: { totalUsers, totalTx, pendingKyc, totalSats, totalLAK }, // ✅
        });
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
        const rateDoc      = await Rate.findOne();
        const spread       = rateDoc?.spreadPercent || 0;
        const usdToLAKBase = rateDoc?.usdToLAK      || 0;
        const btcToUSD     = rateDoc?.btcToUSD       || 0;

        // ✅ ຄຳນວນລາຄາຂາຍລວມ spread
        const usdToLAK = Math.round(usdToLAKBase * (1 + spread / 100));
        const btcToLAK = Math.round(btcToUSD * usdToLAK);

        return res.json({
            success: true,
            rate: {
                usdToLAK,                    // ✅ ລາຄາຂາຍ (ລວມ spread)
                usdToLAKBase,               // ✅ base rate
                spreadPercent : spread,
                btcToUSD,
                btcToLAK,                   // ✅ ລວມ spread
                updatedAt     : rateDoc?.updatedAt,
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── POST /api/admin/rate/update ──────────────────────────────────────────
router.post('/rate/update', protect, adminOnly, async (req, res) => {
    try {
        const { usdToLAK, spreadPercent } = req.body; // ✅ ຮັບທັງ 2

        if (!usdToLAK || usdToLAK <= 0)
            return res.status(400).json({ success: false, message: 'ໃສ່ usdToLAK ທີ່ຖືກຕ້ອງ' });

        if (spreadPercent === undefined || spreadPercent < 0)
            return res.status(400).json({ success: false, message: 'ໃສ່ Spread % ທີ່ຖືກຕ້ອງ (0 ຂຶ້ນໄປ)' });

        const rounded      = Math.round(usdToLAK);
        const spread       = parseFloat(spreadPercent) || 0;
        // ✅ ຄຳນວນລາຄາຂາຍລວມ spread
        const usdToLAKSell = Math.round(rounded * (1 + spread / 100));

        // ✅ ດຶງ BTC/USD
        let btcToUSD = 0;
        try {
            const { data } = await axios.get(
                'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT',
                { timeout: 5000 }
            );
            btcToUSD = parseFloat(data.price);
            console.log('✅ Binance BTC:', btcToUSD);
        } catch {
            try {
                const { data } = await axios.get(
                    'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
                    { timeout: 5000 }
                );
                btcToUSD = data?.bitcoin?.usd ?? 0;
                console.log('✅ CoinGecko BTC:', btcToUSD);
            } catch {
                const existing = await Rate.findOne();
                btcToUSD = existing?.btcToUSD ?? 0;
                console.log('⚠️ ໃຊ້ btcToUSD ເກົ່າ:', btcToUSD);
            }
        }

        // ✅ btcToLAK ໃຊ້ລາຄາຂາຍ (ລວມ spread)
        const btcToLAK = Math.round(btcToUSD * usdToLAKSell);

        const rate = await Rate.findOneAndUpdate(
            {},
            {
                usdToLAK      : rounded,       // ✅ base rate
                spreadPercent : spread,         // ✅ spread %
                btcToUSD,
                btcToLAK,                      // ✅ ລວມ spread
            },
            { returnDocument: 'after', upsert: true }
        );

        exchangeRate.clearCache();

        console.log(`✅ Rate: base=${rounded} | spread=${spread}% | ຂາຍ=${usdToLAKSell} | BTC=$${btcToUSD}`);
        return res.json({ success: true, message: 'ອັບເດດ Rate ສຳເລັດ', rate });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
});

// ── GET /api/admin/report ─────────────────────────────────────────────────
router.get('/report', protect, staffOrAdmin, async (req, res) => {
  try {
    const { from, to, type } = req.query

    const fromDate = from ? new Date(from) : new Date(new Date().setMonth(new Date().getMonth() - 6))
    const toDate   = to   ? new Date(to)   : new Date()
    toDate.setHours(23, 59, 59, 999)

    // ── User Growth PerMonth ──────────────────────────────────────────────
    const userGrowth = await User.aggregate([
      { $match: { createdAt: { $gte: fromDate, $lte: toDate } } },
      { $group: {
        _id: { year: { $year: '$createdAt' }, month: { $month: '$createdAt' } },
        count: { $sum: 1 }
      }},
      { $sort: { '_id.year': 1, '_id.month': 1 } }
    ])

    // ── Transactions ──────────────────────────────────────────────────────
    const txMatch = {
      createdAt: { $gte: fromDate, $lte: toDate },
      status: 'success',
      ...(type && type !== 'all' ? { type } : {}),
    }

    const txByMonth = await Transaction.aggregate([
  { $match: txMatch },
  { $group: {
    _id: {
      year:  { $year:  '$createdAt' },
      month: { $month: '$createdAt' },
      type:  '$type',
    },
    count:      { $sum: 1 },
    totalSats:  { $sum: '$amountSats' },
    totalLAK:   { $sum: '$amountLAK'  },
  }},
  { $sort: { '_id.year': 1, '_id.month': 1 } }
])

// ── Summary ───────────────────────────────────────────────────────────
const summary = await Transaction.aggregate([
  { $match: { createdAt: { $gte: fromDate, $lte: toDate }, status: 'success' } },
  { $group: {
    _id:        '$type',
    count:      { $sum: 1 },
    totalSats:  { $sum: '$amountSats' },
    totalLAK:   { $sum: '$amountLAK'  },
  }}
])

return res.json({ success: true, data: { userGrowth, txByMonth, summary } })
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message })
  }
})

// ── GET /api/admin/report/profit ─────────────────────────────────────────
router.get('/report/profit', protect, adminOnly, async (req, res) => {
  try {
    const { from, to } = req.query

    const fromDate = from ? new Date(from) : new Date(new Date().setMonth(new Date().getMonth() - 6))
    const toDate   = to   ? new Date(to)   : new Date()
    toDate.setHours(23, 59, 59, 999)

    const rate = await Rate.findOne()
    const spreadPercent = rate?.spreadPercent || 0
    const usdToLAKBase  = rate?.usdToLAK     || 0

    // ── ກຳໄລຕໍ່ວັນ — ເພີ່ມ feeSats ──────────────────────────────────────────
    const profitByDay = await Transaction.aggregate([
    {
        $match: {
        createdAt: { $gte: fromDate, $lte: toDate },
        status: 'success',
        type: { $in: ['topup', 'payment', 'withdraw'] },
        }
    },
    {
        $group: {
        _id: {
            year:  { $year:  '$createdAt' },
            month: { $month: '$createdAt' },
            day:   { $dayOfMonth: '$createdAt' },
            type:  '$type',
        },
        totalSats: { $sum: '$amountSats' },
        totalLAK:  { $sum: '$amountLAK'  },
        totalFeeSats: { $sum: '$feeSats' },  // ✅ ເພີ່ມ fee
        count:     { $sum: 1 },
        }
    },
    { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
    ])

    // ── ກຳໄລຕໍ່ເດືອນ ────────────────────────────────────────────────────────
    const profitByMonth = await Transaction.aggregate([
    {
        $match: {
        createdAt: { $gte: fromDate, $lte: toDate },
        status: 'success',
        }
    },
    {
        $group: {
        _id: {
            year:  { $year:  '$createdAt' },
            month: { $month: '$createdAt' },
            type:  '$type',
        },
        totalSats:    { $sum: '$amountSats' },
        totalLAK:     { $sum: '$amountLAK'  },
        totalFeeSats: { $sum: '$feeSats'    },  // ✅ ເພີ່ມ fee
        count:        { $sum: 1 },
        }
    },
    { $sort: { '_id.year': 1, '_id.month': 1 } }
    ])

    // ── ຄຳນວນກຳໄລ ──────────────────────────────────────────────────────
    const calcProfit = (totalLAK, type) => {
      if (type === 'withdraw') return 0
      return Math.round(totalLAK * (spreadPercent / (100 + spreadPercent)))
    }

    const profitDayResult = profitByDay.map(row => ({
      ...row,
      profitLAK: calcProfit(row.totalLAK, row._id.type),
    }))

    const profitMonthResult = profitByMonth.map(row => ({
      ...row,
      profitLAK: calcProfit(row.totalLAK, row._id.type),
    }))

    // ── ກຳໄລລວມ ─────────────────────────────────────────────────────────
    const totalProfitLAK = profitMonthResult
      .filter(r => r._id.type !== 'withdraw')
      .reduce((s, r) => s + r.profitLAK, 0)

    const totalVolumeLAK = profitMonthResult
      .filter(r => r._id.type !== 'withdraw')
      .reduce((s, r) => s + r.totalLAK, 0)

    const totalWithdrawLAK = profitMonthResult
      .filter(r => r._id.type === 'withdraw')
      .reduce((s, r) => s + r.totalLAK, 0)

    // ── ຄ່າໃຊ້ຈ່າຍ ──────────────────────────────────────────────────────
    const expenses = await Expense.find({
      $or: [
        { year: { $gt: new Date(fromDate).getFullYear() } },
        {
          year:  new Date(fromDate).getFullYear(),
          month: { $gte: new Date(fromDate).getMonth() + 1 }
        }
      ]
    }).sort({ year: -1, month: -1 })

    const totalExpenseLAK = expenses.reduce((s, e) => s + e.amount, 0)
    const netProfitLAK    = totalProfitLAK - totalExpenseLAK  // ✅ ກຳໄລສຸດທິ

    return res.json({
      success: true,
      data: {
        spreadPercent,
        usdToLAKBase,
        totalProfitLAK,
        totalVolumeLAK,
        totalWithdrawLAK,
        totalExpenseLAK,   // ✅
        netProfitLAK,      // ✅
        expenses,          // ✅
        profitByDay:   profitDayResult,
        profitByMonth: profitMonthResult,
      }
    })
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message })
  }
})

// ── POST /api/admin/expenses ──────────────────────────────────────────────
router.post('/expenses', protect, adminOnly, async (req, res) => {
  try {
    const { title, amount, category, month, year, note } = req.body
    if (!title || !amount || !month || !year)
      return res.status(400).json({ success: false, message: 'ຂໍ້ມູນບໍ່ຄົບ' })

    const expense = await Expense.create({
      title, amount, category, month, year, note,
      createdBy: req.user._id,
    })
    return res.json({ success: true, data: expense })
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message })
  }
})

// ── DELETE /api/admin/expenses/:id ───────────────────────────────────────
router.delete('/expenses/:id', protect, adminOnly, async (req, res) => {
  try {
    await Expense.findByIdAndDelete(req.params.id)
    return res.json({ success: true, message: 'ລຶບສຳເລັດ' })
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message })
  }
})

// ── GET /api/admin/report/top-users ──────────────────────────────────────
router.get('/report/top-users', protect, staffOrAdmin, async (req, res) => {
  try {
    const { from, to, limit = 10 } = req.query
    const fromDate = from ? new Date(from) : new Date(new Date().setMonth(new Date().getMonth() - 6))
    const toDate   = to   ? new Date(to)   : new Date()
    toDate.setHours(23, 59, 59, 999)

    const topUsers = await Transaction.aggregate([
      {
        $match: {
          createdAt: { $gte: fromDate, $lte: toDate },
          status: 'success',
          type: 'topup',
        }
      },
      {
        $group: {
          _id:       '$user',
          totalSats: { $sum: '$amountSats' },
          totalLAK:  { $sum: '$amountLAK'  },
          count:     { $sum: 1 },
        }
      },
      { $sort: { totalLAK: -1 } },
      { $limit: parseInt(limit) },
      {
        $lookup: {
          from:         'users',
          localField:   '_id',
          foreignField: '_id',
          as:           'user',
        }
      },
      { $unwind: '$user' },
      {
        $project: {
          name:      '$user.name',
          email:     '$user.email',
          totalSats: 1,
          totalLAK:  1,
          count:     1,
        }
      }
    ])

    return res.json({ success: true, data: topUsers })
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message })
  }
})

module.exports = router; 