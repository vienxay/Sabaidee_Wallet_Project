// ຈັດການ Transaction history: ດຶງລາຍການ, ກວດສະຖານະ, ສະຫຼຸບ
// Transaction types: topup | withdraw | pay | laoQR | receive
const Transaction  = require('../models/Transaction');
const exchangeRate = require('../services/exchangeRateService');
const lnbits       = require('../services/lnbitsService');
const Wallet       = require('../models/Wallet');

// ─── GET /api/transactions ────────────────────────────────────────────────────
// ດຶງປະຫວັດທຸລະກຳ (paginated) — sort ໃໝ່ສຸດກ່ອນ
// query: page (default 1), limit (default 20), type (filter ຕາມ type)
exports.getTransactions = async (req, res) => {
    try {
        const page  = parseInt(req.query.page)  || 1;
        const limit = parseInt(req.query.limit) || 20;
        const type  = req.query.type;
        const skip  = (page - 1) * limit;

        const filter = { user: req.user._id };
        if (type) filter.type = type; // filter ສະເພາະ type ຖ້າສ່ົງ query

        // ດຶງ transactions ແລະ total count ພ້ອມກັນ (parallel) ເພື່ອ performance
        const [transactions, total] = await Promise.all([
            Transaction.find(filter)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .lean(), // lean() = return plain JS object ໄວກວ່າ Mongoose document
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
// ດຶງລາຍລະອຽດ transaction ດຽວ — ກວດ user ownership ກັນ cross-user access
exports.getTransaction = async (req, res) => {
    try {
        const transaction = await Transaction.findOne({
            _id:  req.params.id,
            user: req.user._id, // ຕ້ອງ query ທັງ _id ແລະ user ເພື່ອຄວາມປອດໄພ
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
// ກວດສະຖານະ Lightning invoice — Flutter polling ໜ້ານີ້ຫຼັງ topup
// ຖ້າ paid=true → update transaction + sync balance ຈາກ LNBits
exports.checkPaymentStatus = async (req, res) => {
    try {
        const { paymentHash } = req.params;

        const wallet = await Wallet.findOne({ user: req.user._id });
        if (!wallet) return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Wallet' });

        // call LNBits API ເພື່ອກວດວ່າ invoice ຖືກຈ່າຍແລ້ວ
        const status = await lnbits.checkPaymentStatus({
            invoiceKey: wallet.invoiceKey,
            paymentHash,
        });

        if (status.paid) {
            const transaction = await Transaction.findOne({ paymentHash, user: req.user._id });

            // update ສະເພາະຕອນ status ຍັງ pending — ກັນ update ຊ້ຳຖ້າ poll ຫຼາຍຄັ້ງ
            if (transaction && transaction.status === 'pending') {
                transaction.status = 'success';
                await transaction.save();

                // topup ສຳເລັດ → sync balance ຈາກ LNBits ທັນທີ
                if (transaction.type === 'topup') {
                    const balance = await lnbits.getBalance(wallet.invoiceKey);
                    wallet.balanceSats = balance.balanceSats;
                    wallet.balanceLAK  = await exchangeRate.convertSatsToLAK(balance.balanceSats);
                    await wallet.save();
                }
            }
        }

        res.status(200).json({
            success:     true,
            paid:        status.paid,
            paymentHash,
            transaction: status.paid
                ? await Transaction.findOne({ paymentHash, user: req.user._id })
                : null,
        });
    } catch (error) {
        console.error('Check Payment Status Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── GET /api/transactions/summary ───────────────────────────────────────────
// ສະຫຼຸບຍອດໃຊ້ຈ່າຍ ເດືອນນີ້ ແຍກຕາມ type (ສຳລັບ dashboard)
// ຄຳນວນ startOfMonth → end of current month
exports.getSummary = async (req, res) => {
    try {
        // ດຶງ summary ສະເພາະ transactions ຂອງ user ນີ້ ໃນເດືອນປັດຈຸບັນ
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
                    // group ຕາມ type ແລ້ວ sum amounts
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

        // init ທຸກ type ເປັນ null — frontend ກວດ null ເພື່ອສະແດງ "ຍັງບໍ່ມີ"
        const result = {
            topup:    null,
            withdraw: null,
            pay:      null,
            receive:  null,
            laoQR:    null,
        };
        summary.forEach((s) => { result[s._id] = s; });

        res.status(200).json({
            success: true,
            month:   startOfMonth.toISOString().slice(0, 7), // e.g. "2026-05"
            summary: result,
            rate:    { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD },
        });
    } catch (error) {
        console.error('Get Summary Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};
