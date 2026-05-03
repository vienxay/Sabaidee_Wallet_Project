const axios = require('axios');
const Rate  = require('../models/Rate');

let cache = {
    btcToUSD : 0,
    usdToLAK : 0,
    btcToLAK : 0,
    fetchedAt: null,
};

const CACHE_TTL_MS = 60 * 1000;

const isCacheValid = () =>
    cache.fetchedAt && Date.now() - cache.fetchedAt < CACHE_TTL_MS;

const fetchBTCtoUSD = async () => {
    try {
        // ✅ ລອງ Binance ກ່ອນ
        const { data } = await axios.get(
            'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT',
            { timeout: 8000 }
        );
        return parseFloat(data.price);
    } catch {
        // ✅ fallback CoinGecko
        const { data } = await axios.get(
            'https://api.coingecko.com/api/v3/simple/price',
            { params: { ids: 'bitcoin', vs_currencies: 'usd' }, timeout: 8000 }
        );
        return data.bitcoin.usd;
    }
};

exports.getExchangeRate = async () => {
    if (isCacheValid()) return { ...cache };

    try {
        // ✅ ດຶງ usdToLAK ຈາກ DB ທີ່ admin ຕັ້ງ
        const rateDoc  = await Rate.findOne();
        const usdToLAK = rateDoc?.usdToLAK || 21000;

        // ✅ ດຶງ BTC/USD real-time
        let btcToUSD = cache.btcToUSD || 0;
        try {
            btcToUSD = await fetchBTCtoUSD();
        } catch {
            console.warn('⚠️ CoinGecko failed — ໃຊ້ cache');
        }

        const btcToLAK = Math.round(btcToUSD * usdToLAK);

        cache = {
            btcToUSD,
            usdToLAK,
            btcToLAK,
            fetchedAt: new Date(),
        };

        console.log(`💱 Rate: $${btcToUSD} | 1USD=${usdToLAK}ກີບ | 1BTC=${btcToLAK.toLocaleString()}ກີບ`);
        return { ...cache };

    } catch (error) {
        console.error('Exchange Rate Error:', error.message);
        if (cache.fetchedAt) {
            console.warn('⚠️ ໃຊ້ cache ເກົ່າ:', cache.fetchedAt);
            return { ...cache };
        }
        throw new Error('ບໍ່ສາມາດດຶງອັດຕາແລກປ່ຽນໄດ້');
    }
};

// ✅ clear cache — call ຫຼັງ admin update rate
exports.clearCache = () => {
    cache.fetchedAt = null;
    console.log('🔄 Rate cache cleared');
};

exports.convertSatsToLAK = async (sats) => {
    const rate = await exports.getExchangeRate();
    return Math.round((sats / 100_000_000) * rate.btcToLAK);
};

exports.convertLAKToSats = async (lak) => {
    const rate = await exports.getExchangeRate();
    return Math.round((lak / rate.btcToLAK) * 100_000_000);
};