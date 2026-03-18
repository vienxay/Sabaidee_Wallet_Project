import '../core/core.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'wallet_service.dart'; // ເພື່ອໃຊ້ WalletResult

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  Future<WalletResult<DecodedInvoiceModel>> decodeInvoice(
    String paymentRequest,
  ) async {
    final res = await _api.post(AppConstants.paymentDecode, {
      'paymentRequest': paymentRequest,
    });
    if (res.success && res.data != null) {
      final invoiceData =
          res.data!['invoice'] as Map<String, dynamic>? ??
          res.data!; // fallback
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
}
