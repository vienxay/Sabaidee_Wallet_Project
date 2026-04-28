// controllers/kycController.js
const User = require('../models/User');
const Kyc  = require('../models/Kyc');
const { cloudinary } = require('../services/cloudinaryService');
const { sendKycApprovedEmail, sendKycRejectedEmail } = require('../services/emailService');

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
    console.log('=== KYC Submit ===');
    console.log('body:', req.body);
    console.log('files:', req.files);

    try {
        const userId = req.user._id;

        const freshUser = await User.findById(userId).select('kycStatus email name');
        if (!freshUser) {
            return res.status(404).json({ success: false, message: 'ບໍ່ພົບ user' });
        }

        // ── ກວດ duplicate ───────────────────────────────────────────────────
        if (['pending', 'verified'].includes(freshUser.kycStatus)) {
            return res.status(409).json({
                success: false,
                message: freshUser.kycStatus === 'verified'
                    ? 'KYC ຂອງທ່ານຜ່ານການຢືນຢັນແລ້ວ'
                    : 'KYC ຂອງທ່ານກຳລັງຖືກກວດສອບຢູ່',
                kycStatus: freshUser.kycStatus,
            });
        }

        // ── Validate fields ─────────────────────────────────────────────────
        const {
            fullName, dob, passportNumber, expiryDate,
            gender, nationality, consentData,
        } = req.body;

        if (!fullName || !dob || !passportNumber || !expiryDate || !gender || !nationality) {
            return res.status(400).json({
                success: false,
                message: 'ຂໍ້ມູນບໍ່ຄົບ: fullName, dob, passportNumber, expiryDate, gender, nationality',
            });
        }

        if (consentData !== 'true') {
            return res.status(400).json({
                success: false,
                message: 'ຕ້ອງຍິນຍອມ consentData',
            });
        }

        if (!req.files?.idFront?.[0]) {
            return res.status(400).json({
                success: false,
                message: 'ຕ້ອງອັບໂຫລດຮູບ passport (idFront)',
            });
        }

        // ── Upload Cloudinary ───────────────────────────────────────────────
        const frontResult = await uploadToCloudinary(
            req.files.idFront[0].buffer,
            `kyc/${userId}/idFront`
        );

        // ✅ ແກ້ທີ 1 — upload selfie ຖ້າມີ
        let selfieUrl = null;
        if (req.files?.selfie?.[0]) {
            const selfieResult = await uploadToCloudinary(
                req.files.selfie[0].buffer,
                `kyc/${userId}/selfie`
            );
            selfieUrl = selfieResult.secure_url;
        }

        // ── Save Kyc document ───────────────────────────────────────────────
        const referenceId = genRefId();
        const kyc = await Kyc.create({
            user:           userId,
            fullName,
            gender,
            dob:            new Date(dob),
            nationality,
            email:          req.user.email,
            passportNumber: passportNumber.toUpperCase(),
            expiryDate:     new Date(expiryDate),
            idFrontUrl:     frontResult.secure_url,
            selfieUrl,                                  // ✅ ເພີ່ມ selfieUrl
            consentData:    true,
            consentPdpa:    req.body.consentPdpa === 'true',
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
            success:   true,
            message:   'ສົ່ງ KYC ສຳເລັດ — ກຳລັງດຳເນີນການກວດສອບ',
            kycStatus: 'pending',
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
// GET /api/kyc
// ─────────────────────────────────────────────────────────────────────────────
exports.getMyKycStatus = async (req, res) => {
    try {
        const kyc = await Kyc.findOne({ user: req.user._id }).select('-__v');

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
// PUT /api/kyc/verify/:userId  (Admin/Staff)
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
        if (!user) {
            return res.status(404).json({ success: false, message: 'ບໍ່ພົບ User' });
        }

        // ✅ ແກ້ທີ 2 — ກວດ KYC ກ່ອນ review
        const kyc = await Kyc.findOne({ user: user._id });
        if (!kyc) {
            return res.status(404).json({ success: false, message: 'ບໍ່ພົບ KYC ຂອງ User ນີ້' });
        }

        await kyc.updateOne({
            status,
            reviewNote:  reviewNote || null,
            reviewedBy:  req.user._id,
            reviewedAt:  new Date(),
        });

        user.kycStatus = status;
        await user.save();

        // ── ສົ່ງ Email ແຈ້ງເຕືອນ ────────────────────────────────────────────
        if (status === 'verified') {
            sendKycApprovedEmail(user.email, user.name)
                .then(result => {
                    if (result.success) console.log('✅ KYC approval email sent to:', user.email);
                    else console.error('❌ Failed to send approval email:', result.error);
                })
                .catch(err => console.error('❌ Email error:', err));
        } else if (status === 'rejected') {
            sendKycRejectedEmail(user.email, user.name, reviewNote)
                .then(result => {
                    if (result.success) console.log('✅ KYC rejection email sent to:', user.email);
                    else console.error('❌ Failed to send rejection email:', result.error);
                })
                .catch(err => console.error('❌ Email error:', err));
        }

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
// GET /api/kyc/list?status=pending  (Admin/Staff)
// ─────────────────────────────────────────────────────────────────────────────
exports.listKyc = async (req, res) => {
    try {
        const { status } = req.query;

        // ✅ ແກ້ທີ 3 — convert page/limit ເປັນ Number ກ່ອນໃຊ້
        const pageNum  = Number(req.query.page)  || 1;
        const limitNum = Number(req.query.limit) || 20;

        const filter = status
            ? { status }
            : { status: { $in: ['pending', 'verified', 'rejected'] } };

        const [kycs, total] = await Promise.all([
            Kyc.find(filter)
                .populate('user', 'name email')
                .select('-__v')
                .sort({ submittedAt: -1 })
                .skip((pageNum - 1) * limitNum)
                .limit(limitNum),
            Kyc.countDocuments(filter),
        ]);

        return res.json({ success: true, total, page: pageNum, data: kycs });
    } catch (err) {
        return res.status(500).json({ success: false, message: 'Server error', error: err.message });
    }
};