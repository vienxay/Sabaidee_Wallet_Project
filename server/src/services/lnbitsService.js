// server/src/services/lnbitsService.js
const axios = require('axios');

const LNBITS_URL = () => process.env.LNBITS_URL?.replace(/\/$/, '');
const ADMIN_KEY   = () => process.env.LNBITS_ADMIN_KEY;

// ─── Helper: headers ──────────────────────────────────────────────────────────
const headers = (key) => ({
  'X-Api-Key': key,
  'Content-Type': 'application/json',
});

// ─── Helper: ຈັດການ error ─────────────────────────────────────────────────────
const handleError = (error, label) => {
  const detail = error.response?.data?.detail || error.message;
  console.error(`❌ LNbits [${label}]:`, detail);
  throw new Error(detail);
};

// ─────────────────────────────────────────────────────────────────────────────

const lnbitsService = {

  // ─── 1. ສ້າງ User + Wallet ໃໝ່ (ໃຊ້ຕອນ register) ──────────────────────────
  createWallet: async (userName) => {
    if (!process.env.LNBITS_URL || !process.env.LNBITS_ADMIN_KEY)
      throw new Error('LNbits configuration is missing (URL or Admin Key)');

    const url     = `${LNBITS_URL()}/usermanager/api/v1/users`;
    const payload = {
      user_name:  userName,
      wallet_name: `Sabaidee_${userName}`,
      admin_id:   process.env.LNBITS_USER_ID,
    };

    try {
      const response = await axios.post(url, payload, { headers: headers(ADMIN_KEY()) });

      if (!response.data?.wallets?.length)
        throw new Error('LNbits created user but no wallet was returned');

      // ✅ filter VoidWallet ອອກ
      const w = response.data.wallets.find((wallet) => wallet.name !== 'VoidWallet');
      if (!w) throw new Error('No valid wallet found — only VoidWallet returned');
      
      return {
        lnbitsUserId: response.data.id,
        walletId:     w.id,
        adminKey:     w.adminkey,
        invoiceKey:   w.inkey,
      };
    } catch (error) {
      handleError(error, 'createWallet');
    }
  },

  // ─── 2. ດຶງ Balance ຂອງ wallet ──────────────────────────────────────────────
  // invoiceKey = inkey ຂອງ user wallet
  getBalance: async (invoiceKey) => {
    try {
      const { data } = await axios.get(
        `${LNBITS_URL()}/api/v1/wallet`,
        { headers: headers(invoiceKey) },
      );
      return {
        balanceMsats: data.balance,                   // LNbits ສົ່ງ msats
        balanceSats:  Math.floor(data.balance / 1000),
      };
    } catch (error) {
      handleError(error, 'getBalance');
    }
  },

  // ─── 3. ສ້າງ Invoice (TopUp) ──────────────────────────────────────────────
  // invoiceKey = inkey, amount = sats
  createInvoice: async ({ invoiceKey, amount, memo = '' }) => {
    try {
      const { data } = await axios.post(
        `${LNBITS_URL()}/api/v1/payments`,
        { out: false, amount, memo },
        { headers: headers(invoiceKey) },
      );
      return {
        paymentHash:    data.payment_hash,
        paymentRequest: data.payment_request,
      };
    } catch (error) {
      handleError(error, 'createInvoice');
    }
  },

  // ─── 4. ຈ່າຍ Invoice (Withdraw) ───────────────────────────────────────────
  // adminKey = adminkey ຂອງ user wallet
  payInvoice: async ({ adminKey, paymentRequest }) => {
    try {
      const { data } = await axios.post(
        `${LNBITS_URL()}/api/v1/payments`,
        { out: true, bolt11: paymentRequest },
        { headers: headers(adminKey) },
      );
      return {
        paymentHash: data.payment_hash,
        feeSats:     Math.floor((data.fee || 0) / 1000),
      };
    } catch (error) {
      handleError(error, 'payInvoice');
    }
  },

  // ─── 5. Decode Invoice ──────────────────────────────────────────────────────
  decodeInvoice: async (paymentRequest) => {
    try {
      const { data } = await axios.post(
        `${LNBITS_URL()}/api/v1/payments/decode`,
        { data: paymentRequest },
        { headers: headers(ADMIN_KEY()) },
      );
      return {
        amountSats:  Math.floor((data.amount_msat || 0) / 1000),
        description: data.description || '',
        paymentHash: data.payment_hash,
        expiry:      data.expiry,
      };
    } catch (error) {
      handleError(error, 'decodeInvoice');
    }
  },

  // ─── 6. ກວດສະຖານະ Invoice ──────────────────────────────────────────────────
  checkPaymentStatus: async ({ invoiceKey, paymentHash }) => {
    try {
      const { data } = await axios.get(
        `${LNBITS_URL()}/api/v1/payments/${paymentHash}`,
        { headers: headers(invoiceKey) },
      );
      return {
        paid:   data.paid === true,
        status: data.paid ? 'paid' : 'pending',
      };
    } catch (error) {
      handleError(error, 'checkPaymentStatus');
    }
  },
};

module.exports = lnbitsService;