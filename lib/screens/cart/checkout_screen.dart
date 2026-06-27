
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/egc_button.dart';
import '../../widgets/egc_text_field.dart';
import '../shop/shop_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _nameC  = TextEditingController();
  final _phoneC = TextEditingController();
  final _addrC  = TextEditingController();
  final _payNumC= TextEditingController();
  int _step = 0;
  String? _city;
  String _plan = 'daily';
  String? _operator;
  bool _loading = false;

  @override
  void dispose() { _nameC.dispose(); _phoneC.dispose(); _addrC.dispose(); _payNumC.dispose(); super.dispose(); }

  Future<void> _placeOrder() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final cart = ref.read(cartProvider);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final orderId = await FirestoreService().placeOrder(
        userId: uid,
        items: cart,
        delivery: DeliveryInfo(name: _nameC.text, phone: _phoneC.text, city: _city!, addr: _addrC.text),
        paymentPlan: _plan,
        paymentMethod: _operator!,
        paymentPhone: _payNumC.text,
      );
      ref.read(cartProvider.notifier).clear();
      if (mounted) context.go('/order-success?id=\$orderId');
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur : \$e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = cart.fold(0.0, (s, i) => s + i.total);
    final daily = (total / 100).ceil();
    final weekly = (total / 15).ceil();

    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Commander'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop())),
      body: Form(key: _form, child: Column(children: [
        // Stepper
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          _stepDot(0, 'Livraison'), _stepLine(0), _stepDot(1, 'Paiement'), _stepLine(1), _stepDot(2, 'Confirmation'),
        ])),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: _stepContent(total, daily, weekly))),
        // Bottom actions
        Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), decoration: const BoxDecoration(color: EgcColors.bg2, border: Border(top: BorderSide(color: EgcColors.line))),
          child: SafeArea(child: Column(children: [
            Row(children: [
              if (_step > 0) Expanded(flex: 1, child: Padding(padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(onPressed: () => setState(() => _step--),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                  child: const Icon(Icons.arrow_back)))),
              Expanded(flex: 3, child: EgcButton(
                label: _step < 2 ? 'Continuer' : 'Valider la commande',
                icon: _step < 2 ? Icons.arrow_forward : Icons.check_circle_outline,
                loading: _loading,
                onTap: () {
                  if (_step == 0) {
                    if (_form.currentState!.validate() && _city != null) setState(() => _step = 1);
                    else if (_city == null) showSnack(context, 'Choisissez une ville', isError: true);
                  } else if (_step == 1) {
                    if (_operator == null) { showSnack(context, 'Choisissez un opérateur', isError: true); return; }
                    if (_form.currentState!.validate()) setState(() => _step = 2);
                  } else {
                    _placeOrder();
                  }
                },
              )),
            ]),
            const SizedBox(height: 8),
          ]))),
      ])),
    );
  }

  Widget _stepContent(double total, int daily, int weekly) {
    if (_step == 0) return Column(children: [
      EgcTextField(label: 'Nom complet', controller: _nameC, validator: (v) => validateRequired(v, 'Le nom'), textInputAction: TextInputAction.next),
      const SizedBox(height: 14),
      EgcTextField(label: 'Téléphone', controller: _phoneC, keyboardType: TextInputType.phone, validator: validatePhone, textInputAction: TextInputAction.next),
      const SizedBox(height: 14),
      EgcDropdown<String>(label: 'Ville de livraison', value: _city, items: kCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _city = v)),
      const SizedBox(height: 14),
      EgcTextField(label: 'Adresse / Quartier', controller: _addrC, maxLines: 3, validator: (v) => validateRequired(v, 'L adresse')),
      const SizedBox(height: 20),
    ]);

    if (_step == 1) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: EgcColors.bg3, borderRadius: EgcRadius.mdBorder),
        child: Column(children: [
          _sumRow('Total commande', fmtPrice(total)),
          _sumRow('Livraison', 'Gratuite', color: EgcColors.ok),
          _sumRow('Paiement commence', 'À réception', color: EgcColors.blue),
        ])),
      const SizedBox(height: 16),
      const Text('Plan de remboursement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
      const SizedBox(height: 10),
      _planOpt('daily', 'Quotidien — 100 jours', '${fmtPrice(daily)} / jour'),
      const SizedBox(height: 8),
      _planOpt('weekly', 'Hebdomadaire — 15 semaines', '${fmtPrice(weekly)} / semaine'),
      const SizedBox(height: 16),
      const Text('Opérateur de paiement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
      const SizedBox(height: 10),
      ...kOperators.map((op) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _opOpt(op['value']!, op['emoji']!, op['label']!))),
      const SizedBox(height: 14),
      EgcTextField(label: 'Numéro de paiement', controller: _payNumC, keyboardType: TextInputType.phone, validator: validatePhone),
      const SizedBox(height: 20),
    ]);

    // Step 2 — Confirmation
    final cart = ref.read(cartProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('Articles', cart.map((i) => '${i.name} ×${i.qty}  →  ${fmtPrice(i.total)}').toList()),
      _section('Livraison', ['${_nameC.text}', '${_phoneC.text}', '\${_city ?? ''} — \${_addrC.text}']),
      _section('Paiement', ['${_plan == "daily" ? "Quotidien" : "Hebdomadaire"}', '${(_operator ?? '').toUpperCase()} — ${_payNumC.text}']),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.okLine)),
        child: const Text('✅  Livraison garantie sous 48h. Vous payez à réception.', style: TextStyle(fontSize: 13, color: EgcColors.ok, height: 1.5))),
      const SizedBox(height: 20),
    ]);
  }

  Widget _stepDot(int n, String label) => Column(children: [
    Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle,
      color: _step >= n ? EgcColors.primary : EgcColors.bg3,
      border: Border.all(color: _step >= n ? EgcColors.primary : EgcColors.line2, width: 1.5)),
      child: Center(child: _step > n ? const Icon(Icons.check, size: 13, color: Colors.white) : Text('${n+1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _step >= n ? Colors.white : EgcColors.ink3)))),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _step >= n ? EgcColors.primary : EgcColors.ink3)),
  ]);

  Widget _stepLine(int n) => Expanded(child: Container(height: 1.5, color: _step > n ? EgcColors.primary : EgcColors.line, margin: const EdgeInsets.only(bottom: 18)));

  Widget _planOpt(String val, String title, String sub) => GestureDetector(
    onTap: () => setState(() => _plan = val),
    child: Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _plan == val ? EgcColors.primaryBg : EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: _plan == val ? EgcColors.primary : EgcColors.line, width: 1.5)),
      child: Row(children: [
        Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: _plan == val ? EgcColors.primary : Colors.transparent, border: Border.all(color: _plan == val ? EgcColors.primary : EgcColors.line2, width: 1.5)),
          child: _plan == val ? const Icon(Icons.check, size: 11, color: Colors.white) : null),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
          Text(sub, style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
        ]),
      ])));

  Widget _opOpt(String val, String emoji, String label) => GestureDetector(
    onTap: () => setState(() => _operator = val),
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: _operator == val ? EgcColors.primaryBg : EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: _operator == val ? EgcColors.primary : EgcColors.line, width: 1.5)),
      child: Row(children: [
        Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: _operator == val ? EgcColors.primary : Colors.transparent, border: Border.all(color: _operator == val ? EgcColors.primary : EgcColors.line2, width: 1.5)),
          child: _operator == val ? const Icon(Icons.check, size: 11, color: Colors.white) : null),
        const SizedBox(width: 10),
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EgcColors.ink)),
      ])));

  Widget _sumRow(String l, String v, {Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(fontSize: 13, color: EgcColors.ink3)),
      Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? EgcColors.ink)),
    ]));

  Widget _section(String title, List<String> lines) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(border: Border.all(color: EgcColors.line, width: 1.5), borderRadius: EgcRadius.mdBorder),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: const BoxDecoration(color: EgcColors.bg3, borderRadius: BorderRadius.only(topLeft: EgcRadius.md, topRight: EgcRadius.md)),
        child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EgcColors.ink3, letterSpacing: 0.4))),
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((l) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(l, style: const TextStyle(fontSize: 13, color: EgcColors.ink2, height: 1.5)))).toList())),
    ]));
}
