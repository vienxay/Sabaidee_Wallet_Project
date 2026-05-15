// ຫໍ່ຜົນລັບຈາກ Service ທຸກຕົວ — ໃຊ້ generic T ເພື່ອຮອງຮັບທຸກ data type
//
// ຕົວຢ່າງການໃຊ້:
//   final result = await PaymentService.instance.pay(...);
//   if (result.success) { ... result.data ... }
//   else if (result.requireKYC) { ... navigate to KYC ... }
//   else { ... show result.message ... }
class WalletResult<T> {
  final T? data;

  // message ເປັນ String ບໍ່ nullable — default '' ຖ້າບໍ່ມີ error message
  // ຊ່ວຍໃຫ້ code ໃຊ້ .message.isNotEmpty ໂດຍບໍ່ຕ້ອງ null check
  final String message;
  final bool success;

  /// true = server ຕອບຮັບ 403 ພ້ອມ requireKYC flag
  /// Flutter ຈະ redirect ໄປ KYC screen ໂດຍອັດຕະໂນມັດ
  final bool requireKYC;

  const WalletResult._({
    this.data,
    this.message = '',
    required this.success,
    this.requireKYC = false,
  });

  /// ສ້າງ result ສຳລັບກໍລະນີສຳເລັດ
  factory WalletResult.success(T data) =>
      WalletResult._(data: data, success: true);

  /// ສ້າງ result ສຳລັບກໍລະນີລົ້ມເຫລວ
  /// [requireKYC] = true ຖ້າ user ຕ້ອງ verify KYC ກ່ອນ
  factory WalletResult.failure(String message, {bool requireKYC = false}) =>
      WalletResult._(message: message, success: false, requireKYC: requireKYC);
}
