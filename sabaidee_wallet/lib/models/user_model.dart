// lib/models/user_model.dart

// ✅ ຕ້ອງ define enum ກ່ອນ UserModel
enum KycStatus { pending, verified, rejected }

// ── Wallet Model ──────────────────────────────────────────────
class WalletModel {
  final String walletId;
  final String walletName;
  final String invoiceKey;
  final int balanceSats;

  const WalletModel({
    required this.walletId,
    required this.walletName,
    required this.invoiceKey,
    required this.balanceSats,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletId: json['walletId']?.toString() ?? '',
      walletName: json['walletName']?.toString() ?? '',
      invoiceKey: json['invoiceKey']?.toString() ?? '',
      balanceSats: json['balanceSats'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'walletId': walletId,
    'walletName': walletName,
    'invoiceKey': invoiceKey,
    'balanceSats': balanceSats,
  };
}

// ── User Model ────────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final KycStatus? kycStatus;
  final bool isGoogleAccount;
  final WalletModel? wallet;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.kycStatus,
    this.isGoogleAccount = false,
    this.wallet,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id']?.toString() ?? json['id']?.toString();
    return UserModel(
      id: rawId ?? (throw ArgumentError('UserModel: missing id')),
      name: json['name']?.toString().trim() ?? '',
      email: json['email']?.toString().trim() ?? '',
      kycStatus: _parseKycStatus(json['kycStatus']),
      isGoogleAccount: json['isGoogleAccount'] ?? false,
      wallet: json['wallet'] != null
          ? WalletModel.fromJson(json['wallet'] as Map<String, dynamic>)
          : null,
    );
  }

  factory UserModel.fromGoogleJson(Map<String, dynamic> json) {
    return UserModel(
      id:
          json['id']?.toString() ??
          (throw ArgumentError('UserModel: missing id')),
      name: json['name']?.toString().trim() ?? '',
      email: json['email']?.toString().trim() ?? '',
      kycStatus: _parseKycStatus(json['kycStatus']),
      isGoogleAccount: json['isGoogleAccount'] ?? true,
      wallet: json['wallet'] != null
          ? WalletModel.fromJson(json['wallet'] as Map<String, dynamic>)
          : null,
    );
  }

  static KycStatus? _parseKycStatus(dynamic value) {
    if (value == null) return null;
    return KycStatus.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => KycStatus.pending,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'kycStatus': kycStatus?.name,
    'isGoogleAccount': isGoogleAccount,
    'wallet': wallet?.toJson(),
  };

  bool get hasWallet => wallet != null && wallet!.walletId.isNotEmpty;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    KycStatus? kycStatus,
    bool? isGoogleAccount,
    WalletModel? wallet,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      kycStatus: kycStatus ?? this.kycStatus,
      isGoogleAccount: isGoogleAccount ?? this.isGoogleAccount,
      wallet: wallet ?? this.wallet,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email, '
      'kycStatus: ${kycStatus?.name}, hasWallet: $hasWallet)';
}
