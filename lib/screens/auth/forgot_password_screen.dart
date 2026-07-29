import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/egc_button.dart';
import '../../widgets/egc_text_field.dart';

const _serviceId  = 'service_boutikcredit';
const _templateId = 'template_xmzyglc';
const _publicKey  = 'b1vi-wJ-8Q3tWN3Kh';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  bool _loading = false;
  String _email = "";
  final _emailC = TextEditingController();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final _newPassC = TextEditingController();
  final _confirmPassC = TextEditingController();

  @override
  void dispose() {
    _emailC.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _newPassC.dispose();
    _confirmPassC.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailC.text.trim();
    if (email.isEmpty || !email.contains("@")) {
      showSnack(context, "Entrez une adresse email valide", isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      // Verification email via tentative de connexion
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: "CHECK_ONLY_FAKE_PASSWORD_123!");
      } on FirebaseAuthException catch (e) {
        if (e.code == "user-not-found") {
          showSnack(context, "Aucun compte associé à cet email", isError: true);
          setState(() => _loading = false);
          return;
        }
        // wrong-password = email existe, on continue
      }
      final otp = (1000 + Random().nextInt(9000)).toString();
      final expiry = DateTime.now().add(const Duration(minutes: 10));
      await FirebaseFirestore.instance.collection("otp_codes").doc(email).set({
        "code": otp,
        "email": email,
        "expiresAt": Timestamp.fromDate(expiry),
        "createdAt": FieldValue.serverTimestamp(),
        "used": false,
      });
      final res = await http.post(
        Uri.parse("https://api.emailjs.com/api/v1.0/email/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "service_id": _serviceId,
          "template_id": _templateId,
          "user_id": _publicKey,
          "template_params": {
            "user_name": email,
            "otp_code": otp,
            "to_email": email,
          },
        }),
      );
      if (res.statusCode == 200) {
        _email = email;
        setState(() { _step = 1; _loading = false; });
        showSnack(context, "Code envoyé à $email");
      } else {
        showSnack(context, "Erreur envoi email. Réessayez.", isError: true);
        setState(() => _loading = false);
      }
    } catch (e) {
      showSnack(context, "Erreur : ${e.toString()}", isError: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final entered = _otpControllers.map((c) => c.text).join();
    if (entered.length < 4) {
      showSnack(context, "Entrez les 4 chiffres du code", isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection("otp_codes").doc(_email).get();
      if (!doc.exists) {
        showSnack(context, "Code invalide", isError: true);
        setState(() => _loading = false);
        return;
      }
      final data = doc.data()!;
      final expiresAt = (data["expiresAt"] as Timestamp).toDate();
      final storedCode = data["code"] as String;
      final used = data["used"] as bool? ?? false;
      if (used) {
        showSnack(context, "Ce code a déjà été utilisé", isError: true);
        setState(() => _loading = false);
        return;
      }
      if (DateTime.now().isAfter(expiresAt)) {
        showSnack(context, "Code expiré. Recommencez.", isError: true);
        setState(() => _loading = false);
        return;
      }
      if (entered != storedCode) {
        showSnack(context, "Code incorrect", isError: true);
        setState(() => _loading = false);
        return;
      }
      setState(() { _step = 2; _loading = false; });
    } catch (e) {
      showSnack(context, "Erreur vérification", isError: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPassC.text.trim();
    final confirm = _confirmPassC.text.trim();
    if (newPass.length < 6) {
      showSnack(context, "Le mot de passe doit contenir au moins 6 caractères", isError: true);
      return;
    }
    if (newPass != confirm) {
      showSnack(context, "Les mots de passe ne correspondent pas", isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);
      await FirebaseFirestore.instance
          .collection("otp_codes").doc(_email).update({"used": true});
      await http.post(
        Uri.parse("https://api.emailjs.com/api/v1.0/email/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "service_id": _serviceId,
          "template_id": _templateId,
          "user_id": _publicKey,
          "template_params": {
            "user_name": _email,
            "otp_code": "Votre mot de passe a été réinitialisé. Un lien vous a été envoyé pour finaliser.",
            "to_email": _email,
          },
        }),
      );
      if (mounted) {
        showSnack(context, "Un lien de réinitialisation a été envoyé à $_email");
        Navigator.pop(context);
      }
    } catch (e) {
      showSnack(context, "Erreur : ${e.toString()}", isError: true);
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.bg2,
      appBar: AppBar(
        title: const Text("Mot de passe oublié"),
        backgroundColor: EgcColors.bg2,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: List.generate(3, (i) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: i <= _step ? EgcColors.primary : EgcColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ))),
            const SizedBox(height: 32),
            if (_step == 0) ...[
              const Text("Réinitialiser le mot de passe",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EgcColors.ink)),
              const SizedBox(height: 8),
              const Text("Entrez votre adresse email. Nous vous enverrons un code de sécurité.",
                style: TextStyle(fontSize: 14, color: EgcColors.ink3)),
              const SizedBox(height: 32),
              EgcTextField(label: "Adresse email", hint: "votre@email.com",
                controller: _emailC, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 24),
              EgcButton(label: "Envoyer le code", onTap: _sendOtp,
                loading: _loading, icon: Icons.send_rounded),
            ],
            if (_step == 1) ...[
              const Text("Vérification",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EgcColors.ink)),
              const SizedBox(height: 8),
              Text("Entrez le code à 4 chiffres envoyé à $_email",
                style: const TextStyle(fontSize: 14, color: EgcColors.ink3)),
              const SizedBox(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(4, (i) =>
                SizedBox(
                  width: 64, height: 72,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _otpFocusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: EgcColors.ink),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: EgcColors.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: EgcColors.line, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: EgcColors.primary, width: 2),
                      ),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 3) _otpFocusNodes[i + 1].requestFocus();
                      if (val.isEmpty && i > 0) _otpFocusNodes[i - 1].requestFocus();
                    },
                  ),
                ),
              )),
              const SizedBox(height: 32),
              EgcButton(label: "Vérifier le code", onTap: _verifyOtp,
                loading: _loading, icon: Icons.check_circle_rounded),
              const SizedBox(height: 16),
              Center(child: TextButton(
                onPressed: _loading ? null : () => setState(() => _step = 0),
                child: const Text("Renvoyer le code",
                  style: TextStyle(color: EgcColors.primary)),
              )),
            ],
            if (_step == 2) ...[
              const Text("Nouveau mot de passe",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EgcColors.ink)),
              const SizedBox(height: 8),
              const Text("Créez un nouveau mot de passe sécurisé pour votre compte.",
                style: TextStyle(fontSize: 14, color: EgcColors.ink3)),
              const SizedBox(height: 32),
              EgcTextField(label: "Nouveau mot de passe", hint: "••••••••",
                controller: _newPassC, obscure: true),
              const SizedBox(height: 14),
              EgcTextField(label: "Confirmer le mot de passe", hint: "••••••••",
                controller: _confirmPassC, obscure: true),
              const SizedBox(height: 24),
              EgcButton(label: "Réinitialiser le mot de passe", onTap: _resetPassword,
                loading: _loading, icon: Icons.lock_reset_rounded),
            ],
          ]),
        ),
      ),
    );
  }
}
