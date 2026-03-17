/// ──────────────────────────────────────────────
/// API Endpoints ແລະ Config ທັງໝົດ
/// ──────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  // ─── Base URL ───────────────────────────────────────────────────────────────
  // flutter run --dart-define=API_BASE_URL=https://api.example.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android Emulator → localhost
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
  static const String authProfile = '/api/auth/profile';
  static const String authPassword = '/api/auth/password';
  static const String baseUrl = apiBaseUrl; // ✅ alias ສຳລັບ upload
  static const String authProfileImage =
      '/api/auth/profile/image'; // ✅ route ໃໝ່

  // ─── Wallet ──────────────────────────────────────────────────────────────────
  static const String wallet = '/api/wallet';
  static const String walletBalance = '/api/wallet/balance';
  static const String walletRate = '/api/wallet/rate';
  static const String walletTopup = '/api/wallet/topup';
  static const String walletWithdraw = '/api/wallet/withdraw';

  // ─── Payment ─────────────────────────────────────────────────────────────────
  static const String paymentPay = '/api/payment/pay';
  static const String paymentDecode = '/api/payment/decode';

  // ─── Transactions ─────────────────────────────────────────────────────────────
  static const String transactions = '/api/transactions';
  static const String transactionSummary = '/api/transactions/summary';

  // ─── KYC ─────────────────────────────────────────────────────────────────────
  static const String kycStatus = '/api/kyc';
  static const String kycSubmit = '/api/kyc/submit';

  // ─── HTTP Config ──────────────────────────────────────────────────────────────
  static const int connectTimeoutMs = 10000; // 10 ວິນາທີ
  static const int receiveTimeoutMs = 15000; // 15 ວິນາທີ

  // ─── Local Storage Keys ────────────────────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // ─── App Config ────────────────────────────────────────────────────────────────
  static const String appScheme = 'sabaidee'; // deep-link: sabaidee://
}
