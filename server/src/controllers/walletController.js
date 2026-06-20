const Wallet = require("../models/Wallet");
const Transaction = require("../models/Transaction");
const lnbits = require("../services/lnbitsService");
const exchangeRate = require("../services/exchangeRateService");
const Rate = require("../models/Rate");
const { createNotification } = require("./notificationController");

// ════════════════════════════════════════════════════════════════════════════
// GET /api/wallet
// ════════════════════════════════════════════════════════════════════════════
exports.getWallet = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ user: req.user._id });
    if (!wallet)
      return res.status(404).json({ success: false, message: "ບໍ່ພົບ Wallet" });

    const rate = await exchangeRate.getExchangeRate();
    const balanceLAK = await exchangeRate.convertSatsToLAK(wallet.balanceSats);

    res.status(200).json({
      success: true,
      wallet: {
        walletId: wallet.walletId,
        walletName: wallet.walletName,
        invoiceKey: wallet.invoiceKey,
        balanceSats: wallet.balanceSats,
        balanceLAK, // ✅ คํานวณ real-time ຈາກ rate ປັດຈຸບັນ
        rate: {
          btcToUSD: rate.btcToUSD,
          btcToLAK: rate.btcToLAK,
          updatedAt: rate.fetchedAt,
        },
      },
    });
  } catch (error) {
    console.error("Get Wallet Error:", error);
    return res
      .status(500)
      .json({ success: false, message: "ເກີດຂໍ້ຜິດພາດໃນລະບົບ" });
  }
};

// ════════════════════════════════════════════════════════════════════════════
// GET /api/wallet/balance
// ════════════════════════════════════════════════════════════════════════════
exports.getBalance = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ user: req.user._id });
    if (!wallet)
      return res.status(404).json({ success: false, message: "ບໍ່ພົບ Wallet" });

    const rate = await exchangeRate.getExchangeRate();

    try {
      const lnbitsResult = await lnbits.getBalance(wallet.invoiceKey);
      const lnbitsCurrent = lnbitsResult.balanceSats;

      // ຄຳນວນ delta: ຖ້າ LNBits ເພີ່ມຂຶ້ນ = ມີ topup ໃໝ່ເຂົ້າ
      const lnbitsBase = wallet.lnbitsBaseSats ?? lnbitsCurrent;
      const topupDelta = Math.max(0, lnbitsCurrent - lnbitsBase);

      wallet.balanceSats = Math.max(0, wallet.balanceSats + topupDelta);
      wallet.lnbitsBaseSats = lnbitsCurrent;
      wallet.balanceLAK = await exchangeRate.convertSatsToLAK(
        wallet.balanceSats,
      );
      await wallet.save();

      return res.status(200).json({
        success: true,
        balance: {
          sats: wallet.balanceSats,
          msats: wallet.balanceSats * 1000,
          lak: wallet.balanceLAK,
          btcToLAK: rate.btcToLAK,
          btcToUSD: rate.btcToUSD,
          rateAt: rate.fetchedAt,
        },
      });
    } catch (lnbitsErr) {
      // LNBits ໄດ້ → fallback ໃຊ້ balance ຈາກ DB ທີ່ cache ໄວ້
      console.warn(
        "⚠️ LNBits unavailable, using cached balance:",
        lnbitsErr.message,
      );
      const cachedLAK = await exchangeRate.convertSatsToLAK(wallet.balanceSats);

      return res.status(200).json({
        success: true,
        cached: true, // flag ໃຫ້ Flutter ຮູ້ວ່າໃຊ້ cache
        balance: {
          sats: wallet.balanceSats,
          msats: wallet.balanceSats * 1000,
          lak: cachedLAK,
          btcToLAK: rate.btcToLAK,
          btcToUSD: rate.btcToUSD,
          rateAt: rate.fetchedAt,
        },
      });
    }
  } catch (error) {
    console.error("Get Balance Error:", error);
    return res
      .status(500)
      .json({ success: false, message: "ເກີດຂໍ້ຜິດພາດໃນລະບົບ" });
  }
};

