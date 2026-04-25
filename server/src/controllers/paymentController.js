const Wallet = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const Kyc = require('../models/Kyc');
const lnbits = require('../services/lnbitsService');
const exchangeRate = require('../services/exchangeRateService');

const LIMIT = {
    unverified: { perTx: 500_000, daily: 1_000_000 },
    verified: { perTx: 5_000_000, daily: 20_000_000 },
};

const LAO_QR_LIMIT = {
    unverified: 2_000_000,
    verified: 100_000_000,
};

const isLightningAddress = (address) =>
    /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(address);

const getStartOfDay = () => {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    return startOfDay;
};

const getDailySpentLAK = async (userId) => {
    const result = await Transaction.aggregate([
        {
            $match: {
                user: userId,
                type: 'pay',
                status: 'success',
                createdAt: { $gte: getStartOfDay() },
            },
        },
        { $group: { _id: null, total: { $sum: '$amountLAK' } } },
    ]);

    return result[0]?.total || 0;
};

const getDailyLaoQRSpentLAK = async (userId) => {
    const result = await Transaction.aggregate([
        {
            $match: {
                user: userId,
                type: 'laoQR',
                status: 'success',
                createdAt: { $gte: getStartOfDay() },
            },
        },
        { $group: { _id: null, total: { $sum: '$amountLAK' } } },
    ]);

    return result[0]?.total || 0;
};

const formatLAK = (amount) =>
    amount.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,');

