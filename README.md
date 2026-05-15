# 💰 Sabaidee Wallet

ກະເປົ໋າເງິນດິຈິຕອລສຳລັບ Bitcoin Lightning Network ແລະ LAO QR Payment

---

## 📋 ສາລະບານ

- [ພາບລວມ](#ພາບລວມ)
- [Tech Stack](#tech-stack)
- [ຄຸນສົມບັດຫຼັກ](#ຄຸນສົມບັດຫຼັກ)
- [ໂຄງສ້າງໂປຣເຈັກ](#ໂຄງສ້າງໂປຣເຈັກ)
- [ຕິດຕັ້ງ Server](#ຕິດຕັ້ງ-server)
- [ຕິດຕັ້ງ Flutter App](#ຕິດຕັ້ງ-flutter-app)
- [Environment Variables](#environment-variables)
- [API Endpoints](#api-endpoints)
- [KYC Flow](#kyc-flow)
- [Payment Flow](#payment-flow)

---

## ພາບລວມ

**Sabaidee Wallet** ເປັນ mobile app ສຳລັບຈ່າຍເງິນຜ່ານ **Bitcoin Lightning Network** (sats ຈິງ) ແລະ **LAO QR** (demo). ມີລະບົບ KYC ສຳລັບຢືນຢັນຕົວຕົນ ແລະ ລະບົບ daily limit ທີ່ຄວບຄຸມວົງເງິນຕາມ KYC status.

```
ຜູ້ໃຊ້ → Flutter App → Node.js API → LNBits → Lightning Network
                                    ↓
                                 MongoDB
```

---

## Tech Stack

### Frontend (Mobile)
| ເທັກໂນໂລຊີ | ລາຍລະອຽດ |
|---|---|
| Flutter 3.x | UI Framework (iOS & Android) |
| Dart 3.9+ | Programming Language |
| FlutterSecureStorage | ເກັບ JWT token (encrypted) |
| SharedPreferences | ເກັບ user data |
| mobile_scanner | Scan QR Code |
| qr_flutter | ສ້າງ QR Code |
| http | HTTP client |

### Backend (Server)
| ເທັກໂນໂລຊີ | ລາຍລະອຽດ |
|---|---|
| Node.js + Express 5 | Web Framework |
| MongoDB + Mongoose | Database |
| LNBits API | Lightning Network wallet |
| Cloudinary | ເກັບຮູບ profile/KYC |
| JWT (jsonwebtoken) | Authentication |
| bcryptjs | Hash passwords |
| Nodemailer | ສົ່ງ Email OTP |
| Passport.js | Google OAuth 2.0 |
| Multer | File upload |
| Helmet + CORS | Security middleware |
| express-rate-limit | Rate limiting |

---

## ຄຸນສົມບັດຫຼັກ

### 🔐 Authentication
- Register / Login ດ້ວຍ Email + Password
- Google OAuth 2.0
- JWT Session (auto-logout ຫຼັງ 5 ນາທີ ບໍ່ໃຊ້ງານ)
- Forgot Password ດ້ວຍ OTP Email

### ⚡ Lightning Payments (ເງິນຈິງ)
- ຈ່າຍ BOLT11 Invoice
- ຈ່າຍ LNURL
- ຈ່າຍ Lightning Address (`user@domain.com`)
- Scan QR ຈ່າຍທັນທີ
- Top-up ດ້ວຍ Lightning Invoice

### 🇱🇦 LAO QR Payment (Demo)
- Scan ແລະ ຈ່າຍ LAO QR standard (000201...)
- ຈຳກັດ 2,000,000 ກີບ/ມື້ (ກ່ອນ KYC)
- ບັນທຶກ transaction ໃນ history

### 🪪 KYC Verification
- ສົ່ງ Passport + Selfie
- ທີມ Admin/Staff review ແລ້ວ approve/reject
- Email notification ຕອນ approve/reject
- KYC ຜ່ານ → ວົງເງິນສູງຂຶ້ນ

### 👤 Profile
- ອັບເດດ ຊື່, ເບີໂທ, ວັນເດືອນປີເກີດ
- Upload avatar (Cloudinary)

### 🛡️ Admin Dashboard
- ລາຍຊື່ Users + balance
- Review KYC requests
- ອັບເດດ BTC/LAK exchange rate
- ລາຍງານ profit/expense

---

## ໂຄງສ້າງໂປຣເຈັກ

```
Sabaidee_Wallet/
├── sabaidee_wallet/          # Flutter App
│   └── lib/
│       ├── core/             # Constants, Colors, WalletResult
│       ├── models/           # Data models (User, Wallet, Transaction...)
│       ├── services/         # API calls, Auth, Payment, Storage...
│       ├── features/         # Screens ແຍກຕາມ feature
│       │   ├── auth/         # Login, Register, Forgot password
│       │   ├── home/         # Home screen + widgets
│       │   ├── payment/      # Lightning payment, Transfer
│       │   ├── scanner/      # QR Scanner, LAO QR
│       │   ├── kyc/          # KYC submission
│       │   ├── history/      # Transaction history
│       │   ├── withdraw/     # Withdraw screen
│       │   ├── profile/      # Profile screen
│       │   └── admin/        # Admin dashboard
│       └── widgets/          # Shared widgets
│
└── server/                   # Node.js Backend
    └── src/
        ├── config/           # DB, Passport, Cloudinary
        ├── controllers/      # Business logic
        ├── middleware/       # Auth, Validation
        ├── models/           # Mongoose schemas
        ├── routes/           # Express routes
        ├── services/         # LNBits, Email, Exchange rate
        └── utils/            # Lightning utilities
```

---

## ຕິດຕັ້ງ Server

### Prerequisites
- Node.js >= 18
- MongoDB (local ຫຼື Atlas)
- LNBits instance
- Cloudinary account

### 1. Clone & Install

```bash
git clone https://github.com/vienxay/Sabaidee_Wallet_Project.git
cd Sabaidee_Wallet_Project/server
npm install
```

### 2. ຕັ້ງ Environment Variables

```bash
cp .env.example .env
# ແກ້ໄຂ .env ຕາມຕົວຢ່າງລຸ່ມ
```

### 3. ສ້າງ Admin Account (ຄັ້ງດຽວ)

```bash
npm run seed:admin
```

### 4. Start Server

```bash
# Development
npm run dev

# Production
npm start
```

Server ຈະ start ທີ່ `http://localhost:3000`

---

## ຕິດຕັ້ງ Flutter App

### Prerequisites
- Flutter SDK >= 3.9.2
- Android Studio ຫຼື Xcode
- Android/iOS device ຫຼື emulator

### 1. Install Dependencies

```bash
cd sabaidee_wallet
flutter pub get
```

### 2. ຕັ້ງ API URL

ແກ້ `lib/core/app_constants.dart`:

```dart
// Development (ngrok)
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://your-ngrok-url.ngrok-free.dev',
);
```

ຫຼື ສ່ົງ environment ຕອນ build:

```bash
flutter run --dart-define=API_BASE_URL=https://your-server.com
```

### 3. Run App

```bash
# Android
flutter run

# iOS
flutter run --device-id <ios-device-id>
```

---

## Environment Variables

ສ້າງໄຟລ໌ `server/.env`:

```env
# Server
PORT=3000
NODE_ENV=development

# MongoDB
MONGO_URI=mongodb://localhost:27017/sabaidee_wallet

# JWT
JWT_SECRET=your_super_secret_key_here
JWT_EXPIRES_IN=7d

# LNBits
LNBITS_URL=https://your-lnbits-instance.com
LNBITS_ADMIN_KEY=your_lnbits_admin_key
LNBITS_USER_ID=your_lnbits_user_id

# Cloudinary (ສຳລັບ KYC ແລະ Profile images)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Email (Nodemailer)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_CALLBACK_URL=https://your-domain.com/api/auth/google/callback

# Frontend URL (ສຳລັບ deep link redirect ຫຼັງ Google OAuth)
FRONTEND_URL=sabaidee://
```

---

## API Endpoints

### Auth
| Method | Endpoint | ລາຍລະອຽດ |
|--------|----------|----------|
| POST | `/api/auth/register` | ສ້າງ account + wallet |
| POST | `/api/auth/login` | Login |
| GET | `/api/auth/me` | ດຶງ user info |
| POST | `/api/auth/logout` | Logout |
| POST | `/api/auth/forgot-password` | ຂໍ OTP reset password |
| POST | `/api/auth/verify-otp` | ກວດ OTP |
| POST | `/api/auth/reset-password` | Reset password |

### Wallet
| Method | Endpoint | ລາຍລະອຽດ |
|--------|----------|----------|
| GET | `/api/wallet/balance` | ດຶງ balance (sats + LAK) |
| GET | `/api/wallet/rate` | BTC/LAK rate |
| POST | `/api/wallet/topup` | ສ້າງ invoice top-up |
| GET | `/api/wallet/topup/:hash/status` | ກວດ payment status |

### Payment
| Method | Endpoint | ລາຍລະອຽດ |
|--------|----------|----------|
| POST | `/api/payment/decode` | Decode Lightning invoice |
| POST | `/api/payment/pay` | ຈ່າຍ Lightning (BOLT11/LNURL/Address) |
| POST | `/api/payment/laoqr/pay` | ຈ່າຍ LAO QR (demo) |
| GET | `/api/payment/laoqr/limit-status` | ວົງເງິນ LAO QR ລາຍວັນ |

### Withdrawal
| Method | Endpoint | ລາຍລະອຽດ |
|--------|----------|----------|
| GET | `/api/withdrawal/limit-status` | ວົງເງິນຖອນ |
| POST | `/api/withdrawal/preview` | Preview ກ່ອນຖອນ |
| POST | `/api/withdrawal/send` | ຖອນຈິງ |

### KYC
| Method | Endpoint | ລາຍລະອຽດ |
|--------|----------|----------|
| GET | `/api/kyc` | ດຶງ KYC status |
| POST | `/api/kyc/submit` | ສົ່ງ KYC documents |

### Transactions
| Method | Endpoint | ລາຍລະອຽດ |
|--------|----------|----------|
| GET | `/api/transactions` | ປະຫວັດ (paginated) |
| GET | `/api/transactions/summary` | ສະຫຼຸບເດືອນນີ້ |

---

## KYC Flow

```
User ສ້າງ Account
        │
ຈ່າຍ ≤ 2,000,000 ກີບ/ມື້ (ໂດຍບໍ່ KYC)
        │
ຖ້າຕ້ອງການຈ່າຍຫຼາຍກວ່ານີ້ → ສົ່ງ KYC
        │
        ├── ອັບໂຫລດ Passport + Selfie
        ├── Admin/Staff Review (1-3 ວັນ)
        │
        ├── Approved → Email ແຈ້ງ + ວົງເງິນສູງຂຶ້ນ
        └── Rejected → Email ແຈ້ງ + re-submit ໄດ້
```

---

## Payment Flow

### ⚡ Lightning Payment (ເງິນຈິງ)
```
Scan QR / ໃສ່ Invoice
        ↓
Decode → ສະແດງ amount + description
        ↓
Confirm → Server → LNBits → Lightning Network
        ↓
Transaction ບັນທຶກ + Balance sync
```

### 🇱🇦 LAO QR Payment (Demo)
```
Scan QR → parse merchant info
        ↓
ໃສ່ amount (LAK)
        ↓
ກວດ daily limit (server-side)
        ↓
Server ບັນທຶກ demo transaction
        ↓
ສະແດງ success (ບໍ່ call LAPNET API ຕົວຈິງ)
```

> **ໝາຍເຫດ**: LAO QR ປັດຈຸບັນເປັນ demo — ຍັງບໍ່ໄດ້ເຊື່ອມຕໍ່ LAPNET API ຕົວຈິງ

---

## ຄວາມປອດໄພ

- JWT token ເກັບໃນ **FlutterSecureStorage** (Android Keystore / iOS Keychain)
- Session auto-logout ຫຼັງ **5 ນາທີ** ບໍ່ໃຊ້ງານ
- App background > 5 ນາທີ → **logout ທັນທີ**
- Rate limiting ທຸກ endpoint
- Helmet.js security headers
- bcrypt password hashing (salt rounds: 10)
- KYC documents ເກັບໃນ Cloudinary (ບໍ່ຢູ່ server)

---

## ຜູ້ພັດທະນາ

**Vienxay** — [@vienxay](https://github.com/vienxay)

---

*Built with ❤️ for Lao digital payments*
