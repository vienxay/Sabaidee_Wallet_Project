const KYC = require('../models/KYC');
const User = require('../models/User');

// ─── GET /api/kyc ─────────────────────────────────────────────────────────────
// ດຶງ KYC status ຂອງ user

exports.getKYCStatus = async (req, res) => {
    try {
        const kyc = await KYC.findOne({ user: req.user._id });

        if (!kyc) {
            return res.status(200).json({
                success: true,
                kyc: { status: 'pending', message: 'ຍັງບໍ່ໄດ້ຍື່ນ KYC' },
            });
        }

        res.status(200).json({
            success: true,
            kyc: {
                status:       kyc.status,
                fullName:     kyc.fullName,
                idType:       kyc.idType,
                submittedAt:  kyc.submittedAt,
                verifiedAt:   kyc.verifiedAt,
                rejectedReason: kyc.rejectedReason,
                limit: {
                    dailyLimitSats:   kyc.dailyLimitSats,
                    monthlyLimitSats: kyc.monthlyLimitSats,
                },
            },
        });
    } catch (error) {
        console.error('Get KYC Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── POST /api/kyc/submit ─────────────────────────────────────────────────────
// ຍື່ນ KYC ໃໝ່

exports.submitKYC = async (req, res) => {
    try {
        const { fullName, idNumber, idType, dateOfBirth, phone, address } = req.body;

        if (!fullName || !idNumber || !dateOfBirth || !phone) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາປ້ອນຂໍ້ມູນໃຫ້ຄົບ' });
        }

        // ກວດ KYC ທີ່ verified ແລ້ວ
        const existingKYC = await KYC.findOne({ user: req.user._id });
        if (existingKYC?.status === 'verified') {
            return res.status(400).json({ success: false, message: 'KYC ຂອງທ່ານໄດ້ຮັບການຢືນຢັນແລ້ວ' });
        }

        // ກວດ idNumber ຊ້ຳ
        const duplicateID = await KYC.findOne({ idNumber, user: { $ne: req.user._id } });
        if (duplicateID) {
            return res.status(409).json({ success: false, message: 'ເລກທີ່ບັດນີ້ຖືກໃຊ້ງານແລ້ວ' });
        }

        // ດຶງ URL ຮູບທີ່ upload (ຜ່ານ middleware multer/cloudinary)
        const documents = {
            idFront: req.files?.idFront?.[0]?.path || null,
            idBack:  req.files?.idBack?.[0]?.path  || null,
            selfie:  req.files?.selfie?.[0]?.path  || null,
        };

        if (!documents.idFront || !documents.idBack || !documents.selfie) {
            return res.status(400).json({ success: false, message: 'ກະລຸນາອັບໂຫຼດຮູບໃຫ້ຄົບ (ໜ້າ, ຫຼັງ, selfie)' });
        }

        const kyc = await KYC.findOneAndUpdate(
            { user: req.user._id },
            {
                user: req.user._id,
                fullName, idNumber,
                idType:      idType || 'national_id',
                dateOfBirth: new Date(dateOfBirth),
                phone, address,
                documents,
                status:      'submitted',
                submittedAt: new Date(),
                rejectedReason: null,
            },
            { upsert: true, new: true }
        );

        // ອັບເດດ kycStatus ໃນ User ດ້ວຍ
        await User.findByIdAndUpdate(req.user._id, { kycStatus: 'pending' });

        res.status(201).json({
            success: true,
            message: 'ຍື່ນ KYC ສຳເລັດ — ກຳລັງລໍຖ້າການກວດສອບ',
            kyc: { status: kyc.status, submittedAt: kyc.submittedAt },
        });
    } catch (error) {
        console.error('Submit KYC Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};

// ─── PUT /api/kyc/verify/:userId  (Admin only) ────────────────────────────────
// Admin ຢືນຢັນ KYC

exports.verifyKYC = async (req, res) => {
    try {
        const { userId } = req.params;
        const { action, rejectedReason } = req.body; // action: 'approve' | 'reject'

        const kyc = await KYC.findOne({ user: userId });
        if (!kyc) {
            return res.status(404).json({ success: false, message: 'ບໍ່ພົບ KYC' });
        }

        if (action === 'approve') {
            kyc.status     = 'verified';
            kyc.verifiedAt = new Date();
            kyc.dailyLimitSats   = 10_000_000; // ເພີ່ມ limit ຫຼັງ verify
            kyc.monthlyLimitSats = 100_000_000;
            await User.findByIdAndUpdate(userId, { kycStatus: 'verified' });
        } else if (action === 'reject') {
            if (!rejectedReason) {
                return res.status(400).json({ success: false, message: 'ກະລຸນາລະບຸເຫດຜົນ' });
            }
            kyc.status         = 'rejected';
            kyc.rejectedReason = rejectedReason;
            await User.findByIdAndUpdate(userId, { kycStatus: 'rejected' });
        } else {
            return res.status(400).json({ success: false, message: 'action ຕ້ອງເປັນ approve ຫຼື reject' });
        }

        await kyc.save();

        res.status(200).json({
            success: true,
            message: action === 'approve' ? 'KYC ຢືນຢັນສຳເລັດ' : 'KYC ຖືກປະຕິເສດ',
            kyc: { status: kyc.status, verifiedAt: kyc.verifiedAt },
        });
    } catch (error) {
        console.error('Verify KYC Error:', error);
        return res.status(500).json({ success: false, message: 'ເກີດຂໍ້ຜິດພາດໃນລະບົບ' });
    }
};