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

// ✅ ສ້າງ transporter ແບບ lazy
const createTransporter = () => {
    const port = parseInt(process.env.EMAIL_PORT) || 587;
    return nodemailer.createTransport({
        host: process.env.EMAIL_HOST || 'smtp.gmail.com',
        port,
        secure: port === 465,
        auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASS,
        },
    });
};

// ✅ Verify connection
const verifyEmailConnection = async () => {
    try {
        const transporter = createTransporter();
        await transporter.verify();
        console.log('✅ Email service ready');
        return true;
    } catch (error) {
        console.error('❌ Email service error:', error.message);
        return false;
    }
};

// ==================== OTP Email ====================
const sendOTPEmail = async (email, otp, name) => {
    if (!email || !otp || !name) {
        return { success: false, error: 'Missing required parameters' };
    }

    try {
        const transporter = createTransporter();
        const safeName = sanitizeHtml(name);

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
        console.error('Send OTP Error:', error.message);
        return { success: false, error: error.message };
    }
};

// ==================== KYC Emails ====================

// ✅ ສົ່ງອະນຸມັດ KYC
const sendKycApprovedEmail = async (email, name) => {
    if (!email || !name) {
        return { success: false, error: 'Missing email or name' };
    }

    try {
        const transporter = createTransporter();
        const safeName = sanitizeHtml(name);

        const mailOptions = {
            from: `"Sabaidee Wallet" <${process.env.EMAIL_USER}>`,
            to: email,
            subject: 'KYC ອະນຸມັດສຳເລັດແລ້ວ - Sabaidee Wallet',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                    <div style="text-align: center; margin-bottom: 30px;">
                        <div style="width: 80px; height: 80px; background: #4CAF50; border-radius: 50%; display: inline-block; line-height: 80px; color: white; font-size: 40px;">✓</div>
                    </div>
                    <h2 style="color: #4CAF50; text-align: center;">ສະບາຍດີ ${safeName},</h2>
                    <p style="font-size: 16px; color: #333;">ຍິນດີດ້ວຍ! KYC ຂອງທ່ານໄດ້ຮັບການອະນຸມັດແລ້ວ 🎉</p>
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <p style="margin: 0 0 10px 0;"><strong>ທ່ານສາມາດໃຊ້ງານໄດ້ເຕັມຮູບແບບ:</strong></p>
                        <ul style="margin: 0; padding-left: 20px; color: #555;">
                            <li>✅ ຝາກເງິນໄດ້ບໍ່ຈຳກັດ</li>
                            <li>✅ ຖອນເງິນໄດ້</li>
                            <li>✅ ໂອນ/ຮັບເງິນໄດ້</li>
                            <li>✅ ໃຊ້ QR Code ໄດ້</li>
                        </ul>
                    </div>
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="${process.env.API_URL}/open/home" 
                           style="background: #4CAF50; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
                            ເຂົ້າໃຊ້ Wallet
                        </a>
                    </div>
                    <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
                    <p style="color: #666; font-size: 12px; text-align: center;">
                        ອີເມລນີ້ຖືກສົ່ງອັດຕະໂນມັດ ກະລຸນາຢ່າຕອບກັບ<br>
                        Sabaidee Wallet Team
                    </p>
                </div>
            `,
        };

        await transporter.sendMail(mailOptions);
        console.log('✅ KYC approved email sent to:', email);
        return { success: true };
    } catch (error) {
        console.error('Send KYC Approved Error:', error.message);
        return { success: false, error: error.message };
    }
};

// ✅ ສົ່ງປະຕິເສດ KYC
const sendKycRejectedEmail = async (email, name, reason) => {
    if (!email || !name) {
        return { success: false, error: 'Missing email or name' };
    }

    try {
        const transporter = createTransporter();
        const safeName = sanitizeHtml(name);
        const safeReason = sanitizeHtml(reason || 'ເອກະສານບໍ່ຊັດເຈນ');

        const mailOptions = {
            from: `"Sabaidee Wallet" <${process.env.EMAIL_USER}>`,
            to: email,
            subject: 'KYC ບໍ່ຜ່ານການອະນຸມັດ - Sabaidee Wallet',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                    <div style="text-align: center; margin-bottom: 30px;">
                        <div style="width: 80px; height: 80px; background: #f44336; border-radius: 50%; display: inline-block; line-height: 80px; color: white; font-size: 40px;">✕</div>
                    </div>
                    <h2 style="color: #f44336; text-align: center;">ສະບາຍດີ ${safeName},</h2>
                    <p style="font-size: 16px; color: #333;">KYC ຂອງທ່ານບໍ່ຜ່ານການອະນຸມັດ</p>
                    <div style="background: #ffebee; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f44336;">
                        <p style="margin: 0 0 5px 0; color: #666; font-size: 14px;"><strong>ເຫດຜົນ:</strong></p>
                        <p style="margin: 0; color: #333; font-size: 16px;">${safeReason}</p>
                    </div>
                    <p style="color: #555;">ກະລຸນາກວດສອບເອກະສານ ແລະອັບໂຫລດໃໝ່ອີກຄັ້ງ:</p>
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="${process.env.API_URL}/open/kyc" 
                           style="background: #f44336; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
                            ອັບໂຫລດ KYC ໃໝ່
                        </a>
                    </div>
                    <div style="background: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0;">
                        <p style="margin: 0; color: #856404; font-size: 14px;">
                            💡 <strong>ເຄັດລັບ:</strong> ໃຫ້ແນ່ໃຈວ່າຮູບຖ່າຍຊັດເຈນ, ບໍ່ມີແສງສະທ້ອນ, ແລະຂໍ້ມູນກົງກັບເອກະສານ
                        </p>
                    </div>
                    <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
                    <p style="color: #666; font-size: 12px; text-align: center;">
                        ອີເມລນີ້ຖືກສົ່ງອັດຕະໂນມັດ ກະລຸນາຢ່າຕອບກັບ<br>
                        Sabaidee Wallet Team
                    </p>
                </div>
            `,
        };

        await transporter.sendMail(mailOptions);
        console.log('✅ KYC rejected email sent to:', email);
        return { success: true };
    } catch (error) {
        console.error('Send KYC Rejected Error:', error.message);
        return { success: false, error: error.message };
    }
};

module.exports = {
    sendOTPEmail,
    sendKycApprovedEmail,
    sendKycRejectedEmail,
    verifyEmailConnection
};