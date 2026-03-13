const Wallet = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const lnbits = require('../services/lnbitsService');
const exchangeRate = require('../services/exchangeRateService');

// ─── GET /api/wallet ──────────────────────────────────────────────────────────

exports.getWallet = async (req, res) => {
    try {
        const wallet = await Wallet.findOne({ user: req.user._id });
        if (!wallet) return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Wallet' });

        const rate = await exchangeRate.getExchangeRate();
        const balanceLAK = await exchangeRate.convertSatsToLAK(wallet.balanceSats);

        res.status(200).json({
            success: true,
            wallet: {
                walletId:    wallet.walletId,
                walletName:  wallet.walletName,
                invoiceKey:  wallet.invoiceKey,
                balanceSats: wallet.balanceSats,
                balanceLAK,
                rate: { btcToUSD: rate.btcToUSD, btcToLAK: rate.btcToLAK, updatedAt: rate.fetchedAt },
            },
        });
    } catch (error) {
        console.error('Get Wallet Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── GET /api/wallet/balance ──────────────────────────────────────────────────

exports.getBalance = async (req, res) => {
    try {
        const wallet = await Wallet.findOne({ user: req.user._id });
        if (!wallet) return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Wallet' });

        const [balanceResult, rate] = await Promise.all([
            lnbits.getBalance(wallet.invoiceKey),
            exchangeRate.getExchangeRate(),
        ]);

        wallet.balanceSats = balanceResult.balanceSats;
        await wallet.save();

        const balanceLAK = await exchangeRate.convertSatsToLAK(balanceResult.balanceSats);

        res.status(200).json({
            success: true,
            balance: {
                sats: balanceResult.balanceSats, msats: balanceResult.balanceMsats,
                lak: balanceLAK, btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD, rateAt: rate.fetchedAt,
            },
        });
    } catch (error) {
        console.error('Get Balance Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── GET /api/wallet/rate ─────────────────────────────────────────────────────

exports.getRate = async (req, res) => {
    try {
        const rate = await exchangeRate.getExchangeRate();
        res.status(200).json({
            success: true,
            rate: { btcToUSD: rate.btcToUSD, btcToLAK: rate.btcToLAK, usdToLAK: rate.usdToLAK, updatedAt: rate.fetchedAt },
        });
    } catch (error) {
        console.error('Get Rate Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── POST /api/wallet/topup ───────────────────────────────────────────────────
// ສ້າງ Lightning Invoice ສຳລັບ TopUp BTC ເຂົ້າ wallet

exports.topUp = async (req, res) => {
    try {
        const { amountSats, memo } = req.body;
        if (!amountSats || amountSats <= 0)
            return res.status(400).json({ success: false, message: 'ກະລຸນາລະບຸຈຳນວນ sats' });

        const wallet = await Wallet.findOne({ user: req.user._id });
        if (!wallet) return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Wallet' });

        const rate      = await exchangeRate.getExchangeRate();
        const amountLAK = await exchangeRate.convertSatsToLAK(amountSats);

        const invoiceResult = await lnbits.createInvoice({
            invoiceKey: wallet.invoiceKey,
            amount: amountSats,
            memo: memo || `TopUp ${amountSats} sats`,
        });

        const transaction = await Transaction.create({
            user: req.user._id, wallet: wallet._id,
            type: 'topup', status: 'pending',
            amountSats, amountLAK,
            paymentHash: invoiceResult.paymentHash,
            paymentRequest: invoiceResult.paymentRequest,
            memo: memo || `TopUp ${amountSats} sats`,
            exchangeRate: { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD, usdToLAK: rate.usdToLAK, fetchedAt: rate.fetchedAt },
        });

        res.status(201).json({
            success: true,
            message: 'ສ້າງ Invoice TopUp ສຳເລັດ — ສະແກນ QR ເພື່ອຈ່າຍ',
            topup: {
                transactionId: transaction._id,
                paymentRequest: invoiceResult.paymentRequest,
                paymentHash: invoiceResult.paymentHash,
                amountSats, amountLAK,
                rate: { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD },
            },
        });
    } catch (error) {
        console.error('TopUp Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── POST /api/wallet/withdraw ────────────────────────────────────────────────
// ຖອນ sats ອອກໂດຍຈ່າຍ Lightning Invoice ທີ່ສ້າງຈາກ wallet ອື່ນ

exports.withdraw = async (req, res) => {
    try {
        const { paymentRequest, memo } = req.body;
        if (!paymentRequest)
            return res.status(400).json({ success: false, message: 'ກະລຸນາໃສ່ Lightning Invoice' });

        const wallet = await Wallet.findOne({ user: req.user._id }).select('+adminKey');
        if (!wallet) return res.status(404).json({ success: false, message: 'ບໍ່ພົບ Wallet' });

        const [decoded, rate, balanceResult] = await Promise.all([
            lnbits.decodeInvoice(paymentRequest),
            exchangeRate.getExchangeRate(),
            lnbits.getBalance(wallet.invoiceKey),
        ]);

        if (balanceResult.balanceSats < decoded.amountSats)
            return res.status(400).json({ success: false, message: 'ຍອດເງິນ sats ບໍ່ພໍ' });

        const amountLAK = await exchangeRate.convertSatsToLAK(decoded.amountSats);
        const payResult = await lnbits.payInvoice({ adminKey: wallet.adminKey, paymentRequest });

        wallet.balanceSats = balanceResult.balanceSats - decoded.amountSats - (payResult.feeSats || 0);
        await wallet.save();

        const transaction = await Transaction.create({
            user: req.user._id, wallet: wallet._id,
            type: 'withdraw', status: 'success',
            amountSats: decoded.amountSats, amountLAK,
            feeSats: payResult.feeSats || 0,
            paymentHash: payResult.paymentHash, paymentRequest,
            memo: memo || decoded.description || 'Withdraw',
            exchangeRate: { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD, usdToLAK: rate.usdToLAK, fetchedAt: rate.fetchedAt },
        });

        res.status(200).json({
            success: true,
            message: 'ຖອນເງິນສຳເລັດ',
            withdraw: {
                transactionId: transaction._id,
                paymentHash: payResult.paymentHash,
                amountSats: decoded.amountSats, amountLAK,
                feeSats: payResult.feeSats || 0,
                balanceSats: wallet.balanceSats,
            },
        });
    } catch (error) {
        console.error('Withdraw Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};