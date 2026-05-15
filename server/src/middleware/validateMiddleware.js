// Input Validation Middleware — ກວດ request body ກ່ອນ controller
// ໃຊ້ express-validator library
// ─── middleware/validateMiddleware.js ────────────────────────────────────────
const { body, validationResult } = require('express-validator');

// ── Helper: ດຶງ error ທຳອິດ ແລ້ວ return 400 ───────────────────────────────────
// ວາງໄວ້ທ້າຍ array validators ສະເໝີ: [...validators, validate]
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: errors.array()[0].msg,
            errors:  errors.array(),
        });
    }
    next();
};

// ════════════════════════════════════════════════════════════════════════════
// Lightning — decode invoice
// POST /api/payment/decode
// ════════════════════════════════════════════════════════════════════════════
exports.validateDecodeInvoice = [
    body('paymentRequest')
        .notEmpty().withMessage('ກະລຸນາໃສ່ Lightning Invoice')
        .isString().withMessage('paymentRequest ຕ້ອງເປັນ string'),
    validate,
];

// ════════════════════════════════════════════════════════════════════════════
// Lightning — pay invoice
// POST /api/payment/pay
// ════════════════════════════════════════════════════════════════════════════
exports.validatePayInvoice = [
    body('paymentRequest')
        .notEmpty().withMessage('ກະລຸນາໃສ່ Lightning Invoice')
        .isString().withMessage('paymentRequest ຕ້ອງເປັນ string'),
    body('amount')
        .optional()
        .isInt({ min: 1 }).withMessage('amount ຕ້ອງເປັນຕົວເລກທີ່ຫຼາຍກວ່າ 0'),
    body('memo')
        .optional()
        .isString()
        .isLength({ max: 200 }).withMessage('memo ຍາວບໍ່ເກີນ 200 ຕົວອັກສອນ'),
    validate,
];

// ════════════════════════════════════════════════════════════════════════════
// LAO QR — pay
// POST /api/payment/laoqr/pay
// ════════════════════════════════════════════════════════════════════════════
exports.validateLaoQRPay = [
    body('amountLAK')
        .notEmpty().withMessage('ກະລຸນາໃສ່ຈຳນວນເງິນ')
        .isInt({ min: 1_000, max: 2_000_000 }).withMessage('ຈຳນວນເງິນຕ້ອງຢູ່ລະຫວ່າງ 1,000 – 2,000,000 ກີບ'),

    body('merchantName')
        .optional()
        .isString()
        .isLength({ max: 100 }).withMessage('merchantName ຍາວບໍ່ເກີນ 100 ຕົວອັກສອນ'),

    body('bank')
        .optional()
        .isString()
        .isLength({ max: 50 }).withMessage('bank ຍາວບໍ່ເກີນ 50 ຕົວອັກສອນ'),

    body('qrRaw')
        .optional()
        .isString()
        .isLength({ max: 1_000 }).withMessage('qrRaw ຍາວບໍ່ເກີນ 1,000 ຕົວອັກສອນ'),

    body('description')
        .optional()
        .isString()
        .isLength({ max: 200 }).withMessage('description ຍາວບໍ່ເກີນ 200 ຕົວອັກສອນ'),

    validate,
];