// ─── utils/lightningUtils.js ──────────────────────────────────────────────────
const axios  = require('axios');
const bech32 = require('bech32');

const isLightningAddress = (str) =>
    /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(str.trim());

const isLNURL = (str) =>
    str.toUpperCase().startsWith('LNURL');

const decodeLNURL = (lnurl) => {
    const decoded = bech32.bech32.decode(lnurl, 2000);
    const bytes   = bech32.bech32.fromWords(decoded.words);
    return Buffer.from(bytes).toString('utf8');
};

const fetchInvoiceFromLNURL = async (lnurl, amountSats) => {
    const url = decodeLNURL(lnurl);
    const { data: meta } = await axios.get(url, { timeout: 10_000 });
    if (meta.tag !== 'payRequest') throw new Error('ບໍ່ຮອງຮັບ LNURL ນີ້');

    const amountMsats = amountSats * 1000;
    if (amountMsats < meta.minSendable || amountMsats > meta.maxSendable) {
        const minS = Math.ceil(meta.minSendable / 1000);
        const maxS = Math.floor(meta.maxSendable / 1000);
        throw new Error(`ຈຳນວນຕ້ອງຢູ່ລະຫວ່າງ ${minS} – ${maxS} sats`);
    }

    const { data: inv } = await axios.get(
        `${meta.callback}?amount=${amountMsats}`,
        { timeout: 10_000 }
    );
    if (!inv.pr) throw new Error('ບໍ່ສາມາດຂໍ invoice ຈາກ LNURL ໄດ້');
    return inv.pr;
};

const fetchInvoiceFromAddress = async (address, amountSats) => {
    const [user, domain] = address.split('@');
    const { data: meta } = await axios.get(
        `https://${domain}/.well-known/lnurlp/${user}`,
        { timeout: 10_000 }
    );
    if (meta.tag !== 'payRequest') throw new Error('ບໍ່ຮອງຮັບ Lightning Address ນີ້');

    const amountMsats = amountSats * 1000;
    if (amountMsats < meta.minSendable || amountMsats > meta.maxSendable) {
        const minS = Math.ceil(meta.minSendable / 1000);
        const maxS = Math.floor(meta.maxSendable / 1000);
        throw new Error(`ຈຳນວນຕ້ອງຢູ່ລະຫວ່າງ ${minS} – ${maxS} sats`);
    }

    const { data: inv } = await axios.get(
        `${meta.callback}?amount=${amountMsats}`,
        { timeout: 10_000 }
    );
    if (!inv.pr) throw new Error('ຂໍ invoice ຈາກ Lightning Address ບໍ່ສຳເລັດ');
    return inv.pr;
};

module.exports = {
    isLightningAddress,
    isLNURL,
    decodeLNURL,
    fetchInvoiceFromLNURL,
    fetchInvoiceFromAddress,
};
