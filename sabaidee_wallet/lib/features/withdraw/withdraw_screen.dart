import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/withdrawal_service.dart';
import 'withdraw_success_screen.dart';
import '../../features/scanner/qr_scanner_screen.dart';

class WithdrawScreen extends StatefulWidget {
  final int balanceSats;
  final double balanceLAK;

  const WithdrawScreen({
    super.key,
    required this.balanceSats,
    required this.balanceLAK,
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _addressController = TextEditingController();
  final _amountLAKController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  double? _previewSats;
  String? _previewError;

  final _numberFormat = NumberFormat('#,###', 'en_US');

  double get _enteredLAK =>
      double.tryParse(_amountLAKController.text.replaceAll(',', '')) ?? 0;

  // ── Live preview ─────────────────────────────────────────────────────────
  void _onAmountChanged(String raw) {
    final cleaned = raw.replaceAll(',', '');
    final val = double.tryParse(cleaned) ?? 0;

    if (cleaned.isNotEmpty) {
      final formatted = _numberFormat.format(val);
      if (formatted != raw) {
        _amountLAKController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    setState(() {
      _previewSats = val > 0 ? (val / 0.37).roundToDouble() : null;
    });
  }

  // ── Withdraw Flow ─────────────────────────────────────────────────────────
  Future<void> _onWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _previewError = null;
    });

    try {
      final previewResult = await WithdrawalService.instance.preview(
        destination: _addressController.text.trim(),
        amountLAK: _enteredLAK.round(),
      );

      if (!mounted) return;

      if (previewResult.success && previewResult.data != null) {
        final confirmed = await _showConfirmDialog(previewResult.data!);
        if (!confirmed) return;

        final sendResult = await WithdrawalService.instance.send(
          destination: _addressController.text.trim(),
          amountLAK: _enteredLAK.round(),
          memo: 'Withdraw',
        );

        if (!mounted) return;

        if (sendResult.success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  WithdrawSuccessScreen(data: sendResult.data ?? {}),
            ),
          );
        } else {
          _showError(
            sendResult.message.isNotEmpty
                ? sendResult.message
                : 'ຖອນເງິນບໍ່ສຳເລັດ',
          );
        }
      } else {
        // ✅ ສະແດງ error ຕົງໆ — ບໍ່ຕ້ອງ KYC ສຳລັບການຖອນ
        setState(() {
          _previewError = previewResult.message;
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showConfirmDialog(WithdrawalPreviewModel preview) async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _ConfirmBottomSheet(preview: preview),
        ) ??
        false;
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(title: 'ສະແກນ Lightning'),
      ),
    );
    if (result != null && mounted) {
      _addressController.text = result.trim();
      _onAmountChanged(_amountLAKController.text);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountLAKController.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final balanceLAKFmt = _numberFormat.format(widget.balanceLAK.round());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            // ── Balance ────────────────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFFFF8C00),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$balanceLAKFmt LAK',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8C00),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Lightning Address ──────────────────────────────────────────
            _buildLabel('ໃສ່ Lightning Address ຫຼື Invoice'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 15),
              decoration:
                  _inputDecoration(
                    hint: 'user@wallet.com ຫຼື lnbc...',
                    icon: Icons.bolt,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: Color(0xFFFF8C00),
                      ),
                      tooltip: 'ສະແກນ QR',
                      onPressed: _scanQR,
                    ),
                  ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'ກະລຸນາໃສ່ Lightning Address ຫຼື Invoice';
                }
                final clean = v.trim();
                final isAddr = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                ).hasMatch(clean);
                final isInvoice = clean.toLowerCase().startsWith('lnbc');
                final isLNURL = clean.toUpperCase().startsWith('LNURL');
                if (!isAddr && !isInvoice && !isLNURL) {
                  return 'Address ຫຼື Invoice ບໍ່ຖືກຕ້ອງ';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Amount LAK ─────────────────────────────────────────────────
            _buildLabel('Enter Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountLAKController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8C00),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _onAmountChanged,
              decoration: _inputDecoration(hint: '0', suffix: 'LAK'),
              validator: (v) {
                final val = double.tryParse(v?.replaceAll(',', '') ?? '') ?? 0;
                if (val <= 0) {
                  return 'ກະລຸນາໃສ່ຈຳນວນ';
                }
                if (val > widget.balanceLAK) {
                  return 'ຍອດບໍ່ພໍ';
                }
                return null;
              },
            ),

            // ── Sats preview ───────────────────────────────────────────────
            if (_previewSats != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  'Sats ${_numberFormat.format(_previewSats!.round())}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),

            // ── Error ──────────────────────────────────────────────────────
            if (_previewError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade400,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _previewError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 36),
            Center(
              child: Icon(Icons.bolt, color: const Color(0xFFFF8C00), size: 48),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // ── Bottom Button ─────────────────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 12,
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _onWithdraw,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              disabledBackgroundColor: const Color(0xFFFFCC80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'ຖອນເງິນ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFFFF8C00),
    ),
  );

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    String? suffix,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
    suffixText: suffix,
    suffixStyle: const TextStyle(
      color: Color(0xFFFF8C00),
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
    prefixIcon: icon != null
        ? Icon(icon, color: const Color(0xFFFF8C00), size: 20)
        : null,
    filled: true,
    fillColor: const Color(0xFFFAFAFA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade300),
    ),
  );
}

// ─── Helper: format destination ──────────────────────────────────────────────
// Lightning Address → user@domain.com
// BOLT11 invoice   → lnbc1234...abcd
// LNURL            → LNURL Payment
String _fmtDest(String dest) {
  if (dest.isEmpty) return 'Lightning Network';
  // Lightning Address (user@domain.com) — readable ຢູ່ແລ້ວ
  if (dest.contains('@') && !dest.toLowerCase().startsWith('lnbc')) return dest;
  // LNURL
  if (dest.toUpperCase().startsWith('LNURL')) return 'LNURL Payment';
  // BOLT11 invoice — truncate
  if (dest.toLowerCase().startsWith('lnbc') && dest.length > 20) {
    return '${dest.substring(0, 12)}...${dest.substring(dest.length - 8)}';
  }
  // fallback truncate
  if (dest.length > 30) {
    return '${dest.substring(0, 15)}...${dest.substring(dest.length - 8)}';
  }
  return dest;
}

// ═════════════════════════════════════════════════════════════════════════════
// Confirm Bottom Sheet
// ═════════════════════════════════════════════════════════════════════════════
class _ConfirmBottomSheet extends StatelessWidget {
  final WithdrawalPreviewModel preview;
  const _ConfirmBottomSheet({required this.preview});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'en_US');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ຢືນຢັນການຖອນ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _row(
            'ຈໍານວນ',
            '${fmt.format(preview.amountLAK)} LAK\nSats ${fmt.format(preview.amountSats)}',
          ),
          const Divider(height: 24),
          _row('ຖອນຫາບັນຊີ', _fmtDest(preview.destination), small: true),
          const Divider(height: 24),
          _row('ຄ່າທຳນຽມ', '${fmt.format(preview.estimatedFeeSats)} sats'),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ຍົກເລີກ',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ຢືນຢັນ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool small = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
      const SizedBox(width: 16),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: small ? 13 : 15,
          ),
        ),
      ),
    ],
  );
}