// ════════════════════════════════════════════════════════════════════════════
// GET /api/wallet/rate
// ════════════════════════════════════════════════════════════════════════════
exports.getRate = async (req, res) => {
  try {
    // ✅ ດຶງຈາກ DB ດຽວກັບ admin — rate ຕົງກັນ 100%
    const rateDoc = await Rate.findOne();
    res.status(200).json({
      success: true,
      rate: {
        btcToUSD: rateDoc?.btcToUSD || 0,
        btcToLAK: rateDoc?.btcToLAK || 0,
        usdToLAK: rateDoc?.usdToLAK || 0,
        updatedAt: rateDoc?.updatedAt || null,
      },
    });
  } catch (error) {
    console.error("Get Rate Error:", error);
    return res
      .status(500)
      .json({ success: false, message: "ເກີດຂໍ້ຜິດພາດໃນລະບົບ" });
  }
};

// ════════════════════════════════════════════════════════════════════════════
// POST /api/wallet/topup
// ════════════════════════════════════════════════════════════════════════════
exports.topUp = async (req, res) => {
  try {
    const { amountSats, memo } = req.body;
    if (!amountSats || amountSats < 1)
      return res.status(400).json({ success: false, message: "ຕ່ຳສຸດ 1 sat" });

    const wallet = await Wallet.findOne({ user: req.user._id });
    if (!wallet)
      return res.status(404).json({ success: false, message: "ບໍ່ພົບ Wallet" });

    const rate = await exchangeRate.getExchangeRate();
    const amountLAK = await exchangeRate.convertSatsToLAK(amountSats);

    const invoiceResult = await lnbits.createInvoice({
      invoiceKey: wallet.invoiceKey,
      amount: amountSats,
      memo: memo || `TopUp ${amountSats} sats`,
    });

    const transaction = await Transaction.create({
      user: req.user._id,
      wallet: wallet._id,
      type: "topup",
      status: "pending",
      amountSats,
      amountLAK,
      paymentHash: invoiceResult.paymentHash,
      paymentRequest: invoiceResult.paymentRequest,
      memo: memo || `TopUp ${amountSats} sats`,
      exchangeRate: {
        btcToLAK: rate.btcToLAK,
        btcToUSD: rate.btcToUSD,
        usdToLAK: rate.usdToLAK,
        fetchedAt: rate.fetchedAt,
      },
    });

    res.status(201).json({
      success: true,
      message: "ສ້າງ Invoice TopUp ສຳເລັດ — ສະແກນ QR ເພື່ອຈ່າຍ",
      topup: {
        transactionId: transaction._id,
        paymentRequest: invoiceResult.paymentRequest,
        paymentHash: invoiceResult.paymentHash,
        amountSats,
        amountLAK,
        rate: { btcToLAK: rate.btcToLAK, btcToUSD: rate.btcToUSD },
      },
    });
  } catch (error) {
    console.error("TopUp Error:", error);
    return res
      .status(500)
      .json({ success: false, message: "ເກີດຂໍ້ຜິດພາດໃນລະບົບ" });
  }
};

