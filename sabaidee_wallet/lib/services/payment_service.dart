import '../core/core.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'wallet_service.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  // ════════════════════════════════════════════════════════════════════════
  // ⚡ Lightning
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

  // ✅ ເພີ່ມ: LNURL Payment
  Future<WalletResult<Map<String, dynamic>>> payLNURL({
    required String lnurl,
    required int amountSats,
    String memo = '',
  }) async {
    final res = await _api.post(AppConstants.paymentPayLNURL, {
      'lnurl': lnurl,
      'amountSats': amountSats,
      if (memo.isNotEmpty) 'memo': memo,
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
  // 🇱🇦 LAO QR
  // ════════════════════════════════════════════════════════════════════════

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

  Future<WalletResult<LaoQRLimitModel>> getLaoQRLimitStatus() async {
    final res = await _api.get(AppConstants.paymentLaoQRLimit);
    if (res.success && res.data != null) {
      return WalletResult.success(LaoQRLimitModel.fromJson(res.data!));
    }
    return WalletResult.failure(res.message);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔄 Internal Transfer
  // ════════════════════════════════════════════════════════════════════════

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

  Future<WalletResult<Map<String, dynamic>>> transfer({
    required String receiverIdentifier,
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
