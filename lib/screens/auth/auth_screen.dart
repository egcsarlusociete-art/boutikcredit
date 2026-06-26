
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/providers.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with TickerProviderStateMixin {
  late TabController _tab;
  final _loginForm = GlobalKey<FormState>();
  final _regForm   = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;
  String _plan = 'client';

  final _email = TextEditingController();
  final _pw    = TextEditingController();
  final _rName = TextEditingController();
  final _rPhone= TextEditingController();
  final _rEmail= TextEditingController();
  final _rPw   = TextEditingController();
  String? _rCity;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [_email, _pw, _rName, _rPhone, _rEmail, _rPw]) c.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginForm.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signIn(_email.text, _pw.text);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) showSnack(context, _authError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (!_regForm.currentState!.validate()) return;
    if (_rCity == null) { showSnack(context, 'Choisissez votre ville', isError: true); return; }
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).register(
        email: _rEmail.text, password: _rPw.text,
        name: _rName.text, phone: _rPhone.text, city: _rCity!, plan: _plan,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) showSnack(context, _authError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(String e) {
    if (e.contains('invalid-credential') || e.contains('wrong-password')) return 'Email ou mot de passe incorrect';
    if (e.contains('email-already-in-use')) return 'Email déjà utilisé';
    if (e.contains('weak-password')) return 'Mot de passe trop simple';
    if (e.contains('network')) return 'Problème de connexion réseau';
    return 'Erreur. Réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.bg2,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(children: [
              const EgcLogo(size: 52),
              const SizedBox(height: 14),
              const Text('EGC-SARLU', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('Marketplace premium · Cashback garanti', style: TextStyle(fontSize: 13, color: EgcColors.ink3)),
              const SizedBox(height: 24),
              // Tabs
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: EgcColors.bg3, borderRadius: EgcRadius.mdBorder),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.smBorder, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 4)]),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: EgcColors.primary,
                  unselectedLabelColor: EgcColors.ink3,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'Connexion'), Tab(text: 'S\'inscrire')],
                ),
              ),
            ]),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_buildLogin(), _buildRegister()],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLogin() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Form(
      key: _loginForm,
      child: Column(children: [
        EgcTextField(label: 'Email', hint: 'votre@email.com', controller: _email, keyboardType: TextInputType.emailAddress, validator: validateEmail),
        const SizedBox(height: 14),
        EgcTextField(
          label: 'Mot de passe', hint: '••••••••', controller: _pw,
          obscure: _obscure, action: TextInputAction.done,
          validator: validatePassword,
          suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
        ),
        const SizedBox(height: 24),
        EgcButton(label: 'Se connecter', onTap: _login, loading: _loading, icon: Icons.login_rounded),
        const SizedBox(height: 32),
      ]),
    ),
  );

  Widget _buildRegister() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Form(
      key: _regForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Choisissez votre abonnement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
        const SizedBox(height: 10),
        _planTile('client', 'Client Standard', 'Cashback · Livraison gratuite · Sans apport', '3 500'),
        const SizedBox(height: 8),
        _planTile('seller', 'Vendeur', 'Espace vendeur · 1 000 articles · Expert', '5 500'),
        const SizedBox(height: 16),
        EgcTextField(label: 'Nom complet', hint: 'Prénom NOM', controller: _rName, validator: (v) => validateRequired(v, 'Le nom')),
        const SizedBox(height: 14),
        EgcTextField(label: 'Téléphone', hint: '07XXXXXXXX', controller: _rPhone, keyboardType: TextInputType.phone, validator: validatePhone),
        const SizedBox(height: 14),
        EgcDropdown(
          label: 'Ville',
          value: _rCity,
          items: kCities.map((c) => {'value': c, 'label': c}).toList(),
          onChanged: (v) => setState(() => _rCity = v),
        ),
        const SizedBox(height: 14),
        EgcTextField(label: 'Email', hint: 'votre@email.com', controller: _rEmail, keyboardType: TextInputType.emailAddress, validator: validateEmail),
        const SizedBox(height: 14),
        EgcTextField(label: 'Mot de passe', hint: 'Min. 6 caractères', controller: _rPw, obscure: true, action: TextInputAction.done, validator: validatePassword),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: EgcColors.goldBg, borderRadius: EgcRadius.smBorder, border: Border.all(color: EgcColors.goldBg)),
          child: const Text('⚠️ Votre compte sera activé après paiement. Vous recevrez une confirmation sous 24h.', style: TextStyle(fontSize: 12, color: EgcColors.gold)),
        ),
        const SizedBox(height: 20),
        EgcButton(label: 'Créer mon compte', onTap: _register, loading: _loading, icon: Icons.person_add_rounded),
        const SizedBox(height: 32),
      ]),
    ),
  );

  Widget _planTile(String value, String title, String subtitle, String price) {
    final selected = _plan == value;
    return GestureDetector(
      onTap: () => setState(() => _plan = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? EgcColors.primaryBg : EgcColors.bg2,
          borderRadius: EgcRadius.mdBorder,
          border: Border.all(color: selected ? EgcColors.primary : EgcColors.line, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: selected ? EgcColors.primary : Colors.transparent,
              border: Border.all(color: selected ? EgcColors.primary : EgcColors.line2, width: 1.5),
              shape: BoxShape.circle,
            ),
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: EgcColors.ink)),
            const Text('F CFA/an', style: TextStyle(fontSize: 10, color: EgcColors.ink3)),
          ]),
        ]),
      ),
    );
  }
}