// ════════════════════════════════════════════════════════════════════════════
// POST /api/wallet/withdraw
// ════════════════════════════════════════════════════════════════════════════
exports.withdraw = async (req, res) => {
  try {
    const { paymentRequest, memo } = req.body;
    if (!paymentRequest)
      return res
        .status(400)
        .json({ success: false, message: "ກະລຸນາໃສ່ Lightning Invoice" });

    const [decoded, rate] = await Promise.all([
      lnbits.decodeInvoice(paymentRequest),
      exchangeRate.getExchangeRate(),
    ]);

    const amountSats = decoded.amountSats;
    const amountLAK = await exchangeRate.convertSatsToLAK(amountSats);

    // ── Atomic: ກວດ + ຫັກ balance ພ້ອມກັນ (ກັນ race condition) ──
    const wallet = await Wallet.findOneAndUpdate(
      { user: req.user._id, balanceSats: { $gte: amountSats } },
      { $inc: { balanceSats: -amountSats } },
      { new: true },
    ).select("+adminKey");

    if (!wallet) {
      const w = await Wallet.findOne({ user: req.user._id });
      if (!w)
        return res
          .status(404)
          .json({ success: false, message: "ບໍ່ພົບ Wallet" });
      return res.status(400).json({
        success: false,
        message: `ຍອດເງິນບໍ່ພໍ (ຕ້ອງການ ${amountSats.toLocaleString()} sats, ມີ ${w.balanceSats.toLocaleString()} sats)`,
      });
    }

    let payResult;
    try {
      payResult = await lnbits.payInvoice({
        adminKey: wallet.adminKey,
        paymentRequest,
      });
    } catch (lnbitsErr) {
      // LNBits ລົ້ມເຫຼວ → ຄືນເງິນທີ່ຫັກໄວ້
      await Wallet.updateOne(
        { user: req.user._id },
        { $inc: { balanceSats: amountSats } },
      );
      throw lnbitsErr;
    }

    // ── Sync LNBits baseline ──
    const lnbitsAfter = await lnbits.getBalance(wallet.invoiceKey);
    const finalLAK = await exchangeRate.convertSatsToLAK(wallet.balanceSats);

    await Wallet.updateOne(
      { user: req.user._id },
      {
        $set: {
          balanceLAK: finalLAK,
          lnbitsBaseSats: lnbitsAfter.balanceSats,
        },
      },
    );

    const transaction = await Transaction.create({
      user: req.user._id,
      wallet: wallet._id,
      type: "withdraw",
      status: "success",
      amountSats,
      amountLAK,
      feeSats: 0,
      feeLAK: 0,
      paymentHash: payResult.paymentHash,
      paymentRequest,
      memo: memo || decoded.description || "Withdraw",
      exchangeRate: {
        btcToLAK: rate.btcToLAK,
        btcToUSD: rate.btcToUSD,
        usdToLAK: rate.usdToLAK,
        fetchedAt: rate.fetchedAt,
      },
    });

    createNotification({
      userId: req.user._id,
      title: "💸 ຖອນເງິນສຳເລັດ",
      body: `ຖອນ ${amountSats.toLocaleString()} sats (${amountLAK.toLocaleString()} ກີບ)`,
      type: "withdraw",
      transactionId: transaction._id,
    });

    res.status(200).json({
      success: true,
      message: "ຖອນເງິນສຳເລັດ",
      withdraw: {
        transactionId: transaction._id,
        paymentHash: payResult.paymentHash,
        amountSats,
        amountLAK,
        feeSats: 0,
        balanceSats: wallet.balanceSats,
        balanceLAK: finalLAK,
      },
    });
  } catch (error) {
    console.error("Withdraw Error:", error);
    return res
      .status(500)
      .json({ success: false, message: "ເກີດຂໍ້ຜິດພາດໃນລະບົບ" });
  }
};

// ════════════════════════════════════════════════════════════════════════════
// GET /api/wallet/topup/:paymentHash/status
// ════════════════════════════════════════════════════════════════════════════
exports.checkPaymentStatus = async (req, res) => {
  try {
    const { paymentHash } = req.params;

    const wallet = await Wallet.findOne({ user: req.user._id });
    if (!wallet)
      return res.status(404).json({ success: false, message: "ບໍ່ພົບ Wallet" });

    const result = await lnbits.checkPaymentStatus({
      invoiceKey: wallet.invoiceKey,
      paymentHash,
    });

    if (result.paid) {
      const tx = await Transaction.findOneAndUpdate(
        { paymentHash, user: req.user._id },
        { status: "success" },
        { new: true },
      );

      // Topup ສຳເລັດ → ໃຊ້ delta ເພື່ອບໍ່ດຶງເງິນເກົ່າກັບມາ
      const balanceResult = await lnbits.getBalance(wallet.invoiceKey);
      const lnbitsCurrent = balanceResult.balanceSats;
      const lnbitsBase = wallet.lnbitsBaseSats ?? lnbitsCurrent;
      const topupDelta = Math.max(0, lnbitsCurrent - lnbitsBase);

      wallet.balanceSats = Math.max(0, wallet.balanceSats + topupDelta);
      wallet.lnbitsBaseSats = lnbitsCurrent;
      wallet.balanceLAK = await exchangeRate.convertSatsToLAK(
        wallet.balanceSats,
      );
      await wallet.save();

      if (tx) {
        createNotification({
          userId: req.user._id,
          title: "ເງິນເຂົ້າສຳເລັດ",
          body: `ຮັບ ${tx.amountSats.toLocaleString()} sats (${tx.amountLAK.toLocaleString()} ກີບ)`,
          type: "topup",
          transactionId: tx._id,
        });
      }
    }

    res.status(200).json({
      success: true,
      paid: result.paid,
      status: result.status,
    });
  } catch (error) {
    console.error("CheckPaymentStatus Error:", error);
    return res
      .status(500)
      .json({ success: false, message: "ເກີດຂໍ້ຜິດພາດໃນລະບົບ" });
  }
};
