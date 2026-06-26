
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../models/user_model.dart';
import '../../widgets/egc_button.dart';
import '../../widgets/egc_text_field.dart';
import '../../widgets/status_pill.dart';
import '../bonus/bonus_screen.dart';

final withdrawalsProvider = StreamProvider((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return FirestoreService().userWithdrawals(uid);
});

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});
  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _amtC  = TextEditingController();
  final _accC  = TextEditingController();
  final _nameC = TextEditingController();
  String? _operator;
  bool _loading = false;

  @override
  void dispose() { _amtC.dispose(); _accC.dispose(); _nameC.dispose(); super.dispose(); }

  Future<void> _submit(UserModel? user) async {
    final amt = double.tryParse(_amtC.text.replaceAll(' ', '')) ?? 0;
    if (amt < 10000) { showSnack(context, 'Montant minimum : 10 000 F CFA', isError: true); return; }
    if (amt > (user?.bonus ?? 0)) { showSnack(context, 'Solde insuffisant', isError: true); return; }
    if (_operator == null) { showSnack(context, 'Choisissez un opérateur', isError: true); return; }
    if (_accC.text.isEmpty) { showSnack(context, 'Entrez votre numéro', isError: true); return; }
    if (_nameC.text.isEmpty) { showSnack(context, 'Entrez le nom du titulaire', isError: true); return; }
    setState(() => _loading = true);
    try {
      await FirestoreService().requestWithdrawal(
        userId: FirebaseAuth.instance.currentUser!.uid,
        userName: user?.name ?? '',
        amount: amt, method: _operator!,
        account: _accC.text, holderName: _nameC.text,
      );
      _amtC.clear(); _accC.clear(); _nameC.clear();
      setState(() => _operator = null);
      if (mounted) showSnack(context, 'Demande envoyée ✓ Traitement 24-48h');
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataProvider);
    final wdAsync   = ref.watch(withdrawalsProvider);
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Retrait'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context))),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
        error: (_,__) => const Center(child: Text('Erreur')),
        data: (user) => ListView(padding: const EdgeInsets.all(16), children: [
          // Balance
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: EgcColors.line, width: 1.5), borderRadius: EgcRadius.mdBorder),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Solde disponible', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EgcColors.ink3, letterSpacing: 0.4)),
              const SizedBox(height: 6),
              Text(fmtPrice(user?.bonus ?? 0), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.5)),
              const Text('Retrait minimum : 10 000 F CFA', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
            ])),
          const SizedBox(height: 16),
          // Form
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EgcTextField(label: 'Montant (F CFA)', controller: _amtC, keyboardType: TextInputType.number, hint: 'Ex : 15000', textInputAction: TextInputAction.next),
              const SizedBox(height: 14),
              const Text('Opérateur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EgcColors.ink2)),
              const SizedBox(height: 8),
              ...kOperators.map((op) => Padding(padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(onTap: () => setState(() => _operator = op['value']),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: _operator == op['value'] ? EgcColors.primaryBg : EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: _operator == op['value'] ? EgcColors.primary : EgcColors.line, width: 1.5)),
                    child: Row(children: [
                      Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, color: _operator == op['value'] ? EgcColors.primary : Colors.transparent, border: Border.all(color: _operator == op['value'] ? EgcColors.primary : EgcColors.line2, width: 1.5)),
                        child: _operator == op['value'] ? const Icon(Icons.check, size: 10, color: Colors.white) : null),
                      const SizedBox(width: 10),
                      Text(op['emoji']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(op['label']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EgcColors.ink)),
                    ]))))),
              const SizedBox(height: 6),
              EgcTextField(label: 'Numéro de paiement', controller: _accC, keyboardType: TextInputType.phone, hint: '07XXXXXXXX', textInputAction: TextInputAction.next),
              const SizedBox(height: 14),
              EgcTextField(label: 'Nom du titulaire', controller: _nameC, hint: 'Prénom NOM', textInputAction: TextInputAction.done),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.smBorder, border: Border.all(color: EgcColors.primaryMid)),
                child: const Text('⏱ Traitement sous 24 à 48h ouvrables.', style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5))),
              const SizedBox(height: 14),
              EgcButton(label: 'Envoyer la demande', onTap: () => _submit(user), loading: _loading, icon: Icons.send_outlined),
            ])),
          const SizedBox(height: 16),
          // Historique
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Historique', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
              const SizedBox(height: 10),
              wdAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
                error: (_,__) => const Text('Erreur'),
                data: (list) => list.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucun retrait', style: TextStyle(color: EgcColors.ink3))))
                  : Column(children: list.map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Container(width: 38, height: 38, decoration: BoxDecoration(color: EgcColors.errBg, borderRadius: BorderRadius.circular(10)),
                        child: const Center(child: Text('💸', style: TextStyle(fontSize: 18)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${w.method.toUpperCase()} — ${w.account}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EgcColors.ink)),
                        Text(fmtDate(w.createdAt), style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('-${fmtPrice(w.amount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EgcColors.err)),
                        StatusPill(w.status, labels: kWithdrawalStatus),
                      ]),
                    ]))).toList()),
              ),
            ])),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
