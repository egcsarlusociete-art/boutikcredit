import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../models/credit_category.dart' as cc;
import '../../widgets/egc_button.dart';
import '../../widgets/egc_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form   = GlobalKey<FormState>();
  final _nameC  = TextEditingController();
  final _phoneC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC  = TextEditingController();
  final _refC      = TextEditingController();
  final _shopNameC = TextEditingController();
  final _locationC = TextEditingController();
  String _plan = 'client';
  String _creditCat = 'A';
  String? _city;
  bool _loading = false;
  final _auth = AuthService();

  @override
  void dispose() { _nameC.dispose(); _phoneC.dispose(); _emailC.dispose(); _passC.dispose(); _refC.dispose(); _shopNameC.dispose(); _locationC.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    if (_city == null) { showSnack(context, 'Choisissez votre ville', isError: true); return; }
    setState(() => _loading = true);
    try {
      await _auth.register(email: _emailC.text, password: _passC.text,
        name: _plan == 'seller' ? _shopNameC.text : _nameC.text,
        phone: _phoneC.text, city: _city!, plan: _plan, creditCat: _creditCat,
        referralCode: _refC.text.trim().toUpperCase(),
        shopName: _shopNameC.text.trim(),
        location: _locationC.text.trim());
    } catch (e) {
      if (mounted) showSnack(context, e.toString().contains('email-already-in-use') ? 'Email déjà utilisé' : 'Erreur : vérifiez vos informations', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.bg2,
      appBar: AppBar(title: const Text('Créer un compte'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.go('/login'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Image.asset('assets/images/logo_boutikcredit.png', height: 60)),
          const SizedBox(height: 16),
          // Plan choice
          const Text('Choisissez votre abonnement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
          const SizedBox(height: 10),
          _planCard('client', 'Client Standard', 'Commandes · Cashback · Livraison gratuite', '3 500 F CFA/an'),
          const SizedBox(height: 8),
          _planCard('seller', 'Vendeur', 'Espace vendeur · Jusqu\'à 1 000 articles · Expert', '5 500 F CFA/an'),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.smBorder, border: Border.all(color: EgcColors.primaryMid)),
            child: const Text('⚠️ Votre compte sera activé après réception du paiement. Un code vous sera envoyé sous 24h.', style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5))),
          const SizedBox(height: 16),
          // Catégorie de crédit (clients uniquement)
          if (_plan == 'client') ...[
            const Text('Choisissez votre catégorie de crédit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
            const SizedBox(height: 6),
            const Text('Détermine votre plafond maximum de commande', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: cc.kCategories.map((cat) {
                  final sel = _creditCat == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _creditCat = cat.id),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? EgcColors.primary : EgcColors.bg2,
                        border: Border.all(color: sel ? EgcColors.primary : EgcColors.line, width: 1.5),
                        borderRadius: EgcRadius.pill,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Cat. ${cat.id}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : EgcColors.ink)),
                        Text(fmtPrice(cat.plafond), style: TextStyle(fontSize: 9, color: sel ? Colors.white70 : EgcColors.ink3)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Résumé catégorie choisie
            Builder(builder: (_) {
              final cat = cc.kCategories.firstWhere((c) => c.id == _creditCat);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.smBorder, border: Border.all(color: EgcColors.okLine)),
                child: Row(children: [
                  const Text('✅ ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Plafond : ${fmtPrice(cat.plafond)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EgcColors.ok)),
                    Text('Total avec intérêts : ${fmtPrice(cat.total)} · Durée : ${cat.dureeLabel}', style: const TextStyle(fontSize: 11, color: EgcColors.ok)),
                  ])),
                ]),
              );
            }),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 4),
          // Champs spécifiques vendeur
          if (_plan == 'seller') ...[
            EgcTextField(label: 'Nom de la boutique', hint: 'Ex: Boutique Mode Abidjan', controller: _shopNameC,
              validator: (v) => validateRequired(v, 'Le nom de la boutique'), textInputAction: TextInputAction.next),
            const SizedBox(height: 14),
            EgcTextField(label: 'Localisation de la boutique', hint: 'Ville / Quartier / Adresse', controller: _locationC,
              validator: (v) => validateRequired(v, 'La localisation'), textInputAction: TextInputAction.next),
            const SizedBox(height: 14),
          ],
          EgcTextField(label: _plan == 'seller' ? 'Nom du gérant' : 'Nom complet', hint: 'Prénom NOM', controller: _nameC, validator: (v) => validateRequired(v, 'Le nom'), textInputAction: TextInputAction.next),
          const SizedBox(height: 14),
          EgcTextField(label: 'Téléphone', hint: '07XXXXXXXX', controller: _phoneC, keyboardType: TextInputType.phone, validator: validatePhone, textInputAction: TextInputAction.next),
          const SizedBox(height: 14),
          EgcDropdown<String>(
            label: 'Ville', value: _city,
            items: kCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _city = v),
            validator: (v) => v == null ? 'Choisissez une ville' : null,
          ),
          const SizedBox(height: 14),
          EgcTextField(label: 'Email', hint: 'votre@email.com', controller: _emailC, keyboardType: TextInputType.emailAddress, validator: validateEmail, textInputAction: TextInputAction.next),
          const SizedBox(height: 14),
          EgcTextField(label: 'Mot de passe', hint: '6 caractères minimum', controller: _passC, obscure: true, validator: validatePassword),
          const SizedBox(height: 14),
          EgcTextField(
            label: 'Code parrain (optionnel)',
            hint: 'Ex: EGCADMIN',
            controller: _refC,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          EgcButton(label: 'Créer mon compte', onTap: _register, loading: _loading, icon: Icons.person_add_outlined),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Déjà inscrit ? ', style: TextStyle(color: EgcColors.ink3, fontSize: 14)),
            GestureDetector(onTap: () => context.go('/login'),
              child: const Text('Se connecter', style: TextStyle(color: EgcColors.primary, fontWeight: FontWeight.w700, fontSize: 14))),
          ]),
          const SizedBox(height: 24),
        ])),
      ),
    );
  }

  Widget _planCard(String val, String title, String desc, String price) {
    final sel = _plan == val;
    return GestureDetector(
      onTap: () => setState(() => _plan = val),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? EgcColors.primaryBg : EgcColors.bg2,
          border: Border.all(color: sel ? EgcColors.primary : EgcColors.line, width: 1.5),
          borderRadius: EgcRadius.mdBorder,
        ),
        child: Row(children: [
          Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? EgcColors.primary : Colors.transparent, border: Border.all(color: sel ? EgcColors.primary : EgcColors.line2, width: 1.5)),
            child: sel ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(fontSize: 11, color: EgcColors.ink3, height: 1.4)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price.split('/')[0], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: EgcColors.ink)),
            Text('/${price.split('/')[1]}', style: const TextStyle(fontSize: 10, color: EgcColors.ink3)),
          ]),
        ]),
      ),
    );
  }
}
