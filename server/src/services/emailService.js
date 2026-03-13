const nodemailer = require('nodemailer');

// ✅ Sanitize HTML input
const sanitizeHtml = (str) =>
    String(str).replace(/[<>&"']/g, (c) => ({
        '<': '&lt;',
        '>': '&gt;',
        '&': '&amp;',
        '"': '&quot;',
        "'": '&#39;',
    }[c]));

// ✅ สร้าง transporter แบบ lazy (ตาม port จริง)
const createTransporter = () => {
    const port = parseInt(process.env.EMAIL_PORT) || 587;
    return nodemailer.createTransport({
        host: process.env.EMAIL_HOST || 'smtp.gmail.com',
        port,
        secure: port === 465, // ✅ true ສຳລັບ 465, false ສຳລັບ 587
        auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASS,
        },
    });
};

// ✅ Verify connection (ໃຊ້ຕອນ startup)
const verifyEmailConnection = async () => {
    try {
        const transporter = createTransporter();
        await transporter.verify();
        console.log('Email service ready');
        return true;
    } catch (error) {
        console.error('Email service error:', error.message);
        return false;
    }
};

// Send OTP Email
const sendOTPEmail = async (email, otp, name) => {
    // ✅ Validate inputs
    if (!email || !otp || !name) {
        return { success: false, error: 'Missing required parameters' };
    }

    try {
        const transporter = createTransporter();
        const safeName = sanitizeHtml(name); // ✅ XSS protection

        const mailOptions = {
            from: `"Sabaidee Wallet" <${process.env.EMAIL_USER}>`,
            to: email,
            subject: 'ລະຫັດ OTP ສຳລັບຣີເຊັດລະຫັດຜ່ານ',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #333;">ສະບາຍດີ ${safeName},</h2>
                    <p>ທ່ານໄດ້ຂໍລະຫັດ OTP ເພື່ອຣີເຊັດລະຫັດຜ່ານ</p>
                    <div style="background: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
                        <h1 style="color: #007bff; letter-spacing: 5px; margin: 0;">${otp}</h1>
                    </div>
                    <p>ລະຫັດນີ້ມີອາຍຸ <strong>10 ນາທີ</strong></p>
                    <p>ຖ້າທ່ານບໍ່ໄດ້ຂໍລະຫັດນີ້, ກະລຸນາລະວັງຕົວ!</p>
                    <hr style="margin: 30px 0;">
                    <p style="color: #666; font-size: 12px;">Sabaidee Wallet Team</p>
                </div>
            `,
        };

        await transporter.sendMail(mailOptions);
        return { success: true };
    } catch (error) {
        console.error('Send Email Error:', error.message);
        return { success: false, error: error.message };
    }
};

module.exports = { sendOTPEmail, verifyEmailConnection };