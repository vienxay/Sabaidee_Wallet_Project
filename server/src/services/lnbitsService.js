const axios = require('axios');

const LNBITS_URL = () => process.env.LNBITS_URL?.replace(/\/$/, '');
const ADMIN_KEY = () => process.env.LNBITS_ADMIN_KEY;

const headers = (key) => ({
    'X-Api-Key': key,
    'Content-Type': 'application/json',
});

const handleError = (error, label) => {
    const responseData = error.response?.data;
    const status = error.response?.status;

    console.error(`LNbits [${label}] status:`, status);
    console.error(`LNbits [${label}] detail:`, JSON.stringify(responseData, null, 2));

    const detail = responseData?.detail || responseData?.message || error.message;
    throw new Error(detail);
};

const lnbitsService = {
    createWallet: async (userName) => {
        if (!process.env.LNBITS_URL || !process.env.LNBITS_ADMIN_KEY) {
            throw new Error('LNbits configuration is missing (URL or Admin Key)');
        }

        const url = `${LNBITS_URL()}/usermanager/api/v1/users`;
        const payload = {
            user_name: userName,
            wallet_name: `Sabaidee_${userName}`,
            admin_id: process.env.LNBITS_USER_ID,
        };

        try {
            const response = await axios.post(url, payload, { headers: headers(ADMIN_KEY()) });

            if (!response.data?.wallets?.length) {
                throw new Error('LNbits created user but no wallet was returned');
            }

            const wallet = response.data.wallets.find((item) => item.name !== 'VoidWallet');
            if (!wallet) {
                throw new Error('No valid wallet found - only VoidWallet returned');
            }

            return {
                lnbitsUserId: response.data.id,
                walletId: wallet.id,
                adminKey: wallet.adminkey,
                invoiceKey: wallet.inkey,
            };
        } catch (error) {
            handleError(error, 'createWallet');
        }
    },

    getBalance: async (invoiceKey) => {
        try {
            const { data } = await axios.get(`${LNBITS_URL()}/api/v1/wallet`, {
                headers: headers(invoiceKey),
            });

            return {
                balanceMsats: data.balance,
                balanceSats: Math.floor(data.balance / 1000),
            };
        } catch (error) {
            handleError(error, 'getBalance');
        }
    },

    createInvoice: async ({ invoiceKey, amount, memo = '' }) => {
        try {
            const { data } = await axios.post(
                `${LNBITS_URL()}/api/v1/payments`,
                { out: false, amount, memo },
                { headers: headers(invoiceKey) },
            );

            return {
                paymentHash: data.payment_hash,
                paymentRequest: data.payment_request,
            };
        } catch (error) {
            handleError(error, 'createInvoice');
        }
    },

    payInvoice: async ({ adminKey, paymentRequest }) => {
        try {
            const { data } = await axios.post(
                `${LNBITS_URL()}/api/v1/payments`,
                { out: true, bolt11: paymentRequest },
                { headers: headers(adminKey) },
            );

            return {
                paymentHash: data.payment_hash,
                feeSats: Math.floor((data.fee || 0) / 1000),
            };
        } catch (error) {
            handleError(error, 'payInvoice');
        }
    },

    deleteWallet: async (walletId) => {
        try {
            await axios.delete(`${LNBITS_URL()}/usermanager/api/v1/wallets/${walletId}`, {
                headers: headers(ADMIN_KEY()),
            });
            return true;
        } catch (error) {
            handleError(error, 'deleteWallet');
        }
    },

    decodeInvoice: async (paymentRequest) => {
        try {
            const cleanInvoice = paymentRequest.replace(/^lightning:/i, '').trim();

            const { data } = await axios.post(
                `${LNBITS_URL()}/api/v1/payments/decode`,
                { data: cleanInvoice },
                { headers: headers(ADMIN_KEY()) },
            );

            return {
                amountSats: Math.floor((data.amount_msat || data.msat || 0) / 1000),
                description: data.description || '',
                paymentHash: data.payment_hash,
                expiry: data.expiry,
            };
        } catch (error) {
            handleError(error, 'decodeInvoice');
        }
    },

    checkPaymentStatus: async ({ invoiceKey, paymentHash }) => {
        try {
            const { data } = await axios.get(`${LNBITS_URL()}/api/v1/payments/${paymentHash}`, {
                headers: headers(invoiceKey),
            });

            return {
                paid: data.paid === true,
                status: data.paid ? 'paid' : 'pending',
            };
        } catch (error) {
            handleError(error, 'checkPaymentStatus');
        }
    },
};

module.exports = lnbitsService;
