// ຈັດການການຖອນ sats ອອກ:
//   preview  → ກວດ limit + ຄຳນວນ sats ກ່ອນຖອນ (ບໍ່ຖອນຈິງ)
//   send     → ຖອນຈິງ ຜ່ານ LNBits → Lightning Network
// ຮອງຮັບ destination: Lightning Address, LNURL, BOLT11 invoice
import '../core/core.dart';
import 'api_client.dart';

class WithdrawalService {
  WithdrawalService._();
  static final WithdrawalService instance = WithdrawalService._();

  final _api = ApiClient.instance;

  // ດຶງວົງເງິນຖອນ: per-tx limit, daily limit, ຍອດໃຊ້ໄປແລ້ວ, ຍອດຄົງເຫຼືອ
  Future<WalletResult<WithdrawalLimitModel>> getLimitStatus() async {
    final res = await _api.get(AppConstants.withdrawalLimitStatus);
    if (res.success && res.data != null) {
      return WalletResult.success(WithdrawalLimitModel.fromJson(res.data!));
    }
    return WalletResult.failure(res.message);
  }

  // ສະຫຼຸບກ່ອນຖອນ: ກວດ limit, ຄຳນວນ LAK→sats, ຄ່າ fee estimate
  // ໃຊ້ສະແດງໃນ confirm screen ກ່ອນ user ກົດ "ຢືນຢັນ"
  Future<WalletResult<WithdrawalPreviewModel>> preview({
    required String destination,
    required int amountLAK,
  }) async {
    final res = await _api.post(AppConstants.withdrawalPreview, {
      'destination': destination,
      'amountLAK':   amountLAK,
    });

    if (res.success && res.data != null) {
      return WalletResult.success(WithdrawalPreviewModel.fromJson(res.data!));
    }
    if (res.data?['requireKYC'] == true) {
      return WalletResult.failure(res.message, requireKYC: true);
    }
    return WalletResult.failure(res.message);
  }

  // ຖອນຈິງ — server ສົ່ງ Lightning payment ຜ່ານ LNBits
  // ຄວນ call preview() ກ່ອນສະເໝີ ເພື່ອ confirm ກັບ user
  Future<WalletResult<Map<String, dynamic>>> send({
    required String destination,
    required int amountLAK,
    String memo = 'Withdraw',
  }) async {
    final res = await _api.post(AppConstants.withdrawalSend, {
      'destination': destination,
      'amountLAK':   amountLAK,
      'memo':        memo,
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

// ─── Models ───────────────────────────────────────────────────────────────────

// ວົງເງິນຖອນ + ຍອດໃຊ້ປະຈຸວັນ
class WithdrawalLimitModel {
  final bool isKYCVerified;
  final int balanceSats;
  final int perTxLimit;       // ສູງສຸດຕໍ່ transaction (LAK)
  final int dailyLimit;       // ສູງສຸດຕໍ່ມື້ (LAK)
  final int todayWithdrawn;   // ຖອນໄປແລ້ວວັນນີ້ (LAK)
  final int remaining;        // ຍັງຖອນໄດ້ (LAK)
  final int percentage;       // % ທີ່ໃຊ້ໄປ (0-100)

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
        balanceSats:   j['balanceSats']   ?? 0,
        perTxLimit:    j['perTxLimit']    ?? 500000,
        dailyLimit:    j['dailyLimit']    ?? 1000000,
        todayWithdrawn: j['todayWithdrawn'] ?? 0,
        remaining:     j['remaining']     ?? 0,
        percentage:    j['percentage']    ?? 0,
      );
}

// ຂໍ້ມູນສະຫຼຸບກ່ອນຖອນ — ສະແດງໃຫ້ user confirm
class WithdrawalPreviewModel {
  final String destinationType;  // 'address' | 'lnurl' | 'invoice'
  final String destination;
  final int amountLAK;
  final int amountSats;
  final int estimatedFeeSats;    // ~0.1% estimate
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
    final rate   = j['rate']   as Map<String, dynamic>? ?? {};
    return WithdrawalPreviewModel(
      destinationType: j['destinationType'] ?? 'address',
      destination:     j['destination']     ?? '',
      amountLAK:       j['amountLAK']       ?? 0,
      amountSats:      j['amountSats']      ?? 0,
      estimatedFeeSats: j['estimatedFeeSats'] ?? 0,
      balanceSats:     j['balanceSats']     ?? 0,
      btcToLAK:        (rate['btcToLAK']    ?? 0).toDouble(),
      perTxLimit:      limits['perTx']      ?? 500000,
      dailyLimit:      limits['daily']      ?? 1000000,
      todayWithdrawn:  limits['todayWithdrawn'] ?? 0,
      remaining:       limits['remaining']  ?? 0,
    );
  }
}
