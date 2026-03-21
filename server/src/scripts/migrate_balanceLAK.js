// scripts/migrate_balanceLAK.js
const mongoose = require('mongoose');
const Wallet   = require('../models/Wallet');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI).then(async () => {
    const result = await Wallet.updateMany(
        { balanceLAK: { $exists: false } },
        { $set: { balanceLAK: 0 } }
    );
    console.log(`✅ Updated ${result.modifiedCount} wallets`);
    process.exit(0);
});