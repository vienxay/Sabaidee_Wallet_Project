const Transaction  = require('../models/Transaction');
const exchangeRate = require('../services/exchangeRateService');
const lnbits       = require('../services/lnbitsService');
const Wallet       = require('../models/Wallet');

// ─── GET /api/transactions ────────────────────────────────────────────────────
// ດຶງປະຫວັດທຸລະກຳທັງໝົດ (pagination)
// type query: topup | withdraw | pay | receive | laoQR

exports.getTransactions = async (req, res) => {
    try {
        const page  = parseInt(req.query.page)  || 1;
        const limit = parseInt(req.query.limit) || 20;
        const type  = req.query.type;
        const skip  = (page - 1) * limit;

        const filter = { user: req.user._id };
        if (type) filter.type = type;

        const [transactions, total] = await Promise.all([
            Transaction.find(filter)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            Transaction.countDocuments(filter),
        ]);

        res.status(200).json({
            success: true,
            transactions,
            pagination: {
                page, limit,
                total,
                pages: Math.ceil(total / limit),
            },
        });
    } catch (error) {
        console.error('Get Transactions Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── GET /api/transactions/:id ────────────────────────────────────────────────
// ດຶງລາຍລະອຽດ transaction

exports.getTransaction = async (req, res) => {
    try {
        const transaction = await Transaction.findOne({
            _id:  req.params.id,
            user: req.user._id,
        });

        if (!transaction) {
            return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Transaction' });
        }

        res.status(200).json({ success: true, transaction });
    } catch (error) {
        console.error('Get Transaction Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── GET /api/transactions/check/:paymentHash ─────────────────────────────────
// ກວດສະຖານະ invoice (polling ຈາກ frontend ຫຼັງ topup)

exports.checkPaymentStatus = async (req, res) => {
    try {
        const { paymentHash } = req.params;

        const wallet = await Wallet.findOne({ user: req.user._id });
        if (!wallet) return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Wallet' });

        const status = await lnbits.checkPayment({ invoiceKey: wallet.invoiceKey, paymentHash });

        // ໃນ checkPaymentStatus
        if (status.paid) {
            const transaction = await Transaction.findOne({ paymentHash, user: req.user._id });

            // ໃຫ້ອັບເດດ Balance ສະເພາະຕອນທີ່ Status ຍັງເປັນ pending ເທົ່ານັ້ນ
            if (transaction && transaction.status === 'pending') {
                transaction.status = 'success';
                await transaction.save();

                if (transaction.type === 'topup') {
                    const balance = await lnbits.getBalance(wallet.invoiceKey);
                    wallet.balanceSats = balance.balanceSats;
                    await wallet.save();
                }
            }
        }

        res.status(200).json({
            success:     true,
            paid:        status.paid,
            paymentHash,
            transaction: status.paid ? await Transaction.findOne({ paymentHash }) : null,
        });
    } catch (error) {
        console.error('Check Payment Status Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── GET /api/transactions/summary ───────────────────────────────────────────
// ສະຫຼຸບຍອດໃຊ້ຈ່າຍ (ສຳລັບ dashboard)

exports.getSummary = async (req, res) => {
    try {
        const startOfMonth = new Date();
        startOfMonth.setDate(1);
        startOfMonth.setHours(0, 0, 0, 0);

        const [summary, rate] = await Promise.all([
            Transaction.aggregate([
                {
                    $match: {
                        user:      req.user._id,
                        status:    'success',
                        createdAt: { $gte: startOfMonth },
                    },
                },
                {
                    $group: {
                        _id:       '$type',
                        totalSats: { $sum: '$amountSats' },
                        totalLAK:  { $sum: '$amountLAK' },
                        count:     { $sum: 1 },
                    },
                },
            ]),
            exchangeRate.getExchangeRate(),
        ]);

        // ✅ ເພີ່ມ laoQR ໃນ default result
        const result = {
            topup:    null,
            withdraw: null,
            pay:      null,
            receive:  null,
            laoQR:    null, // ✅
        };
        summary.forEach((s) => { result[s._id] = s; });

        res.status(200).json({
            success: true,
            month:   startOfMonth.toISOString().slice(0, 7),
            summary: result,
            rate:    { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD },
        });
    } catch (error) {
        console.error('Get Summary Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};