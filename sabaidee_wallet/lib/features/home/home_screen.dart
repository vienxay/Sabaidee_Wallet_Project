import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/core.dart';
import '../../models/app_models.dart';
import '../../services/wallet_service.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // ─── UI State ─────────────────────────────────────────────────────────────
  bool _balanceVisible = true;
  int _selectedIndex = 0;

  // ─── Data State ───────────────────────────────────────────────────────────
  bool _loading = true;
  UserModel? _user; // ✅ ເພີ່ມ user
  WalletModel? _wallet;
  List<TransactionModel> _recentTx = [];
  String? _error;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─── Load Data ────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // ✅ ດຶງຂໍ້ມູນທັງ 3 ພ້ອມກັນ
    final results = await Future.wait([
      AuthService.instance.getMe(),
      WalletService.instance.getWallet(),
      TransactionService.instance.getTransactions(limit: 5),
    ]);

    if (!mounted) return;

    final user = results[0] as UserModel?;
    final walletRes = results[1] as WalletResult<WalletModel>;
    final txRes = results[2] as WalletResult<List<TransactionModel>>;

    setState(() {
      _loading = false;
      _user = user;
      if (walletRes.success) _wallet = walletRes.data;
      if (txRes.success) _recentTx = txRes.data ?? [];
      if (!walletRes.success) _error = walletRes.message;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────
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
      drawer: const MenuDrawer(),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        onScan: () => _openScanner(title: 'ສະແກນ QR Code'),
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────
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

  // ─── Error UI ─────────────────────────────────────────────────────────────
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

  // ─── Content ──────────────────────────────────────────────────────────────
  Widget _buildContent() => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ ສົ່ງ user ໄປ HomeTopBar
        HomeTopBar(scaffoldKey: _scaffoldKey, user: _user),
        const SizedBox(height: 12),

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

        if (_recentTx.isNotEmpty) HomeRecentTx(tx: _recentTx.first),
        const SizedBox(height: 24),

        HomeHistoryBtn(onTap: _openHistory),
        const SizedBox(height: 100),
      ],
    ),
  );

  // ─── Actions ──────────────────────────────────────────────────────────────
  void _openReceive() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiveSheet(wallet: _wallet),
    );
    // ✅ refresh ຖ້າ TopUp ສຳເລັດ
    if (result == true && mounted) _loadData();
  }

  void _openHistory() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const HistoryScreen()),
  );

  Future<void> _openScanner({required String title}) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => QrScannerScreen(title: title)),
    );

    if (result == null || !mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          SendSheet(wallet: _wallet, invoice: result, onSuccess: _loadData),
    );
  }
}
