// ຈັດການ Payment ທຸກປະເພດ:
//   ⚡ Lightning (BOLT11, LNURL, Lightning Address) — ເງິນຈິງ sats
//   🇱🇦 LAO QR — demo money (ຍັງບໍ່ເຊື່ອມ LAPNET)
//   🔄 Internal Transfer — demo (server ຍັງ implement ບໍ່ຄົບ)
import '../core/core.dart';
import '../models/app_models.dart';
import 'api_client.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  // ─── Lightning ─────────────────────────────────────────────────────────────

  // ຖອດລະຫັດ invoice ກ່ອນຈ່າຍ — ດຶງ amount, description, expiry
  // ຮອງຮັບ: BOLT11, LNURL, Lightning Address
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

  // ຈ່າຍ Lightning invoice — server ສົ່ງ sats ຜ່ານ LNBits
  // requireKYC = true ຖ້າຍອດເກີນ limit ຂອງ unverified user
  Future<WalletResult<Map<String, dynamic>>> pay({
    required String paymentRequest,
    String memo = '',
    int? amountSats, // ລະບຸສຳລັບ LNURL/Address ທີ່ amount flexible
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

  // ຈ່າຍ LNURL ໂດຍກົງ (ບໍ່ຕ້ອງ decode ກ່ອນ)
  Future<WalletResult<Map<String, dynamic>>> payLNURL({
    required String lnurl,
    required int amountSats,
    String memo = '',
  }) async {
    final res = await _api.post(AppConstants.paymentPayLNURL, {
      'lnurl':      lnurl,
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

  // ─── LAO QR (Demo) ────────────────────────────────────────────────────────
  // ຈ່າຍ LAO QR — server ບັນທຶກ transaction ແຕ່ ບໍ່ call LAPNET API ຕົວຈິງ
  // ເມື່ອ LAPNET API ພ້ອມ → ແກ້ server-side ດຽວ Flutter ບໍ່ຕ້ອງ change
  Future<WalletResult<Map<String, dynamic>>> payLaoQR({
    required int amountLAK,
    String merchantName = '',
    String bank = '',
    String qrRaw = '',       // raw QR string ທີ່ scan ໄດ້
    String description = '',
  }) async {
    final res = await _api.post(AppConstants.paymentLaoQR, {
      'amountLAK': amountLAK,
      if (merchantName.isNotEmpty) 'merchantName': merchantName,
      if (bank.isNotEmpty)         'bank':         bank,
      if (qrRaw.isNotEmpty)        'qrRaw':        qrRaw,
      if (description.isNotEmpty)  'description':  description,
    });

    if (res.success) {
      return WalletResult.success(res.data ?? {});
    }
    if (res.data?['requireKYC'] == true) {
      return WalletResult.failure(res.message, requireKYC: true);
    }
    return WalletResult.failure(res.message);
  }

  // ດຶງວົງເງິນ LAO QR ລາຍວັນຈາກ server (ໃຊ້ສະແດງ progress bar)
  Future<WalletResult<LaoQRLimitModel>> getLaoQRLimitStatus() async {
    final res = await _api.get(AppConstants.paymentLaoQRLimit);
    if (res.success && res.data != null) {
      return WalletResult.success(LaoQRLimitModel.fromJson(res.data!));
    }
    return WalletResult.failure(res.message);
  }

  // ─── Internal Transfer ────────────────────────────────────────────────────
  // ຊອກຫາ receiver ດ້ວຍ email ຫຼື wallet ID
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

  // ໂອນ LAK ລະຫວ່າງ wallet (endpoint ຢູ່ server ຍັງ implement ບໍ່ຄົບ)
  Future<WalletResult<Map<String, dynamic>>> transfer({
    required String receiverIdentifier,
    required int amountLAK,
    String memo = '',
  }) async {
    final res = await _api.post(AppConstants.paymentTransfer, {
      'receiverIdentifier': receiverIdentifier,
      'amountLAK':          amountLAK,
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
