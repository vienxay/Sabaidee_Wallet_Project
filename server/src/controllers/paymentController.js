const axios = require("axios");
const Wallet = require("../models/Wallet");
const { createNotification } = require("./notificationController");
const Transaction = require("../models/Transaction");
const Kyc = require("../models/Kyc");
const Rate = require("../models/Rate");
const lnbits = require("../services/lnbitsService");
const exchangeRate = require("../services/exchangeRateService");
const {
  isLightningAddress,
  isLNURL,
  decodeLNURL,
  fetchInvoiceFromLNURL,
  fetchInvoiceFromAddress,
} = require("../utils/lightningUtils");

const getLimits = async () => {
  const r = await Rate.findOne();
  return {
    pay: {
      unverified: { perTx: r.payPerTxUnverified, daily: r.payDailyUnverified },
      verified: { perTx: r.payPerTxVerified, daily: r.payDailyVerified },
    },
    qr: {
      unverified: r.qrDailyUnverified,
      verified: r.qrDailyVerified,
    },
  };
};

const MIN_BALANCE_SATS = 5;

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
        type: "pay",
        status: "success",
        createdAt: { $gte: getStartOfDay() },
      },
    },
    { $group: { _id: null, total: { $sum: "$amountLAK" } } },
  ]);
  return result[0]?.total || 0;
};

const getDailyLaoQRSpentLAK = async (userId) => {
  const result = await Transaction.aggregate([
    {
      $match: {
        user: userId,
        type: "laoQR",
        status: "success",
        createdAt: { $gte: getStartOfDay() },
      },
    },
    { $group: { _id: null, total: { $sum: "$amountLAK" } } },
  ]);
  return result[0]?.total || 0;
};

const formatLAK = (amount) =>
  amount.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1,");

// ════════════════════════════════════════════════════════════════════════════
// POST /api/payment/decode
// ════════════════════════════════════════════════════════════════════════════
exports.decodeInvoice = async (req, res) => {
  try {
    let { paymentRequest } = req.body;
    if (!paymentRequest) {
      return res
        .status(400)
        .json({ success: false, message: "ກະລຸນາໃສ່ Lightning Invoice" });
    }

    paymentRequest = paymentRequest.trim();
    const rate = await exchangeRate.getExchangeRate();

    // ✅ 1. LNURL
    if (isLNURL(paymentRequest)) {
      const url = decodeLNURL(paymentRequest);
      const { data: meta } = await axios.get(url, { timeout: 10_000 });

      const minSats = Math.ceil(meta.minSendable / 1000);
      const maxSats = Math.floor(meta.maxSendable / 1000);
      const [minLAK, maxLAK] = await Promise.all([
        exchangeRate.convertSatsToLAK(minSats),
        exchangeRate.convertSatsToLAK(maxSats),
      ]);

      return res.status(200).json({
        success: true,
        isLNURL: true,
        isAddress: false,
        minSats,
        maxSats,
        minLAK,
        maxLAK,
        description: meta.defaultDescription || "LNURL Payment",
        rate: { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD },
      });
    }

    // ✅ 2. Lightning Address
    if (isLightningAddress(paymentRequest)) {
      return res.status(200).json({
        success: true,
        isLNURL: false,
        isAddress: true,
        payee: paymentRequest,
        amountSats: 0,
        amountLAK: 0,
        description: `Pay to ${paymentRequest}`,
        rate: { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD },
      });
    }

    // ✅ 3. Lightning Invoice
    const decoded = await lnbits.decodeInvoice(paymentRequest);
    const amountLAK = await exchangeRate.convertSatsToLAK(decoded.amountSats);

    return res.status(200).json({
      success: true,
      isLNURL: false,
      isAddress: false,
      amountSats: decoded.amountSats,
      amountLAK,
      description: decoded.description,
      expiry: decoded.expiry,
      rate: { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD },
    });
  } catch (error) {
    console.error("Decode Invoice Error:", error);
    return res
      .status(500)
      .json({ success: false, message: "Invoice ບໍ່ຖືກຕ້ອງ" });
  }
};

