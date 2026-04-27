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
  bool get isSuccess => status == 'ສຳເລັດ';
  bool get isPending => status == 'ລໍຖ້າດຳເນີນການ';
}

// ─── Invoice Decode Model ─────────────────────────────────────────────────────
class DecodedInvoiceModel {
  final int amountSats;
  final int amountLAK;
  final String description;
  final int expiry;
  final RateModel? rate;

  // ✅ ເພີ່ມ fields ສຳລັບ LNURL + Lightning Address
  final bool isLNURL;
  final bool isAddress;
  final int minSats;
  final int maxSats;
  final int minLAK;
  final int maxLAK;

  const DecodedInvoiceModel({
    required this.amountSats,
    required this.amountLAK,
    required this.description,
    required this.expiry,
    this.rate,
    this.isLNURL = false,
    this.isAddress = false,
    this.minSats = 0,
    this.maxSats = 0,
    this.minLAK = 0,
    this.maxLAK = 0,
  });

  factory DecodedInvoiceModel.fromJson(Map<String, dynamic> j) {
    final inv = j['invoice'] as Map<String, dynamic>? ?? j;

    final isLNURL = inv['isLNURL'] as bool? ?? false;
    final isAddress = inv['isAddress'] as bool? ?? false;

    // ✅ LNURL: ໃຊ້ minSats, Lightning Address: amountSats = 0, BOLT11: amountSats
    final amountSats = isLNURL
        ? (inv['minSats'] as num?)?.toInt() ?? 0
        : (inv['amountSats'] as num?)?.toInt() ?? 0;

    final amountLAK = isLNURL
        ? (inv['minLAK'] as num?)?.toInt() ?? 0
        : (inv['amountLAK'] as num?)?.toInt() ?? 0;

    return DecodedInvoiceModel(
      amountSats: amountSats,
      amountLAK: amountLAK,
      description:
          inv['description'] as String? ??
          inv['defaultDescription'] as String? ??
          (isAddress ? 'Pay to ${inv['payee'] ?? ''}' : 'LNURL Payment'),
      expiry: (inv['expiry'] as num?)?.toInt() ?? 0,
      rate: inv['rate'] != null ? RateModel.fromJson(inv['rate']) : null,
      isLNURL: isLNURL,
      isAddress: isAddress,
      minSats: (inv['minSats'] as num?)?.toInt() ?? 0,
      maxSats: (inv['maxSats'] as num?)?.toInt() ?? 0,
      minLAK: (inv['minLAK'] as num?)?.toInt() ?? 0,
      maxLAK: (inv['maxLAK'] as num?)?.toInt() ?? 0,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ✅ Models ໃໝ່ (ເພີ່ມໃສ່ app_models.dart ຖ້າຕ້ອງການ)
// ════════════════════════════════════════════════════════════════════════════

/// LAO QR daily limit info
class LaoQRLimitModel {
  final bool isKYCVerified;
  final int dailyLimit;
  final int todaySpent;
  final int remaining;
  final int percentage;

  const LaoQRLimitModel({
    required this.isKYCVerified,
    required this.dailyLimit,
    required this.todaySpent,
    required this.remaining,
    required this.percentage,
  });

  factory LaoQRLimitModel.fromJson(Map<String, dynamic> j) => LaoQRLimitModel(
    isKYCVerified: j['isKYCVerified'] ?? false,
    dailyLimit: j['dailyLimit'] ?? 2000000,
    todaySpent: j['todaySpent'] ?? 0,
    remaining: j['remaining'] ?? 2000000,
    percentage: j['percentage'] ?? 0,
  );
}

/// Receiver preview info
class ReceiverInfoModel {
  final String name;
  final String account;
  final String? profileImage;

  const ReceiverInfoModel({
    required this.name,
    required this.account,
    this.profileImage,
  });

  factory ReceiverInfoModel.fromJson(Map<String, dynamic> j) =>
      ReceiverInfoModel(
        name: j['name'] ?? '',
        account: j['account'] ?? '',
        profileImage: j['profileImage'],
      );
}
