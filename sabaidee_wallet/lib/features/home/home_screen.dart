// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';
import '../../models/app_models.dart';
import '../../models/kyc_status.dart';
import '../../services/wallet_service.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../services/kyc_gate_service.dart';
import '../../services/kyc_service.dart';
import '../../widgets/menu_drawer.dart';
import '../../widgets/receive_sheet.dart';
import '../../widgets/send_sheet.dart';

import '../home/home_action_buttons.dart';
import '../home/home_top_bar.dart';
import '../home/home_recent_tx.dart';
import '../home/home_bottom_nav.dart';
import '../home/home_balance_card.dart';
import '../home/home_history_btn.dart';

import '../../features/scanner/qr_scanner_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/scanner/qr_utils.dart';
import '../../features/payment/transfer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _balanceVisible = true;
  int _selectedIndex = 0;

  bool _loading = true;
  UserModel? _user;
  WalletModel? _wallet;
  List<TransactionModel> _recentTx = [];
  String? _error;

  // ✅ KYC state
  KycStatus _kycStatus = KycStatus.none;
  KycExistingData? _kycExisting;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final results = await Future.wait([
      AuthService.instance.getMe(),
      WalletService.instance.getBalance(),
      TransactionService.instance.getTransactions(limit: 5),
    ]);

    // ✅ sync KYC status ຈາກ backend
    await KycGateService.instance.syncFromBackend();
    final kycStatus = await KycGateService.instance.getStatus();

    KycExistingData? kycExisting;
    if (kycStatus == KycStatus.rejected) {
      // ດຶງຂໍ້ມູນ KYC ເກົ່າ ສຳລັບ pre-fill ຕອນ re-submit
      try {
        final res = await KycService.checkMyStatus();
        if (res['success'] == true) {
          kycExisting = KycExistingData.fromJson(res);
        }
      } catch (_) {}
    }

    if (!mounted) return;

    final user = results[0] as UserModel?;
    final walletRes = results[1] as WalletResult<WalletModel>;
    final txRes = results[2] as WalletResult<List<TransactionModel>>;

    setState(() {
      _loading = false;
      _user = user;
      _kycStatus = kycStatus;
      _kycExisting = kycExisting;
      if (walletRes.success) _wallet = walletRes.data;
      if (txRes.success) _recentTx = txRes.data ?? [];
      if (!walletRes.success) _error = walletRes.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scaffoldBg,
      drawer: MenuDrawer(
        balanceSats: _wallet?.balanceSats ?? 0,
        balanceLAK: (_wallet?.balanceLAK ?? 0.0).toDouble(),
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        onScan: () => _openScanner(title: 'ສະແກນ QR Code'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: _error != null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textGrey),
        const SizedBox(height: 12),
        Text(
          _error!,
          style: const TextStyle(color: AppColors.textGrey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh, color: AppColors.primary),
          label: const Text(
            'ລອງໃໝ່',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    ),
  );

  Widget _buildContent() {
    final now = DateTime.now();
    final successTx = _recentTx
        .where(
          (tx) =>
              tx.status == 'success' &&
              now.difference(tx.createdAt).inHours < 24,
        )
        .toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeTopBar(scaffoldKey: _scaffoldKey, user: _user),
          const SizedBox(height: 12),

          // ✅ KYC Promo Banner — ສະແດງຖ້າ user ຍັງບໍ່ KYC
          if (_kycStatus == KycStatus.none)
            _KycPromoBanner(onTap: _openKycSubmit),

          HomeBalanceCard(
            wallet: _wallet,
            balanceVisible: _balanceVisible,
            onToggleVisibility: () =>
                setState(() => _balanceVisible = !_balanceVisible),
          ),
          const SizedBox(height: 20),
          HomeActionButtons(
            onReceive: _openReceive,
            onSend: () => _openScanner(title: 'ສະແກນເພື່ອສົ່ງ'),
          ),
          const SizedBox(height: 24),

          if (successTx.isNotEmpty)
            HomeRecentTx(tx: successTx.first)
          else
            _buildEmptyTx(),

          const SizedBox(height: 24),
          HomeHistoryBtn(onTap: _openHistory),

          // ✅ KYC Rejected Banner — ຢູ່ດ້ານລຸ່ມປະຫວັດທຸລະກຳ
          if (_kycStatus == KycStatus.rejected) ...[
            const SizedBox(height: 16),
            _KycRejectedBanner(
              reviewNote: _kycExisting?.reviewNote,
              onTap: _openKycResubmit,
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEmptyTx() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ຍັງບໍ່ມີທຸລະກຳ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Actions ────────────────────────────────────────────────────────────────
  void _openReceive() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiveSheet(wallet: _wallet),
    );
    if (result == true && mounted) _loadData();
  }

  void _openHistory() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const HistoryScreen()),
  );

  // ✅ ເປີດໜ້າ KYC ຄັ້ງທຳອິດ (status == none)
  void _openKycSubmit() {
    Navigator.of(context).pushNamed(
      '/kyc',
      arguments: KycRouteArgs(onCompleted: () => _loadData()),
    );
  }

  // ✅ ເປີດໜ້າ KYC ໃນໂໝດ re-submit
  void _openKycResubmit() {
    Navigator.of(context).pushNamed(
      '/kyc',
      arguments: KycRouteArgs(
        existingData: _kycExisting,
        onCompleted: () {
          _loadData(); // refresh home ຫຼັງ submit ສຳເລັດ
        },
      ),
    );
  }

  Future<void> _openScanner({required String title}) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => QrScannerScreen(title: title)),
    );
    if (result == null || !mounted) return;

    final qrType = detectQRType(result);
    if (qrType == QRType.laoQR) {
      final qrInfo = LaoQRInfo.fromRaw(result);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransferScreen(
            senderName: _user?.name ?? 'Sabaidee Wallet',
            senderAccount: 'ສາບາຍດີ Wallet',
            senderAvatarUrl: _user?.profileImage,
            receiverName: qrInfo.merchantName,
            receiverAccount: qrInfo.bank,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            SendSheet(wallet: _wallet, invoice: result, onSuccess: _loadData),
      );
    }
  }
}

// ─── KYC Rejected Banner ──────────────────────────────────────────────────────
class _KycRejectedBanner extends StatelessWidget {
  final String? reviewNote;
  final VoidCallback onTap;

  const _KycRejectedBanner({this.reviewNote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // ✅ ຖ້າ admin ບໍ່ລະບຸ note ໃຫ້ໃຊ້ຂໍ້ຄວາມ default
    final note = (reviewNote != null && reviewNote!.isNotEmpty)
        ? reviewNote!
        : 'ບໍ່ໄດ້ລະບຸເຫດຜົນ — ກະລຸນາຕິດຕໍ່ທີມງານ';

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD94040).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD94040).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gpp_bad_outlined,
                color: Color(0xFFD94040),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KYC ຖືກປະຕິເສດ — ກົດເພື່ອແກ້ໄຂ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD94040),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ✅ ສະແດງ reviewNote ສະເໝີ (ມີ fallback)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: Color(0xFFD94040),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFD94040),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ກົດເພື່ອແກ້ໄຂ ແລະ ສົ່ງ KYC ຄືນ →',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFD94040),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── KYC Promo Banner (compact) ──────────────────────────────────────────────
class _KycPromoBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _KycPromoBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F7F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF1D9E75).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF1D9E75),
              size: 15,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'KYC ເພື່ອຊຳລະເງິນໄດ້ຫຼາຍກວ່າ ₭2,000,000 ຕໍ່ວັນ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F7A5A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'KYC ເລີຍ',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
