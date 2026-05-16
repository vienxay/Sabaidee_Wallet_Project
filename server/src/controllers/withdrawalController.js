// ─── controllers/withdrawalController.js ────────────────────────────────────
const Wallet       = require('../models/Wallet');
const Transaction  = require('../models/Transaction');
const Kyc          = require('../models/Kyc');
const lnbits       = require('../services/lnbitsService');
const exchangeRate = require('../services/exchangeRateService');
const {
    isLightningAddress,
    isLNURL,
    fetchInvoiceFromLNURL,
    fetchInvoiceFromAddress,
} = require('../utils/lightningUtils');

// ════════════════════════════════════════════════════════════════════════════
// Constants / Limits
// ════════════════════════════════════════════════════════════════════════════
const WITHDRAWAL_LIMIT = {
    unverified: { perTx: 500_000,   daily: 1_000_000  },
    verified:   { perTx: 5_000_000, daily: 20_000_000 },
};

/** ຍອດຖອນລາຍວັນ (LAK) */
const getDailyWithdrawnLAK = async (userId) => {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const result = await Transaction.aggregate([
        {
            $match: {
                user:      userId,
                type:      'withdraw',
                status:    'success',
                createdAt: { $gte: startOfDay },
            },
        },
        { $group: { _id: null, total: { $sum: '$amountLAK' } } },
    ]);
    return result[0]?.total || 0;
};

