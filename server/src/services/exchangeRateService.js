const axios = require('axios');
const Rate  = require('../models/Rate');

let cache = {
    btcToUSD        : 0,
    usdToLAK        : 0,
    usdToLAKBase    : 0,
    spreadPercent   : 0,
    laoQrFeePercent : 0,
    btcToLAK        : 0,
    fetchedAt       : null,
};

const CACHE_TTL_MS = 60 * 1000;

const isCacheValid = () =>
    cache.fetchedAt && Date.now() - cache.fetchedAt < CACHE_TTL_MS;

const fetchBTCtoUSD = async () => {
    try {
        const { data } = await axios.get(
            'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT',
            { timeout: 8000 }
        );
        return parseFloat(data.price);
    } catch {
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
        const rateDoc         = await Rate.findOne();
        const usdToLAKBase    = rateDoc?.usdToLAK        || 21000;
        const feePercent      = rateDoc?.laoQrFeePercent || 0;

        // ລາຄາ base ໂດຍກົງ — ບໍ່ມີ spread markup
        const usdToLAK = usdToLAKBase;

        let btcToUSD = cache.btcToUSD || 0;
        try {
            btcToUSD = await fetchBTCtoUSD();
        } catch {
            console.warn('⚠️ BTC fetch failed — ໃຊ້ cache');
        }

        const btcToLAK = Math.round(btcToUSD * usdToLAK);

        cache = {
            btcToUSD,
            usdToLAKBase,
            usdToLAK,
            spreadPercent   : 0,
            laoQrFeePercent : feePercent,
            btcToLAK,
            fetchedAt       : new Date(),
        };

        console.log(`💱 Base: ${usdToLAKBase} | BTC: $${btcToUSD} | btcToLAK: ${btcToLAK} | fee: ${feePercent}%`);
        return { ...cache };

    } catch (error) {
        console.error('Exchange Rate Error:', error.message);
        if (cache.fetchedAt) return { ...cache };
        throw new Error('ບໍ່ສາມາດດຶງອັດຕາແລກປ່ຽນໄດ້');
    }
};

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