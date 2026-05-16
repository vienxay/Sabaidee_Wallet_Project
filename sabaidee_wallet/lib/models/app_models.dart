// Data Models ທັງໝົດຂອງ App
// ໄຟລ໌ນີ້ເປັນ single source of truth ສຳລັບໂຄງສ້າງຂໍ້ມູນທີ່ຮັບຈາກ API

// ─── User Model ───────────────────────────────────────────────────────────────
/// ຂໍ້ມູນ user ທີ່ login ຢູ່
class UserModel {
  final String id;
  final String name;
  final String? lastName;
  final String email;
  final String? phone;
  final String? dob;
  final String? gender;
  final String? profileImage;

  /// 'none' | 'pending' | 'verified' | 'rejected'
  final String kycStatus;

  /// 'user' | 'admin' | 'staff'
  final String role;
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
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:           j['id'] as String? ?? j['_id'] as String? ?? '',
    name:         j['name'] as String? ?? j['firstName'] as String? ?? '',
    lastName:     j['lastName'] as String?,
    email:        j['email'] as String? ?? '',
    phone:        j['phone'] as String? ?? j['phoneNumber'] as String?,
    dob:          j['dob'] as String? ?? j['birthDate'] as String?,
    gender:       j['gender'] as String?,
    profileImage: j['profileImage']?.toString(),
    kycStatus:    j['kycStatus'] as String? ?? 'pending',
    role:         j['role'] as String? ?? 'user',
    createdAt:    j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'lastName': lastName, 'email': email,
    'phone': phone, 'dob': dob, 'gender': gender,
    'profileImage': profileImage, 'kycStatus': kycStatus, 'role': role,
  };

  bool get isKYCVerified => kycStatus == 'verified';
  bool get isAdmin       => role == 'admin';
  bool get isStaff       => role == 'staff';
}

// ─── Wallet Model ─────────────────────────────────────────────────────────────
/// ຂໍ້ມູນ LNBits wallet ຂອງ user
/// balanceSats = ຍອດ Bitcoin (satoshi), balanceLAK = ຍອດກີບ (demo)
class WalletModel {
  final String walletId;
  final String walletName;
  final String invoiceKey; // ໃຊ້ຮັບ payment (ສ້າງ invoice)
  final int balanceSats;
  final int balanceLAK;
  final RateModel? rate;   // exchange rate ທີ່ດຶງພ້ອມ balance

  const WalletModel({
    required this.walletId,
    required this.walletName,
    required this.invoiceKey,
    required this.balanceSats,
    this.balanceLAK = 0,
    this.rate,
  });

  factory WalletModel.fromJson(Map<String, dynamic> j) => WalletModel(
    walletId:   j['walletId']   as String? ?? '',
    walletName: j['walletName'] as String? ?? '',
    invoiceKey: j['invoiceKey'] as String? ?? '',
    balanceSats: (j['balanceSats'] as num?)?.toInt() ?? 0,
    balanceLAK:  (j['balanceLAK']  as num?)?.toInt() ?? 0,
    rate: j['rate'] != null ? RateModel.fromJson(j['rate']) : null,
  );
}

// ─── Rate Model ───────────────────────────────────────────────────────────────
/// Exchange rate ສຳລັບ BTC ↔ LAK ↔ USD
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
    btcToUSD:  (j['btcToUSD']  as num?)?.toDouble() ?? 0,
    btcToLAK:  (j['btcToLAK']  as num?)?.toDouble() ?? 0,
    usdToLAK:  (j['usdToLAK']  as num?)?.toDouble() ?? 0,
    updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt']) : null,
  );
}

// ─── Transaction Model ────────────────────────────────────────────────────────
/// ຂໍ້ມູນ transaction ເດີ່ຍ (pay, topup, withdraw, laoQR)
class TransactionModel {
  final String id;

  /// 'pay' | 'topup' | 'withdraw' | 'laoQR'
  final String type;

  /// 'success' | 'pending' | 'failed'
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
    id:          j['_id']         as String? ?? '',
    type:        j['type']        as String? ?? '',
    status:      j['status']      as String? ?? '',
    amountSats:  (j['amountSats'] as num?)?.toInt() ?? 0,
    amountLAK:   (j['amountLAK']  as num?)?.toInt() ?? 0,
    feeSats:     (j['feeSats']    as num?)?.toInt() ?? 0,
    paymentHash: j['paymentHash'] as String? ?? '',
    memo:        j['memo']        as String? ?? '',
    kycRequired: j['kycRequired'] as bool? ?? false,
    createdAt:   DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );

  bool get isReceive => type == 'topup' || type == 'receive';
  bool get isSend    => type == 'withdraw' || type == 'pay';
  bool get isSuccess => status == 'ສຳເລັດ';
  bool get isPending => status == 'ລໍຖ້າດຳເນີນການ';
}