// ════════════════════════════════════════════════════════════════════════════
// POST /api/payment/pay
// ════════════════════════════════════════════════════════════════════════════
exports.pay = async (req, res) => {
  try {
    const { paymentRequest, memo, amount } = req.body;

    if (!paymentRequest) {
      return res
        .status(400)
        .json({ success: false, message: "ກະລຸນາໃສ່ Lightning Invoice" });
    }

    const wallet = await Wallet.findOne({ user: req.user._id }).select(
      "+adminKey",
    );
    if (!wallet) {
      return res.status(404).json({ success: false, message: "ບໍ່ພົບ Wallet" });
    }

    const kyc = await Kyc.findOne({ user: req.user._id });
    const isKYCVerified = kyc?.status === "verified";
    const limits = await getLimits();
    const limit = isKYCVerified ? limits.pay.verified : limits.pay.unverified;

    const input = paymentRequest.trim();
    const isAddr = isLightningAddress(input);
    const isLNURLInput = isLNURL(input);

    const rate = await exchangeRate.getExchangeRate();

    let finalInvoice = input;
    let amountSats = parseInt(amount, 10) || 0;
    let description = memo || "Payment";

    if (isAddr) {
      if (amountSats <= 0) {
        return res.status(400).json({
          success: false,
          message: "ກະລຸນາລະບຸຈຳນວນ sats ສຳລັບ Lightning Address",
        });
      }
      finalInvoice = await fetchInvoiceFromAddress(input, amountSats);
    } else if (isLNURLInput) {
      if (amountSats <= 0) {
        return res.status(400).json({
          success: false,
          message: "ກະລຸນາລະບຸຈຳນວນ sats ສຳລັບ LNURL",
        });
      }
      finalInvoice = await fetchInvoiceFromLNURL(input, amountSats);
    } else {
      const decoded = await lnbits.decodeInvoice(finalInvoice);
      amountSats = decoded.amountSats > 0 ? decoded.amountSats : amountSats;
      description = memo || decoded.description || "Payment";
    }

    if (amountSats <= 0) {
      return res
        .status(400)
        .json({ success: false, message: "ກະລຸນາລະບຸຈຳນວນ sats" });
    }

    const amountLAK = await exchangeRate.convertSatsToLAK(amountSats);
    const feePercent = rate.laoQrFeePercent || 0;
    const feeSats = Math.ceil((amountSats * feePercent) / 100);
    const feeLAK = Math.round((amountLAK * feePercent) / 100);
    const totalSats = amountSats + feeSats;

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

    // ── Atomic: ກວດ + ຫັກ balance (ຕ້ອງເຫຼືອຢ່າງໜ້ອຍ MIN_BALANCE_SATS) ──
    const atomicWallet = await Wallet.findOneAndUpdate(
      {
        user: req.user._id,
        balanceSats: { $gte: totalSats + MIN_BALANCE_SATS },
      },
      { $inc: { balanceSats: -totalSats } },
      { new: true },
    ).select("+adminKey");

    if (!atomicWallet) {
      if (wallet.balanceSats <= 0) {
        return res.status(400).json({
          success: false,
          message: "ຍອດເງິນ sats ໝົດແລ້ວ — ກະລຸນາ TopUp ກ່ອນ",
        });
      }
      return res.status(400).json({
        success: false,
        message: `ຍອດເງິນບໍ່ພໍ (ຕ້ອງການ ${totalSats.toLocaleString()} sats, ມີ ${wallet.balanceSats.toLocaleString()} sats — ຕ້ອງເຫຼືອຢ່າງໜ້ອຍ ${MIN_BALANCE_SATS} sats)`,
      });
    }

    let payResult;
    try {
      payResult = await lnbits.payInvoice({
        adminKey: atomicWallet.adminKey,
        paymentRequest: finalInvoice,
      });
    } catch (lnbitsErr) {
      // LNBits ລົ້ມເຫຼວ → ຄືນເງິນທີ່ຫັກໄວ້
      await Wallet.updateOne(
        { user: req.user._id },
        { $inc: { balanceSats: totalSats } },
      );
      throw lnbitsErr;
    }

    // ── ເກັບຄ່າທຳນຽມເຂົ້າ admin wallet ──
    if (feeSats > 0) {
      await lnbits.collectFee({ userAdminKey: atomicWallet.adminKey, feeSats });
    }

    // ── Sync LNBits baseline + update LAK ──
    const newBalance = await lnbits.getBalance(atomicWallet.invoiceKey);
    const finalLAK = await exchangeRate.convertSatsToLAK(
      atomicWallet.balanceSats,
    );
    await Wallet.updateOne(
      { user: req.user._id },
      {
        $set: { lnbitsBaseSats: newBalance.balanceSats, balanceLAK: finalLAK },
      },
    );

    const transaction = await Transaction.create({
      user: req.user._id,
      wallet: atomicWallet._id,
      type: "pay",
      status: "success",
      amountSats,
      amountLAK,
      feeSats,
      feeLAK,
      paymentHash: payResult.paymentHash,
      paymentRequest: finalInvoice,
      memo: description,
      kycRequired: !isKYCVerified,
      kycVerified: isKYCVerified,
      exchangeRate: {
        btcToLAK: rate.btcToLAK,
        btcToUSD: rate.btcToUSD,
        usdToLAK: rate.usdToLAK,
        fetchedAt: rate.fetchedAt,
      },
    });

    createNotification({
      userId: req.user._id,
      title: "⚡ ຈ່າຍເງິນສຳເລັດ",
      body: `ໂອນ ${amountSats.toLocaleString()} sats (${amountLAK.toLocaleString()} ກີບ)${description ? ` — ${description}` : ""}`,
      type: "pay",
      transactionId: transaction._id,
    });

    return res.status(200).json({
      success: true,
      message: "ຈ່າຍເງິນສຳເລັດ",
      payment: {
        transactionId: transaction._id,
        paymentHash: payResult.paymentHash,
        amountSats,
        amountLAK,
        feeSats,
        feeLAK,
        feePercent,
        totalSats,
        balanceSats: atomicWallet.balanceSats,
        balanceLAK: finalLAK,
        rate: { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD },
      },
    });
  } catch (error) {
    console.error("Pay Error:", error);
    return res
      .status(500)
      .json({ success: false, message: "ເກີດຂໍ້ຜິດພາດໃນການຈ່າຍເງິນ" });
  }
};

