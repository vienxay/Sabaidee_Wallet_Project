// ເຊື່ອມຕໍ່ MongoDB ຜ່ານ Mongoose
// MONGO_URI ຕ້ອງຕັ້ງໃນ .env — ຖ້າຂາດ server ຈະ exit ທັນທີ
const mongoose = require('mongoose');

const connectDB = async () => {
    if (!process.env.MONGO_URI) {
        console.error('MongoDB Error: MONGO_URI is not defined in environment variables');
        process.exit(1);
    }

    try {
        const conn = await mongoose.connect(process.env.MONGO_URI, {
            // serverSelectionTimeoutMS: ເວລາ max ທີ່ Mongoose ລໍຖ້າ MongoDB respond (10s)
            serverSelectionTimeoutMS: 10_000,
            // socketTimeoutMS: ເວລາ max ທີ່ socket ລໍຖ້າ response ຫຼັງ connect ສຳເລັດ (30s)
            socketTimeoutMS:          30_000,
        });
        console.log(`MongoDB Connected: ເຊື່ອມຕໍ່ຖານຂໍ້ມູນສຳເລັດ`);
    } catch (error) {
        console.error(`MongoDB Error: ${error.message}`);
        process.exit(1); // ບໍ່ສາມາດ connect DB → server ບໍ່ຄວນ start
    }
};

module.exports = connectDB;
