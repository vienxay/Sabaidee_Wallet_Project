// ─── lib/services/withdrawal_service.dart ────────────────────────────────────
import '../core/core.dart';
import 'api_client.dart';
import '../core/wallet_result.dart';

class WithdrawalService {
  WithdrawalService._();
  static final WithdrawalService instance = WithdrawalService._();

  final _api = ApiClient.instance;

  // ── GET /api/withdrawal/limit-status ──────────────────────────────────────
  Future<WalletResult<WithdrawalLimitModel>> getLimitStatus() async {
    final res = await _api.get(AppConstants.withdrawalLimitStatus);
    if (res.success && res.data != null) {
      return WalletResult.success(WithdrawalLimitModel.fromJson(res.data!));
    }
    return WalletResult.failure(res.message);
  }

  // ── POST /api/withdrawal/preview ──────────────────────────────────────────
  Future<WalletResult<WithdrawalPreviewModel>> preview({
    required String destination,
    required int amountLAK,
  }) async {
    final res = await _api.post(AppConstants.withdrawalPreview, {
      'destination': destination,
      'amountLAK': amountLAK,
    });

    if (res.success && res.data != null) {
      return WalletResult.success(WithdrawalPreviewModel.fromJson(res.data!));
    }
    if (res.data?['requireKYC'] == true) {
      return WalletResult.failure(res.message, requireKYC: true);
    }
    return WalletResult.failure(res.message);
  }

  // ── POST /api/withdrawal/send ─────────────────────────────────────────────
  Future<WalletResult<Map<String, dynamic>>> send({
    required String destination,
    required int amountLAK,
    String memo = 'Withdraw',
  }) async {
    final res = await _api.post(AppConstants.withdrawalSend, {
      'destination': destination,
      'amountLAK': amountLAK,
      'memo': memo,
    });

    if (res.success) {
      return WalletResult.success(res.data ?? {});
    }
    if (res.data?['requireKYC'] == true) {
      return WalletResult.failure(res.message, requireKYC: true);
    }
    return WalletResult.failure(res.message);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Models
// ════════════════════════════════════════════════════════════════════════════

class WithdrawalLimitModel {
  final bool isKYCVerified;
  final int balanceSats;
  final int perTxLimit;
  final int dailyLimit;
  final int todayWithdrawn;
  final int remaining;
  final int percentage;

  const WithdrawalLimitModel({
    required this.isKYCVerified,
    required this.balanceSats,
    required this.perTxLimit,
    required this.dailyLimit,
    required this.todayWithdrawn,
    required this.remaining,
    required this.percentage,
  });

  factory WithdrawalLimitModel.fromJson(Map<String, dynamic> j) =>
      WithdrawalLimitModel(
        isKYCVerified: j['isKYCVerified'] ?? false,
        balanceSats: j['balanceSats'] ?? 0,
        perTxLimit: j['perTxLimit'] ?? 500000,
        dailyLimit: j['dailyLimit'] ?? 1000000,
        todayWithdrawn: j['todayWithdrawn'] ?? 0,
        remaining: j['remaining'] ?? 0,
        percentage: j['percentage'] ?? 0,
      );
}

class WithdrawalPreviewModel {
  final String destinationType; // 'address' | 'invoice'
  final String destination;
  final int amountLAK;
  final int amountSats;
  final int estimatedFeeSats;
  final int balanceSats;
  final double btcToLAK;
  final int perTxLimit;
  final int dailyLimit;
  final int todayWithdrawn;
  final int remaining;

  const WithdrawalPreviewModel({
    required this.destinationType,
    required this.destination,
    required this.amountLAK,
    required this.amountSats,
    required this.estimatedFeeSats,
    required this.balanceSats,
    required this.btcToLAK,
    required this.perTxLimit,
    required this.dailyLimit,
    required this.todayWithdrawn,
    required this.remaining,
  });

  factory WithdrawalPreviewModel.fromJson(Map<String, dynamic> j) {
    final limits = j['limits'] as Map<String, dynamic>? ?? {};
    final rate = j['rate'] as Map<String, dynamic>? ?? {};
    return WithdrawalPreviewModel(
      destinationType: j['destinationType'] ?? 'address',
      destination: j['destination'] ?? '',
      amountLAK: j['amountLAK'] ?? 0,
      amountSats: j['amountSats'] ?? 0,
      estimatedFeeSats: j['estimatedFeeSats'] ?? 0,
      balanceSats: j['balanceSats'] ?? 0,
      btcToLAK: (rate['btcToLAK'] ?? 0).toDouble(),
      perTxLimit: limits['perTx'] ?? 500000,
      dailyLimit: limits['daily'] ?? 1000000,
      todayWithdrawn: limits['todayWithdrawn'] ?? 0,
      remaining: limits['remaining'] ?? 0,
    );
  }
}
