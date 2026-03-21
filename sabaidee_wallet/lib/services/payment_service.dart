import '../core/core.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'wallet_service.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  // ════════════════════════════════════════════════════════════════════════
  // ⚡ Lightning — ຄືເດີມ
  // ════════════════════════════════════════════════════════════════════════

  Future<WalletResult<DecodedInvoiceModel>> decodeInvoice(
    String paymentRequest,
  ) async {
    final res = await _api.post(AppConstants.paymentDecode, {
      'paymentRequest': paymentRequest,
    });
    if (res.success && res.data != null) {
      final invoiceData =
          res.data!['invoice'] as Map<String, dynamic>? ?? res.data!;
      return WalletResult.success(DecodedInvoiceModel.fromJson(invoiceData));
    }
    return WalletResult.failure(res.message);
  }

  Future<WalletResult<Map<String, dynamic>>> pay({
    required String paymentRequest,
    String memo = '',
    int? amountSats,
  }) async {
    final res = await _api.post(AppConstants.paymentPay, {
      'paymentRequest': paymentRequest,
      if (memo.isNotEmpty) 'memo': memo,
      if (amountSats != null) 'amount': amountSats,
    });

    if (res.success && res.data?['payment'] != null) {
      return WalletResult.success(res.data!['payment'] as Map<String, dynamic>);
    }
    if (res.data?['requireKYC'] == true) {
      return WalletResult.failure(res.message, requireKYC: true);
    }
    return WalletResult.failure(res.message);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🇱🇦 LAO QR — ໃໝ່
  // ════════════════════════════════════════════════════════════════════════

  /// ຈ່າຍ LAO QR (Demo)
  Future<WalletResult<Map<String, dynamic>>> payLaoQR({
    required int amountLAK,
    String merchantName = '',
    String bank = '',
    String qrRaw = '',
    String description = '',
  }) async {
    final res = await _api.post(AppConstants.paymentLaoQR, {
      'amountLAK': amountLAK,
      if (merchantName.isNotEmpty) 'merchantName': merchantName,
      if (bank.isNotEmpty) 'bank': bank,
      if (qrRaw.isNotEmpty) 'qrRaw': qrRaw,
      if (description.isNotEmpty) 'description': description,
    });

    if (res.success) {
      return WalletResult.success(res.data ?? {});
    }
    if (res.data?['requireKYC'] == true) {
      return WalletResult.failure(res.message, requireKYC: true);
    }
    return WalletResult.failure(res.message);
  }

  /// ດຶງຍອດ LAO QR ວັນນີ້
  Future<WalletResult<LaoQRLimitModel>> getLaoQRLimitStatus() async {
    final res = await _api.get(AppConstants.paymentLaoQRLimit);
    if (res.success && res.data != null) {
      return WalletResult.success(LaoQRLimitModel.fromJson(res.data!));
    }
    return WalletResult.failure(res.message);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔄 Internal Transfer — ໃໝ່
  // ════════════════════════════════════════════════════════════════════════

  /// ຄົ້ນຫາຜູ້ຮັບ (preview ກ່ອນໂອນ)
  Future<WalletResult<ReceiverInfoModel>> lookupReceiver(String q) async {
    final res = await _api.get(
      '${AppConstants.paymentTransferLookup}?q=${Uri.encodeComponent(q)}',
    );
    if (res.success && res.data?['receiver'] != null) {
      return WalletResult.success(
        ReceiverInfoModel.fromJson(res.data!['receiver']),
      );
    }
    return WalletResult.failure(res.message);
  }

  /// ໂອນເງິນລະຫວ່າງ Sabaidee Wallet users
  Future<WalletResult<Map<String, dynamic>>> transfer({
    required String receiverIdentifier, // email ຫຼື phone
    required int amountLAK,
    String memo = '',
  }) async {
    final res = await _api.post(AppConstants.paymentTransfer, {
      'receiverIdentifier': receiverIdentifier,
      'amountLAK': amountLAK,
      if (memo.isNotEmpty) 'memo': memo,
    });

    if (res.success) {
      return WalletResult.success(res.data?['transfer'] ?? {});
    }
    if (res.data?['requireKYC'] == true) {
      return WalletResult.failure(res.message, requireKYC: true);
    }
    return WalletResult.failure(res.message);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ✅ Models ໃໝ່ (ເພີ່ມໃສ່ app_models.dart ຖ້າຕ້ອງການ)
// ════════════════════════════════════════════════════════════════════════════

/// LAO QR daily limit info
class LaoQRLimitModel {
  final bool isKYCVerified;
  final int dailyLimit;
  final int todaySpent;
  final int remaining;
  final int percentage;

  const LaoQRLimitModel({
    required this.isKYCVerified,
    required this.dailyLimit,
    required this.todaySpent,
    required this.remaining,
    required this.percentage,
  });

  factory LaoQRLimitModel.fromJson(Map<String, dynamic> j) => LaoQRLimitModel(
    isKYCVerified: j['isKYCVerified'] ?? false,
    dailyLimit: j['dailyLimit'] ?? 2000000,
    todaySpent: j['todaySpent'] ?? 0,
    remaining: j['remaining'] ?? 2000000,
    percentage: j['percentage'] ?? 0,
  );
}

/// Receiver preview info
class ReceiverInfoModel {
  final String name;
  final String account;
  final String? profileImage;

  const ReceiverInfoModel({
    required this.name,
    required this.account,
    this.profileImage,
  });

  factory ReceiverInfoModel.fromJson(Map<String, dynamic> j) =>
      ReceiverInfoModel(
        name: j['name'] ?? '',
        account: j['account'] ?? '',
        profileImage: j['profileImage'],
      );
}
