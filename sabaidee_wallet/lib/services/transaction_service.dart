import '../core/core.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'wallet_service.dart'; // ເພື່ອໃຊ້ WalletResult

class TransactionService {
  TransactionService._();
  static final TransactionService instance = TransactionService._();

  final _api = ApiClient.instance;

  Future<WalletResult<List<TransactionModel>>> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    var path = '${AppConstants.transactions}?page=$page&limit=$limit';
    if (type != null) path += '&type=$type';

    final res = await _api.get(path);
    if (res.success && res.data?['transactions'] != null) {
      final list = (res.data!['transactions'] as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return WalletResult.success(list);
    }
    return WalletResult.failure(res.message);
  }

  Future<bool> checkPaymentStatus(String paymentHash) async {
    final res = await _api.get(
      '${AppConstants.transactions}/check/$paymentHash',
    );
    return res.success && res.data?['paid'] == true;
  }

  Future<WalletResult<Map<String, dynamic>>> getSummary() async {
    final res = await _api.get(AppConstants.transactionSummary);
    if (res.success && res.data?['summary'] != null) {
      return WalletResult.success(res.data!['summary'] as Map<String, dynamic>);
    }
    return WalletResult.failure(res.message);
  }
}