// ─── Invoice Decode Model ─────────────────────────────────────────────────────
/// ຜົນຈາກການ decode Lightning invoice ກ່ອນຈ່າຍ
/// ຮອງຮັບທັງ BOLT11 invoice, LNURL, ແລະ Lightning Address
class DecodedInvoiceModel {
  final int amountSats;
  final int amountLAK;
  final String description;
  final int expiry;      // invoice ໝົດອາຍຸໃນ X ວິນາທີ
  final RateModel? rate;

  final bool isLNURL;    // true = ຕ້ອງໃສ່ຈຳນວນເອງ (ບໍ່ fixed amount)
  final bool isAddress;  // true = Lightning Address (user@domain.com)
  final int minSats;     // LNURL: ຈຳນວນຕ່ຳສຸດ
  final int maxSats;     // LNURL: ຈຳນວນສູງສຸດ
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
    final inv      = j['invoice'] as Map<String, dynamic>? ?? j;
    final isLNURL  = inv['isLNURL']  as bool? ?? false;
    final isAddress = inv['isAddress'] as bool? ?? false;

    // LNURL/Address: amount = 0 (user ຕ້ອງໃສ່ເອງ), BOLT11: amount fixed
    final amountSats = (isLNURL || isAddress)
        ? 0
        : (inv['amountSats'] as num?)?.toInt() ?? 0;
    final amountLAK = (isLNURL || isAddress)
        ? 0
        : (inv['amountLAK'] as num?)?.toInt() ?? 0;

    return DecodedInvoiceModel(
      amountSats:  amountSats,
      amountLAK:   amountLAK,
      description: inv['description'] as String?
          ?? inv['defaultDescription'] as String?
          ?? (isAddress ? 'Pay to ${inv['payee'] ?? ''}' : 'LNURL Payment'),
      expiry:  (inv['expiry'] as num?)?.toInt() ?? 0,
      rate:    inv['rate'] != null ? RateModel.fromJson(inv['rate']) : null,
      isLNURL: isLNURL,
      isAddress: isAddress,
      minSats: (inv['minSats'] as num?)?.toInt() ?? 0,
      maxSats: (inv['maxSats'] as num?)?.toInt() ?? 0,
      minLAK:  (inv['minLAK']  as num?)?.toInt() ?? 0,
      maxLAK:  (inv['maxLAK']  as num?)?.toInt() ?? 0,
    );
  }
}

// ─── LAO QR Limit Model ───────────────────────────────────────────────────────
/// ຂໍ້ມູນວົງເງິນ LAO QR ລາຍວັນຂອງ user
class LaoQRLimitModel {
  final bool isKYCVerified;
  final int dailyLimit;    // ວົງເງິນທັງໝົດຕໍ່ມື້ (LAK)
  final int todaySpent;    // ໃຊ້ໄປແລ້ວວັນນີ້ (LAK)
  final int remaining;     // ຍັງໃຊ້ໄດ້ (LAK)
  final int percentage;    // % ທີ່ໃຊ້ໄປ (0-100)

  const LaoQRLimitModel({
    required this.isKYCVerified,
    required this.dailyLimit,
    required this.todaySpent,
    required this.remaining,
    required this.percentage,
  });

  factory LaoQRLimitModel.fromJson(Map<String, dynamic> j) => LaoQRLimitModel(
    isKYCVerified: j['isKYCVerified'] ?? false,
    dailyLimit:    j['dailyLimit']    ?? 2000000,
    todaySpent:    j['todaySpent']    ?? 0,
    remaining:     j['remaining']     ?? 2000000,
    percentage:    j['percentage']    ?? 0,
  );
}

// ─── Receiver Info Model ──────────────────────────────────────────────────────
/// ຂໍ້ມູນ receiver ທີ່ຮັບເງິນ (ໃຊ້ໃນ internal transfer)
class ReceiverInfoModel {
  final String name;
  final String account;   // wallet ID ຫຼື email
  final String? profileImage;

  const ReceiverInfoModel({
    required this.name,
    required this.account,
    this.profileImage,
  });

  factory ReceiverInfoModel.fromJson(Map<String, dynamic> j) =>
      ReceiverInfoModel(
        name:         j['name']    ?? '',
        account:      j['account'] ?? '',
        profileImage: j['profileImage'],
      );
}