exports.decodeInvoice = async (req, res) => {
    try {
        let { paymentRequest } = req.body;
        if (!paymentRequest) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາໃສ່ Lightning Invoice' });
        }

        paymentRequest = paymentRequest.trim();

        if (isLightningAddress(paymentRequest)) {
            const rate = await exchangeRate.getExchangeRate();
            return res.status(200).json({
                success: true,
                isAddress: true,
                payee: paymentRequest,
                amountSats: 0,
                amountLAK: 0,
                description: `Pay to ${paymentRequest}`,
                rate: {
                    btcToLAK: rate.btcToLAK,
                    btcToUSD: rate.btcToUSD,
                },
            });
        }

        const [decoded, rate] = await Promise.all([
            lnbits.decodeInvoice(paymentRequest),
            exchangeRate.getExchangeRate(),
        ]);

        const amountLAK = await exchangeRate.convertSatsToLAK(decoded.amountSats);

        return res.status(200).json({
            success: true,
            isAddress: false,
            amountSats: decoded.amountSats,
            amountLAK,
            description: decoded.description,
            expiry: decoded.expiry,
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

exports.pay = async (req, res) => {
    try {
        const { paymentRequest, memo, amount } = req.body;

        if (!paymentRequest) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາໃສ່ Lightning Invoice' });
        }

        const wallet = await Wallet.findOne({ user: req.user._id }).select('+adminKey');
        if (!wallet) {
            return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Wallet' });
        }

        const kyc = await Kyc.findOne({ user: req.user._id });
        const isKYCVerified = kyc?.status === 'verified';
        const limit = isKYCVerified ? LIMIT.verified : LIMIT.unverified;

        const [decoded, rate, balanceResult] = await Promise.all([
            lnbits.decodeInvoice(paymentRequest.trim()),
            exchangeRate.getExchangeRate(),
            lnbits.getBalance(wallet.invoiceKey),
        ]);

        const amountSats = decoded.amountSats > 0 ? decoded.amountSats : (parseInt(amount, 10) || 0);
        if (amountSats <= 0) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາລະບຸຈຳນວນ sats' });
        }

        const amountLAK = await exchangeRate.convertSatsToLAK(amountSats);

        if (amountLAK > limit.perTx) {
            return res.status(403).json({
                success: false,
                requireKYC: !isKYCVerified,
                message: isKYCVerified
                    ? `ເກີນ limit ຕໍ່ຄັ້ງ (${limit.perTx.toLocaleString()} LAK)`
                    : `ຕ້ອງຢືນຢັນ KYC ເພື່ອຈ່າຍເກີນ ${limit.perTx.toLocaleString()} LAK`,
            });
        }

        const dailySpent = await getDailySpentLAK(req.user._id);
        if (dailySpent + amountLAK > limit.daily) {
            return res.status(403).json({
                success: false,
                requireKYC: !isKYCVerified,
                message: `ເກີນ limit ລາຍວັນ (ໃຊ້ໄປ ${dailySpent.toLocaleString()} / ${limit.daily.toLocaleString()} LAK)`,
            });
        }

        if (balanceResult.balanceSats < amountSats) {
            return res.status(400).json({ success: false, message: 'ຍອດເງິນ sats ບໍ່ພໍ' });
        }

        const payResult = await lnbits.payInvoice({
            adminKey: wallet.adminKey,
            paymentRequest: paymentRequest.trim(),
        });

        wallet.balanceSats = balanceResult.balanceSats - amountSats - (payResult.feeSats || 0);
        await wallet.save();

        const transaction = await Transaction.create({
            user: req.user._id,
            wallet: wallet._id,
            type: 'pay',
            status: 'success',
            amountSats,
            amountLAK,
            feeSats: payResult.feeSats || 0,
            paymentHash: payResult.paymentHash,
            paymentRequest: paymentRequest.trim(),
            memo: memo || decoded.description || 'Payment',
            kycRequired: !isKYCVerified,
            kycVerified: isKYCVerified,
            exchangeRate: {
                btcToLAK: rate.btcToLAK,
                btcToUSD: rate.btcToUSD,
                usdToLAK: rate.usdToLAK,
                fetchedAt: rate.fetchedAt,
            },
        });

        return res.status(200).json({
            success: true,
            message: 'ຈ່າຍເງິນສຳເລັດ',
            payment: {
                transactionId: transaction._id,
                paymentHash: payResult.paymentHash,
                amountSats,
                amountLAK,
                feeSats: payResult.feeSats || 0,
                balanceSats: wallet.balanceSats,
                rate: {
                    btcToLAK: rate.btcToLAK,
                    btcToUSD: rate.btcToUSD,
                    usedAt: rate.fetchedAt,
                },
            },
        });
    } catch (error) {
        console.error('Pay Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.payLaoQR = async (req, res) => {
    try {
        const userId = req.user._id;
        const { amountLAK, merchantName, bank, qrRaw, description } = req.body;

        const kyc = await Kyc.findOne({ user: userId });
        const isKYCVerified = kyc?.status === 'verified';
        const dailyLimit = isKYCVerified ? LAO_QR_LIMIT.verified : LAO_QR_LIMIT.unverified;

        const todaySpent = await getDailyLaoQRSpentLAK(userId);
        const remaining = dailyLimit - todaySpent;

        if (amountLAK > remaining) {
            if (!isKYCVerified) {
                return res.status(403).json({
                    success: false,
                    requireKYC: true,
                    limitExceeded: true,
                    todaySpent,
                    remaining,
                    dailyLimit,
                    message:
                        `ເກີນວົງເງິນຕໍ່ມື້ (${formatLAK(dailyLimit)} ກີບ). ` +
                        'ກະລຸນາຢືນຢັນຕົວຕົນ (KYC) ເພື່ອຍົກລະດັບວົງເງິນ',
                });
            }

            return res.status(400).json({
                success: false,
                limitExceeded: true,
                todaySpent,
                remaining,
                dailyLimit,
                message:
                    `ຍອດໃຊ້ວັນນີ້: ${formatLAK(todaySpent)} ກີບ. ` +
                    `ວົງເງິນຄົງເຫຼືອ: ${formatLAK(remaining)} ກີບ`,
            });
        }

        const tx = await Transaction.create({
            user: userId,
            type: 'laoQR',
            status: 'success',
            amountSats: 0,
            amountLAK,
            merchantName: merchantName || 'ຮ້ານຄ້າ',
            bank: bank || '',
            qrRaw: qrRaw || '',
            memo: description || 'LAO QR Payment',
            kycVerified: isKYCVerified,
        });

        return res.status(200).json({
            success: true,
            message: 'ສົ່ງເງິນສຳເລັດ',
            todaySpent: todaySpent + amountLAK,
            remaining: remaining - amountLAK,
            dailyLimit,
            transactionId: tx._id,
        });
    } catch (error) {
        console.error('LAO QR Pay Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getLaoQRLimitStatus = async (req, res) => {
    try {
        const userId = req.user._id;
        const kyc = await Kyc.findOne({ user: userId });
        const isKYCVerified = kyc?.status === 'verified';
        const dailyLimit = isKYCVerified ? LAO_QR_LIMIT.verified : LAO_QR_LIMIT.unverified;

        const todaySpent = await getDailyLaoQRSpentLAK(userId);
        const remaining = dailyLimit - todaySpent;

        return res.json({
            success: true,
            isKYCVerified,
            dailyLimit,
            todaySpent,
            remaining,
            percentage: Math.min(Math.round((todaySpent / dailyLimit) * 100), 100),
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
