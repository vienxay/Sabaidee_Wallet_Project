require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

const ADMIN_SEED = {
    name    : process.env.ADMIN_NAME     || 'Super Admin',
    email   : process.env.ADMIN_EMAIL,
    password: process.env.ADMIN_PASSWORD, // ← ສົ່ງ plain text ເລີຍ
    role    : 'admin',
};

async function seedAdmin() {
    if (!ADMIN_SEED.email || !ADMIN_SEED.password) {
        console.error('❌ ກຳນົດ ADMIN_EMAIL ແລະ ADMIN_PASSWORD ໃນ .env ກ່ອນ');
        process.exit(1);
    }

    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB');

    const exists = await User.findOne({ email: ADMIN_SEED.email });
    if (exists) {
        // ✅ ລົບ admin ເກົ່າທີ່ hash ຜິດ ແລ້ວສ້າງໃໝ່
        await User.deleteOne({ email: ADMIN_SEED.email });
        console.log('🗑️  ລົບ admin ເກົ່າ → ສ້າງໃໝ່...');
    }

    // ✅ User.create → pre('save') hash ອັດຕະໂນມັດ — ບໍ່ຕ້ອງ hash ເອງ
    await User.create(ADMIN_SEED);
    console.log(`✅ Admin "${ADMIN_SEED.email}" ຖືກສ້າງແລ້ວ`);
    await mongoose.disconnect();
}

seedAdmin().catch(err => {
    console.error('❌ Seed failed:', err.message);
    process.exit(1);
});