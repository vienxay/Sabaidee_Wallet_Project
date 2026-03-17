import '../core/core.dart';
import '../models/app_models.dart';
import 'api_client.dart';

class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  final _api = ApiClient.instance;

  Future<WalletResult<WalletModel>> getWallet() async {
    final res = await _api.get(AppConstants.wallet);
    if (res.success && res.data?['wallet'] != null) {
      return WalletResult.success(WalletModel.fromJson(res.data!['wallet']));
    }
    return WalletResult.failure(res.message);
  }

  Future<WalletResult<Map<String, dynamic>>> getBalance() async {
    final res = await _api.get(AppConstants.walletBalance);
    if (res.success && res.data?['balance'] != null) {
      return WalletResult.success(res.data!['balance'] as Map<String, dynamic>);
    }
    return WalletResult.failure(res.message);
  }

  Future<WalletResult<RateModel>> getRate() async {
    final res = await _api.get(AppConstants.walletRate);
    if (res.success && res.data?['rate'] != null) {
      return WalletResult.success(RateModel.fromJson(res.data!['rate']));
    }
    return WalletResult.failure(res.message);
  }

  Future<WalletResult<Map<String, dynamic>>> createTopUpInvoice({
    required int amountSats,
    String memo = '',
  }) async {
    final res = await _api.post(AppConstants.walletTopup, {
      'amountSats': amountSats,
      if (memo.isNotEmpty) 'memo': memo,
    });
    if (res.success && res.data?['topup'] != null) {
      return WalletResult.success(res.data!['topup'] as Map<String, dynamic>);
    }
    return WalletResult.failure(res.message);
  }

  Future<WalletResult<Map<String, dynamic>>> withdraw({
    required String paymentRequest,
    String memo = '',
  }) async {
    final res = await _api.post(AppConstants.walletWithdraw, {
      'paymentRequest': paymentRequest,
      if (memo.isNotEmpty) 'memo': memo,
    });
    if (res.success && res.data?['withdraw'] != null) {
      return WalletResult.success(
        res.data!['withdraw'] as Map<String, dynamic>,
      );
    }
    return WalletResult.failure(res.message);
  }

  // ─── ກວດສະຖານະ Invoice ວ່າຈ່າຍແລ້ວບໍ່ ──────────────────────────────────
  Future<WalletResult<Map<String, dynamic>>> checkPaymentStatus({
    required String paymentHash,
  }) async {
    final res = await _api.get(
      '${AppConstants.walletTopup}/$paymentHash/status',
    );
    if (res.success && res.data != null) {
      return WalletResult.success(res.data!);
    }
    return WalletResult.failure(res.message);
  }
}

// Result Wrapper ໄວ້ໃຊ້ຮ່ວມກັນທຸກ Service
class WalletResult<T> {
  final bool success;
  final T? data;
  final String message;
  final bool requireKYC;

  const WalletResult._({
    required this.success,
    this.data,
    this.message = '',
    this.requireKYC = false,
  });

  factory WalletResult.success(T data) =>
      WalletResult._(success: true, data: data);
  factory WalletResult.failure(String msg, {bool requireKYC = false}) =>
      WalletResult._(success: false, message: msg, requireKYC: requireKYC);
}
