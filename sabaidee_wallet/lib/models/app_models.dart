// lib/models/app_models.dart
// Source of Truth - ມີ Model ທັງໝົດ

// ─── User Model ───────────────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String name; // ໃຊ້ເປັນ firstName ກໍໄດ້ ຫຼື name ຄືເກົ່າ
  final String? lastName; // ເພີ່ມໃໝ່
  final String email;
  final String? phone; // ເພີ່ມໃໝ່
  final String? dob; // ວັນເກີດ
  final String? gender; // ເພດ
  final String? profileImage;
  final String kycStatus;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    this.lastName,
    required this.email,
    this.phone,
    this.dob,
    this.gender,
    this.profileImage,
    required this.kycStatus,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] as String? ?? j['_id'] as String? ?? '', // ຮອງຮັບທັງ id ແລະ _id
    name: j['name'] as String? ?? j['firstName'] as String? ?? '',
    lastName: j['lastName'] as String?,
    email: j['email'] as String? ?? '',
    phone: j['phone'] as String? ?? j['phoneNumber'] as String?,
    dob: j['dob'] as String? ?? j['birthDate'] as String?,
    gender: j['gender'] as String?,
    profileImage: j['profileImage']?.toString(),
    kycStatus: j['kycStatus'] as String? ?? 'pending',
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'dob': dob,
    'gender': gender,
    'profileImage': profileImage,
    'kycStatus': kycStatus,
  };

  bool get isKYCVerified => kycStatus == 'verified';
}

// ─── Wallet Model ─────────────────────────────────────────────────────────────
class WalletModel {
  final String walletId;
  final String walletName;
  final String invoiceKey;
  final int balanceSats;
  final int balanceLAK;
  final RateModel? rate;

  const WalletModel({
    required this.walletId,
    required this.walletName,
    required this.invoiceKey,
    required this.balanceSats,
    this.balanceLAK = 0,
    this.rate,
  });

  factory WalletModel.fromJson(Map<String, dynamic> j) => WalletModel(
    walletId: j['walletId'] as String? ?? '',
    walletName: j['walletName'] as String? ?? '',
    invoiceKey: j['invoiceKey'] as String? ?? '',
    balanceSats: (j['balanceSats'] as num?)?.toInt() ?? 0,
    balanceLAK: (j['balanceLAK'] as num?)?.toInt() ?? 0,
    rate: j['rate'] != null ? RateModel.fromJson(j['rate']) : null,
  );
}

// ─── Rate Model ───────────────────────────────────────────────────────────────
class RateModel {
  final double btcToUSD;
  final double btcToLAK;
  final double usdToLAK;
  final DateTime? updatedAt;

  const RateModel({
    required this.btcToUSD,
    required this.btcToLAK,
    required this.usdToLAK,
    this.updatedAt,
  });

  factory RateModel.fromJson(Map<String, dynamic> j) => RateModel(
    btcToUSD: (j['btcToUSD'] as num?)?.toDouble() ?? 0,
    btcToLAK: (j['btcToLAK'] as num?)?.toDouble() ?? 0,
    usdToLAK: (j['usdToLAK'] as num?)?.toDouble() ?? 0,
    updatedAt: j['updatedAt'] != null
        ? DateTime.tryParse(j['updatedAt'])
        : null,
  );
}

// ─── Transaction Model ────────────────────────────────────────────────────────
class TransactionModel {
  final String id;
  final String type;
  final String status;
  final int amountSats;
  final int amountLAK;
  final int feeSats;
  final String paymentHash;
  final String memo;
  final bool kycRequired;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amountSats,
    required this.amountLAK,
    this.feeSats = 0,
    this.paymentHash = '',
    this.memo = '',
    this.kycRequired = false,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
    id: j['_id'] as String? ?? '',
    type: j['type'] as String? ?? '',
    status: j['status'] as String? ?? '',
    amountSats: (j['amountSats'] as num?)?.toInt() ?? 0,
    amountLAK: (j['amountLAK'] as num?)?.toInt() ?? 0,
    feeSats: (j['feeSats'] as num?)?.toInt() ?? 0,
    paymentHash: j['paymentHash'] as String? ?? '',
    memo: j['memo'] as String? ?? '',
    kycRequired: j['kycRequired'] as bool? ?? false,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );

  bool get isReceive => type == 'topup' || type == 'receive';
  bool get isSend => type == 'withdraw' || type == 'pay';
  bool get isSuccess => status == 'success';
  bool get isPending => status == 'pending';
}

// ─── Invoice Decode Model ─────────────────────────────────────────────────────
class DecodedInvoiceModel {
  final int amountSats;
  final int amountLAK;
  final String description;
  final int expiry;
  final RateModel? rate;

  const DecodedInvoiceModel({
    required this.amountSats,
    required this.amountLAK,
    required this.description,
    required this.expiry,
    this.rate,
  });

  factory DecodedInvoiceModel.fromJson(Map<String, dynamic> j) {
    final inv = j['invoice'] as Map<String, dynamic>? ?? j;
    return DecodedInvoiceModel(
      amountSats: (inv['amountSats'] as num?)?.toInt() ?? 0,
      amountLAK: (inv['amountLAK'] as num?)?.toInt() ?? 0,
      description: inv['description'] as String? ?? '',
      expiry: (inv['expiry'] as num?)?.toInt() ?? 0,
      rate: inv['rate'] != null ? RateModel.fromJson(inv['rate']) : null,
    );
  }
}
