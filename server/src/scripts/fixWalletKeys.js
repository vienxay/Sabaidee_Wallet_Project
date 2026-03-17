// server/src/scripts/fixWalletKeys.js — v2
// ລັນ: node src/scripts/fixWalletKeys.js

require('dotenv').config();
const axios    = require('axios');
const mongoose = require('mongoose');
const Wallet   = require('../models/Wallet');

const LNBITS_URL = process.env.LNBITS_URL?.replace(/\/$/, '');
const ADMIN_KEY  = process.env.LNBITS_ADMIN_KEY;

async function fixWalletKeys() {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB');

    // ─── ດຶງ wallets ທັງໝົດຈາກ LNbits ກ່ອນ ─────────────────────────────────
    console.log('\n📡 ດຶງ wallets ທັງໝົດຈາກ LNbits...');
    const { data: allWallets } = await axios.get(
        `${LNBITS_URL}/usermanager/api/v1/wallets`,
        { headers: { 'X-Api-Key': ADMIN_KEY } }
    );

    // ✅ Log raw response ເບິ່ງ structure ທີ່ແທ້ຈິງ
    console.log('\n📡 RAW LNbits wallets:');
    console.log(JSON.stringify(allWallets, null, 2));

    // ─── filter VoidWallet ອອກ ───────────────────────────────────────────────
    const validWallets = allWallets.filter(w => w.name !== 'VoidWallet');
    console.log(`\n✅ Valid wallets (ບໍ່ລວມ VoidWallet): ${validWallets.length}`);
    validWallets.forEach(w => {
        console.log(`   id: ${w.id} | name: ${w.name} | inkey: ${w.inkey} | adminkey: ${w.adminkey}`);
    });

    // ─── Match + Update DB ───────────────────────────────────────────────────
    const dbWallets = await Wallet.find({}).select('+adminKey');
    console.log(`\n📦 Wallets in DB: ${dbWallets.length}`);

    for (const dbWallet of dbWallets) {
        const match = validWallets.find(w => w.id === dbWallet.walletId);
        if (!match) {
            console.log(`⚠️  walletId ${dbWallet.walletId} ບໍ່ພົບໃນ LNbits`);
            continue;
        }

        await Wallet.updateOne(
            { _id: dbWallet._id },
            { $set: { invoiceKey: match.inkey, adminKey: match.adminkey } }
        );
        console.log(`✅ Updated: ${dbWallet.walletId}`);
        console.log(`   invoiceKey → ${match.inkey}`);
        console.log(`   adminKey   → ${match.adminkey}`);
    }

    console.log('\n🏁 Done');
    await mongoose.disconnect();
}

fixWalletKeys().catch(console.error);