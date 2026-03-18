const Wallet = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const KYC = require('../models/KYC');
const lnbits = require('../services/lnbitsService');
const exchangeRate = require('../services/exchangeRateService');

// ─── ຄ່າ limit ຈ່າຍເງິນ ──────────────────────────────────────────────────────
const LIMIT = {
    unverified: { perTx: 500_000, daily: 1_000_000 },   // LAK (ບໍ່ KYC)
    verified:   { perTx: 5_000_000, daily: 20_000_000 }, // LAK (KYC ແລ້ວ)
};

// ─── Helper: ກວດ daily spending ──────────────────────────────────────────────
const getDailySpentLAK = async (userId) => {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const result = await Transaction.aggregate([
        {
            $match: {
                user: userId,
                type: 'pay',
                status: 'success',
                createdAt: { $gte: startOfDay },
            },
        },
        { $group: { _id: null, total: { $sum: '$amountLAK' } } },
    ]);

    return result[0]?.total || 0;
};

// ─── POST /api/payment/pay ────────────────────────────────────────────────────
// ຈ່າຍເງິນ: ກວດ KYC → ກວດ limit → ດຶງ rate → ຕັດເງິນ

// paymentController.js — pay()
// ເພີ່ມ debug + ຮອງຮັບ amountless
exports.pay = async (req, res) => {
    try {
        const { paymentRequest, memo, amount } = req.body;

        // ✅ Debug
        console.log('📦 paymentRequest:', paymentRequest?.substring(0, 30));
        console.log('📦 amount from client:', amount);

        if (!paymentRequest) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາໃສ່ Lightning Invoice' });
        }

        const wallet = await Wallet.findOne({ user: req.user._id }).select('+adminKey');
        if (!wallet) return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Wallet' });

        const kyc = await KYC.findOne({ user: req.user._id });
        const isKYCVerified = kyc?.status === 'verified';
        const limit = isKYCVerified ? LIMIT.verified : LIMIT.unverified;

        const [decoded, rate, balanceResult] = await Promise.all([
            lnbits.decodeInvoice(paymentRequest.trim()), // ✅ trim
            exchangeRate.getExchangeRate(),
            lnbits.getBalance(wallet.invoiceKey),
        ]);

        // ✅ ຖ້າ amountless → ໃຊ້ amount ຈາກ Flutter
        const amountSats = decoded.amountSats > 0
            ? decoded.amountSats
            : (parseInt(amount) || 0);

        if (amountSats <= 0) {
            return res.status(400).json({
                success: false,
                message: 'ກະລຸນາລະບຸຈຳນວນ sats',
            });
        }

        const amountLAK = await exchangeRate.convertSatsToLAK(amountSats);

        // ── limit per tx ────────────────────────────────────────────────────
        if (amountLAK > limit.perTx) {
            return res.status(403).json({
                success: false,
                message: isKYCVerified
                    ? `ເກີນ limit ຕໍ່ຄັ້ງ (${limit.perTx.toLocaleString()} LAK)`
                    : `ຕ້ອງຢືນຢັນ KYC ເພື່ອຈ່າຍເກີນ ${limit.perTx.toLocaleString()} LAK`,
                requireKYC: !isKYCVerified,
            });
        }

        // ── daily limit ─────────────────────────────────────────────────────
        const dailySpent = await getDailySpentLAK(req.user._id);
        if (dailySpent + amountLAK > limit.daily) {
            return res.status(403).json({
                success: false,
                message: `ເກີນ limit ລາຍວັນ (ໃຊ້ໄປ ${dailySpent.toLocaleString()} / ${limit.daily.toLocaleString()} LAK)`,
                requireKYC: !isKYCVerified,
            });
        }

        // ── balance ─────────────────────────────────────────────────────────
        if (balanceResult.balanceSats < amountSats) {
            return res.status(400).json({ success: false, message: 'ຍອດເງິນ sats ບໍ່ພໍ' });
        }

        // ── pay ─────────────────────────────────────────────────────────────
        const payResult = await lnbits.payInvoice({
            adminKey: wallet.adminKey,
            paymentRequest: paymentRequest.trim(), // ✅ trim
        });

        // ── update balance ──────────────────────────────────────────────────
        wallet.balanceSats = balanceResult.balanceSats - amountSats - (payResult.feeSats || 0);
        await wallet.save();

        // ── save transaction ────────────────────────────────────────────────
        const transaction = await Transaction.create({
            user:   req.user._id,
            wallet: wallet._id,
            type:   'pay',
            status: 'success',
            amountSats,
            amountLAK,
            feeSats:     payResult.feeSats || 0,
            paymentHash: payResult.paymentHash,
            paymentRequest: paymentRequest.trim(),
            memo: memo || decoded.description || 'Payment',
            kycRequired: !isKYCVerified,
            kycVerified:  isKYCVerified,
            exchangeRate: {
                btcToLAK:  rate.btcToLAK,
                btcToUSD:  rate.btcToUSD,
                usdToLAK:  rate.usdToLAK,
                fetchedAt: rate.fetchedAt,
            },
        });

        res.status(200).json({
            success: true,
            message: 'ຈ່າຍເງິນສຳເລັດ',
            payment: {
                transactionId: transaction._id,
                paymentHash:   payResult.paymentHash,
                amountSats,
                amountLAK,
                feeSats:     payResult.feeSats || 0,
                balanceSats: wallet.balanceSats,
                rate: {
                    btcToLAK: rate.btcToLAK,
                    btcToUSD: rate.btcToUSD,
                    usedAt:   rate.fetchedAt,
                },
            },
        });

    } catch (error) {
        console.error('Pay Error:', error);
        return res.status(500).json({ success: false, message: error.message });
        //                                                        ↑ ✅ ສະແດງ error ຈິງໆ
    }
};

// ─── POST /api/payment/decode ─────────────────────────────────────────────────
// Preview invoice ກ່ອນຈ່າຍ (ສະແດງ LAK ກ່ອນ confirm)

exports.decodeInvoice = async (req, res) => {
    try {
        const { paymentRequest } = req.body;
        if (!paymentRequest) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາໃສ່ Lightning Invoice' });
        }

        const [decoded, rate] = await Promise.all([
            lnbits.decodeInvoice(paymentRequest),
            exchangeRate.getExchangeRate(),
        ]);

        const amountLAK = await exchangeRate.convertSatsToLAK(decoded.amountSats);

        res.status(200).json({
            success: true,
            // ✅ ເອົາ invoice key ອອກ — flat ໂດຍກົງ
            amountSats:  decoded.amountSats,
            amountLAK,
            description: decoded.description,
            expiry:      decoded.expiry,
            rate: {
                btcToLAK: rate.btcToLAK,
                btcToUSD: rate.btcToUSD,
            },
        });
    } catch (error) {
        console.error('Decode Invoice Error:', error);
        return res.status(500).json({ success: false, message: 'Invoice ບໍ່ຖືກຕ້ອງ' });
    }
};