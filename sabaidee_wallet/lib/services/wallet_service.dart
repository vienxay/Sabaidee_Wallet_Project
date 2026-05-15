// ຈັດການ Wallet: ດຶງ balance, rate, ສ້າງ invoice top-up, ກວດສະຖານະ payment
import '../core/core.dart';
import '../models/app_models.dart';
import 'api_client.dart';

class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  final _api = ApiClient.instance;

  // ດຶງຂໍ້ມູນ wallet ທັງໝົດ (walletId, name, keys, balance)
  Future<WalletResult<WalletModel>> getWallet() async {
    final res = await _api.get(AppConstants.wallet);
    if (res.success && res.data?['wallet'] != null) {
      return WalletResult.success(WalletModel.fromJson(res.data!['wallet']));
    }
    return WalletResult.failure(res.message);
  }

  // ດຶງ balance ສົດ (sats + LAK) ພ້ອມ rate — ໃຊ້ refresh ຫນ້າ home
  // clamp(0, 999999999) ກັນຄ່າ negative ຫຼື overflow ຈາກ server
  Future<WalletResult<WalletModel>> getBalance() async {
    final res = await _api.get(AppConstants.walletBalance);
    if (res.success && res.data?['balance'] != null) {
      final b = res.data!['balance'] as Map<String, dynamic>;

      final wallet = WalletModel(
        walletId:   '',
        walletName: '',
        invoiceKey: '',
        balanceSats: ((b['sats'] as num?)?.toInt() ?? 0).clamp(0, 999999999),
        balanceLAK:  ((b['lak']  as num?)?.toInt() ?? 0).clamp(0, 999999999),
        rate: b['btcToLAK'] != null
            ? RateModel(
                btcToUSD: (b['btcToUSD'] as num?)?.toDouble() ?? 0,
                btcToLAK: (b['btcToLAK'] as num?)?.toDouble() ?? 0,
                usdToLAK: 0,
              )
            : null,
      );
      return WalletResult.success(wallet);
    }
    return WalletResult.failure(res.message);
  }

  // ດຶງ BTC/LAK exchange rate ລ່າສຸດ
  Future<WalletResult<RateModel>> getRate() async {
    final res = await _api.get(AppConstants.walletRate);
    if (res.success && res.data?['rate'] != null) {
      return WalletResult.success(RateModel.fromJson(res.data!['rate']));
    }
    return WalletResult.failure(res.message);
  }

  // ສ້າງ Lightning invoice ສຳລັບ top-up — user ຈ່າຍຈາກ wallet ອື່ນ
  // return: { paymentRequest, paymentHash, amountSats }
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

  // ກວດວ່າ top-up invoice ຖືກຈ່າຍແລ້ວຫຼືຍັງ (polling ໂດຍ receive_sheet)
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
