// ─── transfer_screen.dart ────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'transfer_confirm_screen.dart'; // ✅ ເພີ່ມ
import '../../services/daily_limit_service.dart';

class TransferScreen extends StatefulWidget {
  final String senderName;
  final String senderAccount;
  final String? senderAvatarUrl;

  final String receiverName;
  final String receiverAccount;
  final String? receiverAvatarUrl;

  const TransferScreen({
    super.key,
    this.senderName = '',
    this.senderAccount = '',
    this.senderAvatarUrl,
    this.receiverName = '',
    this.receiverAccount = '',
    this.receiverAvatarUrl,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with SingleTickerProviderStateMixin {
  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Quick amounts ──
  static const _quickAmounts = ['50,000', '100,000', '200,000', '500,000'];

  // ✅ ເພີ່ມຫຼັງ static const _quickAmounts
  int _todaySpent = 0;
  int _dailyLimit = DailyLimitService.limitUnverified;
  bool _limitLoaded = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
    _loadLimit();
  }

  Future<void> _loadLimit() async {
    final spent = await DailyLimitService.instance.getTodaySpent();
    final limit = await DailyLimitService.instance.getDailyLimit();
    if (!mounted) return;
    setState(() {
      _todaySpent = spent;
      _dailyLimit = limit;
      _limitLoaded = true;
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  void _fillAmount(String label) {
    _amountCtrl.text = label.replaceAll(',', '');
    setState(() {});
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransferConfirmScreen(
            senderName: widget.senderName,
            senderAccount: widget.senderAccount,
            senderAvatarUrl: widget.senderAvatarUrl,
            receiverName: widget.receiverName,
            receiverAccount: widget.receiverAccount,
            receiverAvatarUrl: widget.receiverAvatarUrl,
            amountLAK: int.parse(_amountCtrl.text.replaceAll(',', '')),
            memo: _memoCtrl.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_limitLoaded) ...[
                          _buildLimitBar(),
                          const SizedBox(height: 16),
                        ],

                        // ── Amount ──
                        _buildLabel('ຈຳນວນເງິນ (LAK)', required: true),
                        const SizedBox(height: 20),
                        _buildAmountField(),
                        const SizedBox(height: 12),

                        // ── Quick chips ──
                        _buildQuickChips(),
                        const SizedBox(height: 20),

                        // ── Memo ──
                        _buildLabel('ເນື້ອໃນ', required: true),
                        const SizedBox(height: 20),
                        _buildMemoField(),
                        const SizedBox(height: 32),

                        // ── Next button ──
                        _buildNextButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header (orange)
  // ═══════════════════
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8820C),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ ເພີ່ມ
        children: [
          // ── Top bar ── (ຄືເດີມ)
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'ໂອນເງິນ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 24),

          // ✅ ຈາກ Row → Column
          // ── ຈາກບັນຊີ ──
          Text(
            'ຈາກບັນຊີ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildAccountRow(
            name: widget.senderName,
            account: widget.senderAccount,
            avatarUrl: widget.senderAvatarUrl,
            avatarIcon: Icons.person,
          ),
          const SizedBox(height: 16),

          // ── ທາບັນຊີ ──
          Text(
            'ຫາບັນຊີ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildAccountRow(
            name: widget.receiverName,
            account: widget.receiverAccount,
            avatarUrl: widget.receiverAvatarUrl,
            avatarIcon: Icons.store_mall_directory_outlined,
          ),
        ],
      ),
    );
  }

  // ✅ ເພີ່ມກ່ອນ _buildLabel()
  Widget _buildLimitBar() {
    final remaining = _dailyLimit - _todaySpent;
    final progress = (_todaySpent / _dailyLimit).clamp(0.0, 1.0);
    final isNear = progress >= 0.8;

    String fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ວົງເງິນຄົງເຫຼືອວັນນີ້',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: fmt(remaining),
                    style: TextStyle(
                      color: isNear
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFE8820C),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${fmt(_dailyLimit)} ກີບ',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isNear ? const Color(0xFFEF4444) : const Color(0xFFE8820C),
            ),
          ),
        ),
      ],
    );
  }

  // ── Account row (avatar + name + account)
  // Widget _buildAccountRow({
  //   required String name,
  //   required String account,
  //   String? avatarUrl,
  //   IconData avatarIcon = Icons.person,
  //   bool alignEnd = false,
  // }) {
  //   final avatar = Container(
  //     width: 44,
  //     height: 44,
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       shape: BoxShape.circle,
  //       border: Border.all(
  //         color: Colors.white.withValues(alpha: 0.6),
  //         width: 2,
  //       ),
  //     ),
  //     child: avatarUrl != null
  //         ? ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover))
  //         : Icon(avatarIcon, color: const Color(0xFFE8820C), size: 24),
  //   );

  //   final textCol = Column(
  //     crossAxisAlignment: alignEnd
  //         ? CrossAxisAlignment.end
  //         : CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         name,
  //         maxLines: 1,
  //         overflow: TextOverflow.ellipsis,
  //         style: const TextStyle(
  //           color: Colors.white,
  //           fontSize: 13,
  //           fontWeight: FontWeight.w700,
  //         ),
  //       ),
  //       const SizedBox(height: 2),
  //       Text(
  //         account,
  //         style: TextStyle(
  //           color: Colors.white.withValues(alpha: 0.75),
  //           fontSize: 11,
  //         ),
  //       ),
  //     ],
  //   );

  //   return alignEnd
  //       ? Row(
  //           mainAxisAlignment: MainAxisAlignment.end,
  //           children: [textCol, const SizedBox(width: 8), avatar],
  //         )
  //       : Row(
  //           children: [
  //             avatar,
  //             const SizedBox(width: 8),
  //             Flexible(child: textCol),
  //           ],
  //         );
  // }

  Widget _buildAccountRow({
    required String name,
    required String account,
    String? avatarUrl,
    IconData avatarIcon = Icons.person,
  }) {
    final avatar = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: avatarUrl != null
          ? ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover))
          : Icon(avatarIcon, color: const Color(0xFFE8820C), size: 24),
    );

    return Row(
      children: [
        avatar,
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                account,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Form fields
  // ══════════════
  Widget _buildLabel(String text, {bool required = false}) => RichText(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      children: required
          ? [
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFE8820C)),
              ),
            ]
          : [],
    ),
  );

  Widget _buildAmountField() => TextFormField(
    controller: _amountCtrl,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1A1A),
    ),
    decoration: InputDecoration(
      hintText: 'ປ້ອນຈຳນວນເງິນ',
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixText: 'LAK  ',
      prefixStyle: const TextStyle(
        color: Color(0xFFE8820C),
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8820C), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return 'ກະລຸນາໃສ່ຈຳນວນເງິນ';
      final n = int.tryParse(v);
      if (n == null || n < 1000) return 'ຕ້ອງຢ່າງໜ້ອຍ 1,000 ກີບ';
      return null;
    },
    onChanged: (_) => setState(() {}),
  );

  Widget _buildQuickChips() => Wrap(
    spacing: 8,
    children: _quickAmounts.map((amt) {
      final isSelected = _amountCtrl.text == amt.replaceAll(',', '');
      return GestureDetector(
        onTap: () => _fillAmount(amt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8820C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE8820C)
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            '$amt ກີບ',
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF555555),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildMemoField() => TextFormField(
    controller: _memoCtrl,
    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
    decoration: InputDecoration(
      hintText: 'ເນື້ອໃນ',
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8820C), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
    ),
    validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'ກະລຸນາໃສ່ເນື້ອໃນ' : null,
  );

  // Next button
  // ════════════
  Widget _buildNextButton() => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: _onNext,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8820C),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        'ຕໍ່ໄປ',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}
