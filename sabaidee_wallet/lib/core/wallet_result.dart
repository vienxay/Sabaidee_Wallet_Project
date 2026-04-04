// lib/core/wallet_result.dart
class WalletResult<T> {
  final T? data;
  final String? message;
  final bool success;
  final bool requireKYC;

  const WalletResult._({
    this.data,
    this.message,
    required this.success,
    this.requireKYC = false,
  });

  factory WalletResult.success(T data) =>
      WalletResult._(data: data, success: true);

  factory WalletResult.failure(String? message, {bool requireKYC = false}) =>
      WalletResult._(message: message, success: false, requireKYC: requireKYC);
}
