/// ──────────────────────────────────────────────
/// API Endpoints ແລະ Config ທັງໝົດ
/// ──────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  // ─── Base URL ───────────────────────────────────────────────────────────────
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://unpluralized-membranophonic-saniya.ngrok-free.dev',
  );

  // ─── Auth ────────────────────────────────────────────────────────────────────
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authMe = '/api/auth/me';
  static const String authLogout = '/api/auth/logout';
  static const String authForgotPass = '/api/auth/forgot-password';
  static const String authVerifyOtp = '/api/auth/verify-otp';
  static const String authResetPass = '/api/auth/reset-password';
  static const String authGoogle = '/api/auth/google';
  static const String baseUrl = apiBaseUrl;
  static const String authProfileImage = '/api/auth/profile/image';

  // ─── Profile ─────────────────────────────────────────────────────────────────
  static const String profileMe = '/api/profile/me';
  static const String profileAvatar = '/api/profile/avatar';

  // ─── Wallet ──────────────────────────────────────────────────────────────────
  static const String wallet = '/api/wallet';
  static const String walletBalance = '/api/wallet/balance';
  static const String walletRate = '/api/wallet/rate';
  static const String walletTopup = '/api/wallet/topup';
  static const String walletWithdraw = '/api/wallet/withdraw';

  // ─── Payment ─────────────────────────────────────────────────────────────────
  static const String paymentPay = '/api/payment/pay';
  static const String paymentDecode = '/api/payment/decode';
  static const paymentLaoQR = '/api/payment/laoqr/pay';
  static const paymentLaoQRLimit = '/api/payment/laoqr/limit-status';
  static const paymentTransfer = '/api/payment/transfer';
  static const paymentTransferLookup = '/api/payment/transfer/lookup';
  static const String paymentPayLNURL = '/api/payment/pay-lnurl';

  // ─── Transactions ─────────────────────────────────────────────────────────────
  static const String transactions = '/api/transactions';
  static const String transactionSummary = '/api/transactions/summary';

  // ─── KYC ─────────────────────────────────────────────────────────────────────
  static const String kycStatus = '/api/kyc'; // GET  — ດຶງ status + kyc object
  static const String kycSubmit =
      '/api/kyc/submit'; // POST — submit / re-submit
  static const String kycList = '/api/kyc/list'; // ✅ GET  — admin list
  static const String kycVerify =
      '/api/kyc/verify'; // ✅ PUT  — admin review (:userId)

  // ─── HTTP Config ──────────────────────────────────────────────────────────────
  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 15000;

  // ─── Local Storage Keys ────────────────────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // ─── App Config ────────────────────────────────────────────────────────────────
  static const String appScheme = 'sabaidee';

  // ─── Withdrawal ───────────────────────────────────────────────────────────────
  static const String withdrawalLimitStatus = '/api/withdrawal/limit-status';
  static const String withdrawalPreview = '/api/withdrawal/preview';
  static const String withdrawalSend = '/api/withdrawal/send';

  // ─── Admin ────────────────────────────────────────────────────────────────────
  static const adminKyc = '/api/admin/kyc';
  static const adminKycReview = '/api/admin/kyc/review';
  static const adminUsers = '/api/admin/users';
  static const adminUpdateRole = '/api/admin/users/role';
  static const adminRate = '/api/admin/rate';
  static const adminUpdateRate = '/api/admin/rate/update';
}