// ════════════════════════════════════════════════════════════════════════════
// GET /api/withdrawal/limit-status
// ດຶງວົງເງິນຖອນ + ຍອດໃຊ້ໄປແລ້ວມື້ນີ້
// ════════════════════════════════════════════════════════════════════════════
exports.getLimitStatus = async (req, res) => {
    try {
        const userId = req.user._id;

        const [kyc, wallet, todayWithdrawn] = await Promise.all([
            Kyc.findOne({ user: userId }),
            Wallet.findOne({ user: userId }),
            getDailyWithdrawnLAK(userId),
        ]);

        const isKYCVerified = kyc?.status === 'verified';
        const limit         = isKYCVerified ? WITHDRAWAL_LIMIT.verified : WITHDRAWAL_LIMIT.unverified;

        return res.json({
            success:      true,
            isKYCVerified,
            balanceSats:  wallet?.balanceSats || 0,
            perTxLimit:   limit.perTx,
            dailyLimit:   limit.daily,
            todayWithdrawn,
            remaining:    limit.daily - todayWithdrawn,
            percentage:   Math.min(Math.round((todayWithdrawn / limit.daily) * 100), 100),
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ════════════════════════════════════════════════════════════════════════════
// POST /api/withdrawal/preview
// Preview ກ່ອນຖອນ: ກວດ limit, ຄຳນວນ sats ↔ LAK, return ສະຫຼຸບ
// ════════════════════════════════════════════════════════════════════════════
exports.previewWithdrawal = async (req, res) => {
    try {
        const { destination, amountLAK } = req.body;
        // destination = Lightning Address (user@domain) or BOLT11 invoice

        if (!destination || !amountLAK) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາໃສ່ຂໍ້ມູນໃຫ້ຄົບ' });
        }

        const userId = req.user._id;

        const [kyc, wallet, rate, todayWithdrawn] = await Promise.all([
            Kyc.findOne({ user: userId }),
            Wallet.findOne({ user: userId }),
            exchangeRate.getExchangeRate(),
            getDailyWithdrawnLAK(userId),
        ]);

        if (!wallet) return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Wallet' });

        const isKYCVerified = kyc?.status === 'verified';
        const limit         = isKYCVerified ? WITHDRAWAL_LIMIT.verified : WITHDRAWAL_LIMIT.unverified;

        // ── ກວດ per-tx limit ─────────────────────────────────────────────────
        if (amountLAK > limit.perTx) {
            return res.status(403).json({
                success:    false,
                requireKYC: !isKYCVerified,
                message:    isKYCVerified
                    ? `ເກີນ limit ຕໍ່ຄັ້ງ (${limit.perTx.toLocaleString()} LAK)`
                    : `ຕ້ອງ KYC ເພື່ອຖອນເກີນ ${limit.perTx.toLocaleString()} LAK`,
            });
        }

        // ── ກວດ daily limit ──────────────────────────────────────────────────
        if (todayWithdrawn + amountLAK > limit.daily) {
            return res.status(403).json({
                success:       false,
                requireKYC:    !isKYCVerified,
                limitExceeded: true,
                todayWithdrawn,
                remaining:     limit.daily - todayWithdrawn,
                dailyLimit:    limit.daily,
                message:       `ວົງເງິນຄົງເຫຼືອ ${(limit.daily - todayWithdrawn).toLocaleString()} LAK`,
            });
        }

        // ── ຄຳນວນ sats ───────────────────────────────────────────────────────
        const amountSats = await exchangeRate.convertLAKToSats(amountLAK);

        // ── ກວດ balance ──────────────────────────────────────────────────────
        if (wallet.balanceSats < amountSats) {
            return res.status(400).json({ success: false, message: 'ຍອດ sats ບໍ່ພໍ' });
        }

        // ── ດຶງ display name ─────────────────────────────────────────────────
        const destinationType = isLightningAddress(destination)
            ? 'address'
            : isLNURL(destination)
                ? 'lnurl'
                : 'invoice';

        return res.json({
            success:         true,
            destinationType,
            destination:     destination.trim(),
            amountLAK,
            amountSats,
            estimatedFeeSats: Math.ceil(amountSats * 0.001), // ~0.1% estimate
            balanceSats:     wallet.balanceSats,
            rate: {
                btcToLAK: rate.btcToLAK,
                btcToUSD: rate.btcToUSD,
            },
            limits: {
                perTx:         limit.perTx,
                daily:         limit.daily,
                todayWithdrawn,
                remaining:     limit.daily - todayWithdrawn,
            },
        });
    } catch (error) {
        console.error('Preview Withdrawal Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ════════════════════════════════════════════════════════════════════════════
// POST /api/withdrawal/send
// ຖອນເງິນ: ສົ່ງ Lightning → update balance → save tx
// ════════════════════════════════════════════════════════════════════════════
exports.sendWithdrawal = async (req, res) => {
    try {
        const { destination, amountLAK, memo } = req.body;

        if (!destination || !amountLAK) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາໃສ່ຂໍ້ມູນໃຫ້ຄົບ' });
        }

        const userId = req.user._id;

        const [kyc, wallet, rate, todayWithdrawn] = await Promise.all([
            Kyc.findOne({ user: userId }),
            Wallet.findOne({ user: userId }).select('+adminKey'),
            exchangeRate.getExchangeRate(),
            getDailyWithdrawnLAK(userId),
        ]);

        if (!wallet) return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Wallet' });

        const isKYCVerified = kyc?.status === 'verified';
        const limit         = isKYCVerified ? WITHDRAWAL_LIMIT.verified : WITHDRAWAL_LIMIT.unverified;

        // ── ກວດ limits (double-check) ─────────────────────────────────────────
        if (amountLAK > limit.perTx) {
            return res.status(403).json({
                success:    false,
                requireKYC: !isKYCVerified,
                message:    `ເກີນ limit ຕໍ່ຄັ້ງ (${limit.perTx.toLocaleString()} LAK)`,
            });
        }
        if (todayWithdrawn + amountLAK > limit.daily) {
            return res.status(403).json({
                success:       false,
                limitExceeded: true,
                message:       `ວົງເງິນຄົງເຫຼືອ ${(limit.daily - todayWithdrawn).toLocaleString()} LAK`,
            });
        }

        // ── ຄຳນວນ sats ───────────────────────────────────────────────────────
        const amountSats = await exchangeRate.convertLAKToSats(amountLAK);

        // LNBits ຮຽກຮ້ອງ reserve ຢ່າງໜ້ອຍ 10 sats ສຳລັບ routing fee
        const MIN_RESERVE_SATS = 10;
        if (wallet.balanceSats < amountSats + MIN_RESERVE_SATS) {
            return res.status(400).json({
                success: false,
                message: `ຍອດ sats ບໍ່ພໍ — ຕ້ອງມີຢ່າງໜ້ອຍ ${amountSats + MIN_RESERVE_SATS} sats (ມີ ${wallet.balanceSats} sats)`,
            });
        }

        // ── ໄດ້ BOLT11 invoice ───────────────────────────────────────────────
        let paymentRequest;
        const destType = isLightningAddress(destination)
            ? 'address'
            : isLNURL(destination)
                ? 'lnurl'
                : 'invoice';

        if (destType === 'address') {
            paymentRequest = await fetchInvoiceFromAddress(destination.trim(), amountSats);
        } else if (destType === 'lnurl') {
            paymentRequest = await fetchInvoiceFromLNURL(destination.trim(), amountSats); // ✅ ເພີ່ມ
        } else {
            paymentRequest = destination.trim();
        }

        // ── ສົ່ງຜ່ານ LNBits ──────────────────────────────────────────────────
        const payResult = await lnbits.payInvoice({
            adminKey: wallet.adminKey,
            paymentRequest,
        });

        const feeSats = payResult.feeSats || 0;

        // ── Update wallet balance ────────────────────────────────────────────
        wallet.balanceSats = wallet.balanceSats - amountSats - feeSats;
        await wallet.save();

        // ── Save Transaction ─────────────────────────────────────────────────
        const transaction = await Transaction.create({
            user:            userId,
            wallet:          wallet._id,
            type:            'withdraw',
            status:          'success',
            amountSats,
            amountLAK,
            feeSats,
            paymentHash:     payResult.paymentHash,
            paymentRequest,
            destination:     destination.trim(),
            destinationType: destType,
            memo:            memo || `Withdraw to ${destination}`,
            kycVerified:     isKYCVerified,
            exchangeRate: {
                btcToLAK:  rate.btcToLAK,
                btcToUSD:  rate.btcToUSD,
                usdToLAK:  rate.usdToLAK,
                fetchedAt: rate.fetchedAt,
            },
        });

        return res.status(200).json({
            success:       true,
            message:       'ຖອນເງິນສຳເລັດ',
            transactionId: transaction._id,
            paymentHash:   payResult.paymentHash,
            destination:   destination.trim(),
            destinationType: destType,
            amountSats,
            amountLAK,
            feeSats,
            balanceSats:   wallet.balanceSats,
            createdAt:     transaction.createdAt,
            rate: {
                btcToLAK: rate.btcToLAK,
                btcToUSD: rate.btcToUSD,
            },
        });

    } catch (error) {
        console.error('Withdrawal Error:', error);

        // ── Save failed transaction ───────────────────────────────────────────
        try {
            await Transaction.create({
                user:        req.user._id,
                type:        'withdraw',
                status:      'failed',
                amountSats:  0,
                amountLAK:   req.body.amountLAK || 0,
                destination: req.body.destination || '',
                memo:        'Failed withdrawal',
                errorMsg:    error.message,
            });
        } catch (_) {}

        return res.status(500).json({ success: false, message: error.message });
    }
};