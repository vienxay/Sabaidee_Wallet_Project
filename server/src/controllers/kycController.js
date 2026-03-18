// controllers/kycController.js
const User = require('../models/User');
const Kyc  = require('../models/Kyc');
const { cloudinary } = require('../services/cloudinaryService');

const genRefId = () => 'KYC-' + Date.now().toString(36).toUpperCase();

const uploadToCloudinary = (buffer, folder) =>
    new Promise((resolve, reject) => {
        cloudinary.uploader.upload_stream(
            { folder, resource_type: 'image' },
            (err, result) => err ? reject(err) : resolve(result)
        ).end(buffer);
    });

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/kyc/submit
// ─────────────────────────────────────────────────────────────────────────────
exports.submitKyc = async (req, res) => {
    try {
        const userId = req.user._id;

        // ── ກວດ duplicate ───────────────────────────────────────────────────
        if (['pending', 'verified'].includes(req.user.kycStatus)) {
            return res.status(409).json({
                success: false,
                message: req.user.kycStatus === 'verified'
                    ? 'KYC ຂອງທ່ານຜ່ານການຢືນຢັນແລ້ວ'
                    : 'KYC ຂອງທ່ານກຳລັງຖືກກວດສອບຢູ່',
                kycStatus: req.user.kycStatus,
            });
        }

        // ── Validate fields ─────────────────────────────────────────────────
        const {
            fullName, dob, passportNumber, expiryDate, gender,
             placeOfBirth,  isPep, 
            consentData, consentPdpa,
        } = req.body;

        if (!fullName || !dob || !passportNumber || !expiryDate || !gender) {
            return res.status(400).json({
                success: false,
                message: 'ຂໍ້ມູນບໍ່ຄົບ: fullName, dob, passportNumber, expiryDate, gender',
            });
        }
        if (consentData !== 'true') {
            return res.status(400).json({
                success: false,
                message: 'ຕ້ອງຍິນຍອມ consentData',
            });
        }
        if (!req.files?.idFront?.[0] || !req.files?.selfie?.[0]) {
            return res.status(400).json({
                success: false,
                message: 'ຕ້ອງອັບໂຫລດ idFront ແລະ selfie',
            });
        }

        // ── Upload Cloudinary ───────────────────────────────────────────────
        const uploadPromises = [
            uploadToCloudinary(req.files.idFront[0].buffer, `kyc/${userId}/idFront`),
            uploadToCloudinary(req.files.selfie[0].buffer,  `kyc/${userId}/selfie`),
        ];
        

        const [frontResult, selfieResult, backResult] = await Promise.all(uploadPromises);

        // ── Save Kyc document ───────────────────────────────────────────────
        const referenceId = genRefId();
        const kyc = await Kyc.create({
            user:           userId,
            fullName,
            gender,
            dob:            new Date(dob),
            passportNumber: passportNumber.toUpperCase(),
            nationality:    nationality  || 'null',
            email:          req.user.email,
            expiryDate:     new Date(expiryDate),
            idFrontUrl:     frontResult.secure_url,
            selfieUrl:      selfieResult.secure_url,
            isPep:          isPep === 'true',
            consentData:    true,
            consentPdpa:    consentPdpa === 'true',
            referenceId,
            status:         'pending',
            submittedAt:    new Date(),
        });  

        // ── Update User ─────────────────────────────────────────────────────
        await User.findByIdAndUpdate(userId, {
            kycStatus: 'pending',
            kyc:       kyc._id,
        });

        return res.status(201).json({
            success:     true,
            message:     'ສົ່ງ KYC ສຳເລັດ — ກຳລັງດຳເນີນການກວດສອບ',
            referenceId,
            kycStatus:   'pending',
        });

    } catch (err) {
        console.error('submitKyc error:', err);
        return res.status(500).json({
            success: false,
            message: 'Server error',
            error:   err.message,
        });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/kyc — ດຶງ status + ລາຍລະອຽດ
// ─────────────────────────────────────────────────────────────────────────────
exports.getMyKycStatus = async (req, res) => {
    try {
        const kyc = await Kyc.findOne({ user: req.user._id })
            .select('-__v');

        return res.json({
            success:   true,
            kycStatus: req.user.kycStatus,
            kyc:       kyc || null,
        });
    } catch (err) {
        return res.status(500).json({ success: false, message: 'Server error', error: err.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PUT /api/kyc/verify/:userId  (Admin)
// ─────────────────────────────────────────────────────────────────────────────
exports.reviewKyc = async (req, res) => {
    try {
        const { status, reviewNote } = req.body;
        if (!['verified', 'rejected'].includes(status)) {
            return res.status(400).json({
                success: false,
                message: 'status ຕ້ອງເປັນ verified ຫລື rejected',
            });
        }

        const user = await User.findById(req.params.userId);
        if (!user) return res.status(404).json({ success: false, message: 'ບໍ່ພົບ User' });

        // ── Update Kyc document ─────────────────────────────────────────────
        await Kyc.findOneAndUpdate(
            { user: user._id },
            {
                status,
                reviewNote:  reviewNote || null,
                reviewedBy:  req.user._id,
                reviewedAt:  new Date(),
            }
        );

        // ── Update User kycStatus ───────────────────────────────────────────
        user.kycStatus = status;
        await user.save();

        return res.json({
            success: true,
            message: `KYC ${status === 'verified' ? 'ຜ່ານການຢືນຢັນ' : 'ຖືກປະຕິເສດ'} ສຳເລັດ`,
            user: {
                id:        user._id,
                name:      user.name,
                email:     user.email,
                kycStatus: user.kycStatus,
            },
        });
    } catch (err) {
        return res.status(500).json({ success: false, message: 'Server error', error: err.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/kyc/list?status=pending  (Admin)
// ─────────────────────────────────────────────────────────────────────────────
exports.listKyc = async (req, res) => {
    try {
        const { status, page = 1, limit = 20 } = req.query;
        const filter = status ? { status } : { status: { $in: ['pending', 'verified', 'rejected'] } };

        const [kycs, total] = await Promise.all([
            Kyc.find(filter)
                .populate('user', 'name email')
                .select('-__v')
                .sort({ submittedAt: -1 })
                .skip((page - 1) * limit)
                .limit(Number(limit)),
            Kyc.countDocuments(filter),
        ]);

        return res.json({ success: true, total, page: Number(page), data: kycs });
    } catch (err) {
        return res.status(500).json({ success: false, message: 'Server error', error: err.message });
    }
};