// ════════════════════════════════════════════════════════════════════════════
// ✅ POST /api/payment/pay-lnurl  (ໃໝ່)
// ════════════════════════════════════════════════════════════════════════════
exports.payLNURL = async (req, res) => {
  try {
    const { lnurl, amountSats, memo } = req.body;

    if (!lnurl || !amountSats || amountSats <= 0) {
      return res
        .status(400)
        .json({ success: false, message: "ກະລຸນາໃສ່ LNURL ແລະ ຈຳນວນ sats" });
    }

    // ✅ ໃຊ້ fetchInvoiceFromLNURL ແທນ lnurlPay
    const invoice = await fetchInvoiceFromLNURL(lnurl, amountSats);

    req.body.paymentRequest = invoice;
    req.body.amount = amountSats;
    req.body.memo = memo || "LNURL Payment";
    return exports.pay(req, res);
  } catch (error) {
    console.error("LNURL Pay Error:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// ════════════════════════════════════════════════════════════════════════════
// POST /api/payment/pay-lao-qr
// ════════════════════════════════════════════════════════════════════════════
exports.payLaoQR = async (req, res) => {
  try {
    const userId = req.user._id;
    const { amountLAK, merchantName, bank, qrRaw, description } = req.body;

    if (!amountLAK || amountLAK < 10) {
      return res
        .status(400)
        .json({ success: false, message: "ຈຳນວນເງິນຕ່ຳສຸດ 10 ກີບ" });
    }

    const [kyc, wallet, limits] = await Promise.all([
      Kyc.findOne({ user: userId }),
      Wallet.findOne({ user: userId }).select("+adminKey"),
      getLimits(),
    ]);

    if (!wallet) {
      return res.status(404).json({ success: false, message: "ບໍ່ພົບ Wallet" });
    }

    const isKYCVerified = kyc?.status === "verified";
    const dailyLimit = isKYCVerified
      ? limits.qr.verified
      : limits.qr.unverified;

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
            "ກະລຸນາຢືນຢັນຕົວຕົນ (KYC) ເພື່ອຍົກລະດັບວົງເງິນ",
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

    const [amountSats, rate] = await Promise.all([
      exchangeRate.convertLAKToSats(amountLAK),
      exchangeRate.getExchangeRate(),
    ]);

    if (!amountSats || amountSats <= 0) {
      return res.status(400).json({
        success: false,
        message: "ຈຳນວນ sats ຕ່ຳເກີນໄປ — ກະລຸນາ admin ຕັ້ງ Rate ໃຫ້ຖືກຕ້ອງ",
      });
    }

    // ── ຄ່າທຳນຽມ LAO QR (admin ຕັ້ງໃນ Rate) ───────────────────────────────
    const feePercent = rate.laoQrFeePercent || 0;
    const feeSats = Math.ceil((amountSats * feePercent) / 100);
    const feeLAK = Math.round((amountLAK * feePercent) / 100);
    const totalSats = amountSats + feeSats;

    // ── Atomic: ກວດ + ຫັກ balance ພ້ອມກັນ (ກັນ race condition) ──
    const atomicWallet = await Wallet.findOneAndUpdate(
      { user: userId, balanceSats: { $gte: totalSats + MIN_BALANCE_SATS } },
      { $inc: { balanceSats: -totalSats } },
      { new: true },
    );

    if (!atomicWallet) {
      if (wallet.balanceSats <= 0) {
        return res.status(400).json({
          success: false,
          message: "ຍອດເງິນ sats ໝົດແລ້ວ — ກະລຸນາ TopUp ກ່ອນ",
        });
      }
      return res.status(400).json({
        success: false,
        message: `ຍອດເງິນບໍ່ພໍ (ຕ້ອງການ ${totalSats.toLocaleString()} sats, ມີ ${wallet.balanceSats.toLocaleString()} sats — ຕ້ອງເຫຼືອຢ່າງໜ້ອຍ ${MIN_BALANCE_SATS} sats)`,
      });
    }

    // ── ໂອນ sats ທັງໝົດ (ເງິນ + fee) ເຂົ້າ admin wallet ──
    // LAO QR ບໍ່ມີ Lightning payment ອອກ → sats ຍັງຄ້າງໃນ user LNBits
    if (totalSats > 0) {
      await lnbits.collectFee({ userAdminKey: wallet.adminKey, feeSats: totalSats });
    }

    // ── Sync LNBits baseline + LAK ──
    const lnbitsSnap = await lnbits.getBalance(wallet.invoiceKey);
    const finalLAK = await exchangeRate.convertSatsToLAK(
      atomicWallet.balanceSats,
    );
    await Wallet.updateOne(
      { user: userId },
      {
        $set: { lnbitsBaseSats: lnbitsSnap.balanceSats, balanceLAK: finalLAK },
      },
    );

    const tx = await Transaction.create({
      user: userId,
      wallet: atomicWallet._id,
      type: "laoQR",
      status: "success",
      amountSats,
      amountLAK,
      feeSats,
      feeLAK,
      merchantName: merchantName || "ຮ້ານຄ້າ",
      bank: bank || "",
      qrRaw: qrRaw || "",
      memo: description || "LAO QR Payment",
      kycVerified: isKYCVerified,
      exchangeRate: {
        btcToLAK: rate.btcToLAK,
        btcToUSD: rate.btcToUSD,
        usdToLAK: rate.usdToLAK,
        fetchedAt: rate.fetchedAt,
      },
    });

    createNotification({
      userId: userId,
      title: "ຈ່າຍ LAO QR ສຳເລັດ",
      body: `ຈ່າຍ ${amountLAK.toLocaleString()} ກີບ ທີ່ ${merchantName || "ຮ້ານຄ້າ"}`,
      type: "laoQR",
      transactionId: tx._id,
    });

    return res.status(200).json({
      success: true,
      message: "ສົ່ງເງິນສຳເລັດ",
      todaySpent: todaySpent + amountLAK,
      remaining: remaining - amountLAK,
      dailyLimit,
      transactionId: tx._id,
      payment: {
        amountSats,
        amountLAK,
        feeSats,
        feeLAK,
        feePercent,
        totalSats,
        balanceSats: atomicWallet.balanceSats,
        balanceLAK: finalLAK,
        rate: { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD },
      },
    });
  } catch (error) {
    console.error("LAO QR Pay Error:", error);
    return res
      .status(500)
      .json({ success: false, message: "ເກີດຂໍ້ຜິດພາດໃນການຈ່າຍ LAO QR" });
  }
};

// ════════════════════════════════════════════════════════════════════════════
// GET /api/payment/lao-qr/limit
// ════════════════════════════════════════════════════════════════════════════
exports.getLaoQRLimitStatus = async (req, res) => {
  try {
    const userId = req.user._id;
    const [kyc, rate, limits] = await Promise.all([
      Kyc.findOne({ user: userId }),
      exchangeRate.getExchangeRate(),
      getLimits(),
    ]);
    const isKYCVerified = kyc?.status === "verified";
    const dailyLimit = isKYCVerified
      ? limits.qr.verified
      : limits.qr.unverified;

    const todaySpent = await getDailyLaoQRSpentLAK(userId);
    const remaining = dailyLimit - todaySpent;

    return res.json({
      success: true,
      isKYCVerified,
      dailyLimit,
      todaySpent,
      remaining,
      percentage: Math.min(Math.round((todaySpent / dailyLimit) * 100), 100),
      laoQrFeePercent: rate.laoQrFeePercent || 0,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
