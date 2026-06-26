import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/egc_button.dart';
import '../../widgets/egc_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC  = TextEditingController();
  bool _loading = false;
  final _auth = AuthService();

  @override
  void dispose() { _emailC.dispose(); _passC.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signIn(_emailC.text, _passC.text);
    } catch (e) {
      if (mounted) showSnack(context, _friendlyError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('invalid-credential') || e.contains('wrong-password')) return 'Email ou mot de passe incorrect';
    if (e.contains('user-not-found')) return 'Aucun compte avec cet email';
    if (e.contains('too-many-requests')) return 'Trop de tentatives, réessayez plus tard';
    return 'Erreur de connexion. Vérifiez vos identifiants.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.bg2,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Logo
              Center(child: Column(children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: EgcColors.primary, borderRadius: EgcRadius.mdBorder),
                  child: const Center(child: Text('E', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(height: 16),
                const Text('EGC-SARLU', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.4)),
                const SizedBox(height: 6),
                const Text('Connectez-vous à votre compte', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: EgcColors.ink3)),
              ])),
              const SizedBox(height: 36),

              EgcTextField(label: 'Email', hint: 'votre@email.com', controller: _emailC,
                keyboardType: TextInputType.emailAddress, validator: validateEmail,
                textInputAction: TextInputAction.next),
              const SizedBox(height: 14),
              EgcTextField(label: 'Mot de passe', hint: '••••••••', controller: _passC,
                obscure: true, validator: validatePassword,
                textInputAction: TextInputAction.done),
              const SizedBox(height: 24),

              EgcButton(label: 'Se connecter', onTap: _login, loading: _loading,
                icon: Icons.arrow_forward_rounded),
              const SizedBox(height: 16),

              Center(child: TextButton(
                onPressed: () {},
                child: const Text('Mot de passe oublié ?', style: TextStyle(color: EgcColors.primary, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(height: 32),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Pas encore de compte ? ", style: TextStyle(color: EgcColors.ink3, fontSize: 14)),
                GestureDetector(
                  onTap: () => context.go('/register'),
                  child: const Text("S'inscrire", style: TextStyle(color: EgcColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
