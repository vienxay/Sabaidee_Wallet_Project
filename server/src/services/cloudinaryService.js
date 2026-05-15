// Cloudinary Service — ຈັດການ upload ຮູບ profile ໄປ cloud storage
// ຂໍ້ຮຽກ: CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET ໃນ .env
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');

// ຕັ້ງຄ່າ Cloudinary ຈາກ environment variables
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key:    process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Storage config: ຮູບຖືກ upload ໂດຍອັດຕະໂນມັດ ໄປ folder sabaidee_wallet/profiles
// transformation: crop ຮູບເປັນ 400×400 ໂດຍ focus ໃສ່ໃບໜ້າ (face-aware)
const storage = new CloudinaryStorage({
    cloudinary,
    params: {
        folder:           'sabaidee_wallet/profiles',
        allowed_formats:  ['jpg', 'jpeg', 'png', 'webp'],
        transformation:   [{ width: 400, height: 400, crop: 'fill', gravity: 'face' }],
    },
});

// multer middleware ສຳລັບ upload ຮູບ — limit 5MB ຕໍ່ file
// ໃຊ້: upload.single('avatar') ໃນ route
const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
});

module.exports = { cloudinary, upload };
