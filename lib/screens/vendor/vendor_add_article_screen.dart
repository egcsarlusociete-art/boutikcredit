
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/egc_button.dart';
import '../../widgets/egc_text_field.dart';

class VendorAddArticleScreen extends ConsumerStatefulWidget {
  const VendorAddArticleScreen({super.key});
  @override
  ConsumerState<VendorAddArticleScreen> createState() => _VendorAddArticleScreenState();
}

class _VendorAddArticleScreenState extends ConsumerState<VendorAddArticleScreen> {
  final _form   = GlobalKey<FormState>();
  final _nameC  = TextEditingController();
  final _descC  = TextEditingController();
  final _priceC = TextEditingController();
  final _qtyC   = TextEditingController(text: '1');
  final _addrC  = TextEditingController();
  String? _category, _state, _rdvDate, _rdvSlot;
  bool _loading = false;

  final _slots = ['08h-10h', '10h-12h', '14h-16h', '16h-18h'];
  final _rdvDays = List.generate(14, (i) {
    final d = DateTime.now().add(Duration(days: i + 1));
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  });

  @override
  void dispose() { _nameC.dispose(); _descC.dispose(); _priceC.dispose(); _qtyC.dispose(); _addrC.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_category == null) { showSnack(context, 'Choisissez une catégorie', isError: true); return; }
    if (_state == null) { showSnack(context, 'Indiquez l\'état', isError: true); return; }
    if (_rdvDate == null || _rdvSlot == null) { showSnack(context, 'Réservez un créneau expert', isError: true); return; }
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userData = await AuthService().userStream(uid).first;
    try {
      await FirestoreService().submitArticle({
        'vendeurId': uid,
        'vendeurName': userData?.name ?? '',
        'shopName': userData?.name ?? '',
        'vendeurCity': userData?.city ?? '',
        'name': _nameC.text.trim(),
        'category': _category,
        'description': _descC.text.trim(),
        'state': _state,
        'price': double.parse(_priceC.text.replaceAll(' ', '')),
        'qty': int.parse(_qtyC.text),
        'rdvDate': _rdvDate,
        'rdvSlot': _rdvSlot,
        'address': _addrC.text.trim(),
        'cashback': 3,
      });
      if (mounted) { showSnack(context, 'Article soumis ! L\'expert vous contactera pour la prise de vue.'); Navigator.pop(context); }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Soumettre un article'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context))),
      body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(16), children: [
        _sectionTitle('Informations produit'),
        EgcTextField(label: 'Nom du produit *', controller: _nameC, validator: (v) => validateRequired(v, 'Le nom'), textInputAction: TextInputAction.next),
        const SizedBox(height: 14),
        EgcDropdown<String>(label: 'Catégorie *', value: _category,
          items: kCategories.entries.where((e) => e.key != 'all').map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _category = v),
          validator: (v) => v == null ? 'Choisissez une catégorie' : null),
        const SizedBox(height: 14),
        EgcDropdown<String>(label: 'État *', value: _state,
          items: kStates.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _state = v),
          validator: (v) => v == null ? 'Indiquez l\'état' : null),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: EgcTextField(label: 'Prix (F CFA) *', controller: _priceC, keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Prix requis' : null, textInputAction: TextInputAction.next)),
          const SizedBox(width: 10),
          Expanded(child: EgcTextField(label: 'Quantité *', controller: _qtyC, keyboardType: TextInputType.number, textInputAction: TextInputAction.next)),
        ]),
        const SizedBox(height: 14),
        EgcTextField(label: 'Description *', controller: _descC, maxLines: 4, validator: (v) => validateRequired(v, 'La description')),
        const SizedBox(height: 20),
        _sectionTitle('Rendez-vous Expert EGC'),
        Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.smBorder, border: Border.all(color: EgcColors.primaryMid)),
          child: const Text('📸 Un expert EGC viendra prendre les photos dans votre boutique. Les photos seront publiées sous 48h.', style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5))),
        EgcDropdown<String>(label: 'Date du RDV *', value: _rdvDate,
          items: _rdvDays.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => _rdvDate = v)),
        const SizedBox(height: 14),
        EgcDropdown<String>(label: 'Créneau *', value: _rdvSlot,
          items: _slots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _rdvSlot = v)),
        const SizedBox(height: 14),
        EgcTextField(label: 'Adresse de votre boutique *', controller: _addrC, maxLines: 2, validator: (v) => validateRequired(v, 'L\'adresse')),
        const SizedBox(height: 24),
        EgcButton(label: 'Soumettre l\'article', onTap: _submit, loading: _loading, icon: Icons.send_outlined),
        const SizedBox(height: 32),
      ])),
    );
  }
  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EgcColors.ink)));
}
