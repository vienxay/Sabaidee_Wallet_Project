const axios = require('axios');

// ─── Cache (ປ້ອງກັນຮ້ອງ API ຫຼາຍເກີນ) ────────────────────────────────────────
let cache = {
    btcToUSD: 0,
    usdToLAK: 0,
    btcToLAK: 0,
    fetchedAt: null,
};

const CACHE_TTL_MS = 60 * 1000; // 1 ນາທີ

const isCacheValid = () =>
    cache.fetchedAt && Date.now() - cache.fetchedAt < CACHE_TTL_MS;

// ─── ດຶງ BTC/USD ຈາກ CoinGecko (free, no API key) ────────────────────────────
const fetchBTCtoUSD = async () => {
    const response = await axios.get(
        'https://api.coingecko.com/api/v3/simple/price',
        {
            params: { ids: 'bitcoin', vs_currencies: 'usd' },
            timeout: 8000,
        }
    );
    return response.data.bitcoin.usd;
};

// ─── ດຶງ USD/LAK ຈາກ exchangerate-api ────────────────────────────────────────
const fetchUSDtoLAK = async () => {
    const response = await axios.get(
        `https://open.er-api.com/v6/latest/USD`,
        { timeout: 8000 }
    );
    return response.data.rates.LAK || 20900; // fallback rate
};

// ─── getExchangeRate (ສົ່ງ rates ທັງໝົດ) ─────────────────────────────────────
exports.getExchangeRate = async () => {
    if (isCacheValid()) {
        return { ...cache };
    }

    try {
        const [btcToUSD, usdToLAK] = await Promise.all([
            fetchBTCtoUSD(),
            fetchUSDtoLAK(),
        ]);

        cache = {
            btcToUSD,
            usdToLAK,
            btcToLAK: btcToUSD * usdToLAK,
            fetchedAt: new Date(),
        };

        console.log(`💱 Rate updated: 1 BTC = $${btcToUSD} = ${(btcToUSD * usdToLAK).toLocaleString()} LAK`);
        return { ...cache };
    } catch (error) {
        console.error('Exchange Rate Error:', error.message);

        // ຖ້າ cache ຍັງມີຢູ່ (ເຖິງ expire) ໃຊ້ cache ເກົ່າຕໍ່
        if (cache.fetchedAt) {
            console.warn('⚠️ ໃຊ້ cache ເກົ່າ:', cache.fetchedAt);
            return { ...cache };
        }

        throw new Error('ບໍ່ສາມາດດຶງອັດຕາແລກປ່ຽນໄດ້');
    }
};

// ─── convertSatsToLAK ──────────────────────────────────────────────────────
exports.convertLAKToSats = async (lak) => {
    const rate = await exports.getExchangeRate();
    const btc = lak / rate.btcToLAK;
    return Math.round(btc * 100_000_000); // BTC → sats
};

// ─── convertLAKtoSats ──────────────────────────────────────────────────────
exports.convertSatsToLAK = async (sats) => {
    const rate = await exports.getExchangeRate();
    const btc = sats / 100_000_000; // sats → BTC
    return Math.round(btc * rate.btcToLAK);
};