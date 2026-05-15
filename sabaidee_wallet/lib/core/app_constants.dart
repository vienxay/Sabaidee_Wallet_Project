/// ຄ່າຄົງທີ່ທັງໝົດຂອງ App — URL, Endpoints, Keys, Timeout
/// ແກ້ໄຂທີ່ນີ້ຈຸດດຽວ ທຸກສ່ວນຂອງ App ຈະໄດ້ຮັບຄ່າໃໝ່ທັນທີ
class AppConstants {
  AppConstants._();

  // ─── Base URL ──────────────────────────────────────────────────────────────
  // ດຶງຈາກ environment variable API_BASE_URL ຕອນ build
  // ຖ້າບໍ່ຕັ້ງ → ໃຊ້ ngrok URL ສຳລັບ development
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://unpluralized-membranophonic-saniya.ngrok-free.dev',
  );

  // ─── Auth Endpoints ────────────────────────────────────────────────────────
  static const String authRegister      = '/api/auth/register';
  static const String authLogin         = '/api/auth/login';
  static const String authMe            = '/api/auth/me';         // ດຶງຂໍ້ມູນ user ຕົນເອງ
  static const String authLogout        = '/api/auth/logout';
  static const String authForgotPass    = '/api/auth/forgot-password';
  static const String authVerifyOtp     = '/api/auth/verify-otp';
  static const String authResetPass     = '/api/auth/reset-password';
  static const String authGoogle        = '/api/auth/google';
  static const String baseUrl           = apiBaseUrl;
  static const String authProfileImage  = '/api/auth/profile/image';

  // ─── Profile Endpoints ────────────────────────────────────────────────────
  static const String profileMe     = '/api/profile/me';
  static const String profileAvatar = '/api/profile/avatar';

  // ─── Wallet Endpoints ────────────────────────────────────────────────────
  static const String wallet        = '/api/wallet';
  static const String walletBalance = '/api/wallet/balance';
  static const String walletRate    = '/api/wallet/rate';         // ດຶງ BTC/LAK rate ປັດຈຸບັນ
  static const String walletTopup   = '/api/wallet/topup';        // ສ້າງ invoice ສຳລັບ top-up
  static const String walletWithdraw = '/api/wallet/withdraw';

  // ─── Payment Endpoints ───────────────────────────────────────────────────
  static const String paymentPay            = '/api/payment/pay';           // ຈ່າຍ Lightning invoice
  static const String paymentDecode         = '/api/payment/decode';        // ຖອດລະຫັດ invoice ກ່ອນຈ່າຍ
  static const paymentLaoQR                 = '/api/payment/laoqr/pay';     // ຈ່າຍ LAO QR (demo)
  static const paymentLaoQRLimit            = '/api/payment/laoqr/limit-status'; // ວົງເງິນ LAO QR
  static const paymentTransfer              = '/api/payment/transfer';      // ໂອນລະຫວ່າງ wallet (ຍັງ implement ບໍ່ຄົບ)
  static const paymentTransferLookup        = '/api/payment/transfer/lookup';
  static const String paymentPayLNURL       = '/api/payment/pay-lnurl';     // ຈ່າຍ LNURL

  // ─── Transaction Endpoints ──────────────────────────────────────────────
  static const String transactions       = '/api/transactions';
  static const String transactionSummary = '/api/transactions/summary';

  // ─── KYC Endpoints ──────────────────────────────────────────────────────
  static const String kycStatus = '/api/kyc';         // GET  ດຶງ status ຂອງ user
  static const String kycSubmit = '/api/kyc/submit';  // POST ສົ່ງຂໍ້ມູນ KYC
  static const String kycList   = '/api/kyc/list';    // GET  admin list ທຸກ KYC
  static const String kycVerify = '/api/kyc/verify';  // PUT  admin review (ຕ້ອງຕໍ່ທ້າຍດ້ວຍ /:userId)

  // ─── HTTP Timeout ────────────────────────────────────────────────────────
  // ໃຊ້ Duration ໂດຍກົງ — single source of truth ສຳລັບ api_client.dart
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration uploadTimeout  = Duration(seconds: 60);  // ສຳລັບ upload ຮູບ

  // ─── Local Storage Keys ──────────────────────────────────────────────────
  // ໃຊ້ key ດຽວກັນທຸກຈຸດ ເພື່ອກັນ typo
  static const String tokenKey = 'auth_token';
  static const String userKey  = 'user_data';

  // ─── App Config ──────────────────────────────────────────────────────────
  static const String appScheme = 'sabaidee'; // deep link scheme: sabaidee://home

  // ─── Withdrawal Endpoints ────────────────────────────────────────────────
  static const String withdrawalLimitStatus = '/api/withdrawal/limit-status';
  static const String withdrawalPreview     = '/api/withdrawal/preview';  // ກວດ limit ກ່ອນຖອນ
  static const String withdrawalSend        = '/api/withdrawal/send';     // ຖອນຈິງ

  // ─── Admin Endpoints ────────────────────────────────────────────────────
  static const adminKyc        = '/api/admin/kyc';
  static const adminKycReview  = '/api/admin/kyc/review';
  static const adminUsers      = '/api/admin/users';
  static const adminUpdateRole = '/api/admin/users/role';
  static const adminRate       = '/api/admin/rate';
  static const adminUpdateRate = '/api/admin/rate/update';
}
