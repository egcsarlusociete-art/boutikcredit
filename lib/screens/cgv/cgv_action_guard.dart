
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../cgv/cgv_screen.dart';
import '../auth/register_screen.dart';

/// Appelé AVANT toute action nécessitant un compte.
/// 1. Si pas connecté    → sheet "Créer un compte" (avec lecture CGV intégrée)
/// 2. Si connecté + CGV non signées → sheet CGV rapide
/// 3. Si connecté + CGV signées      → exécute l'action directement
Future<bool> requireAccountAndCgv(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  // ── Pas de compte : proposer inscription ────────────────────────
  if (user == null) {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GuestSheet(),
    );
    return result == true;
  }

  // ── Compte existant : vérifier CGV ──────────────────────────────
  final signed = await _hasSigned(user.uid);
  if (signed) return true;

  if (!context.mounted) return false;
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CgvSheet(),
  );
  return result == true;
}

Future<bool> _hasSigned(String uid) async {
  final db = FirebaseFirestore.instance;
  DocumentSnapshot snap = await db.collection('users').doc(uid).get();
  if (!snap.exists) snap = await db.collection('vendeurs').doc(uid).get();
  if (!snap.exists) return false;
  final data = snap.data() as Map<String, dynamic>?;
  return data?['cgvAccepted'] == true;
}

/// Sheet visiteur : invite à créer un compte
class _GuestSheet extends StatelessWidget {
  const _GuestSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EgcColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 36, height: 4, decoration: BoxDecoration(color: EgcColors.line2, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 20)),
        // Icône
        Container(width: 60, height: 60, decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Text('🔐', style: TextStyle(fontSize: 28)))),
        const SizedBox(height: 16),
        const Text('Créez votre compte EGC-SARLU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.4), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Pour commander, parrainer ou retirer vos gains, vous devez créer un compte et accepter nos Conditions Générales.',
          style: TextStyle(fontSize: 13, color: EgcColors.ink3, height: 1.6), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        // Avantages rapides
        _perk('🛒', 'Commandez à crédit', 'Cat A à J — jusqu\'à 1 000 000 FCFA'),
        _perk('💰', 'Cashback garanti', 'Sur chaque achat validé'),
        _perk('🔗', 'Parrainage', '500 FCFA par ami inscrit'),
        const SizedBox(height: 20),
        // Boutons
        SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
              final u = FirebaseAuth.instance.currentUser;
              if (u != null && context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Créer mon compte gratuitement'),
          )),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 44,
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer en visiteur', style: TextStyle(color: EgcColors.ink3)),
          )),
      ]),
    );
  }

  Widget _perk(String icon, String title, String sub) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
        Text(sub, style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
      ])),
    ]));
}

/// Sheet CGV rapide pour utilisateurs déjà connectés mais pas encore signataires
class _CgvSheet extends StatefulWidget {
  const _CgvSheet();
  @override
  State<_CgvSheet> createState() => _CgvSheetState();
}

class _CgvSheetState extends State<_CgvSheet> {
  bool _accepted = false;
  bool _signing = false;

  Future<void> _sign() async {
    if (!_accepted) return;
    setState(() => _signing = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;
      try {
        await db.collection('users').doc(uid).update({
          'cgvAccepted': true,
          'cgvSignedAt': FieldValue.serverTimestamp(),
          'cgvVersion': '1.0',
        });
      } catch (_) {
        await db.collection('vendeurs').doc(uid).update({
          'cgvAccepted': true,
          'cgvSignedAt': FieldValue.serverTimestamp(),
          'cgvVersion': '1.0',
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EgcColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(children: [
        // Handle + titre
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: EgcColors.line2, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 14)),
            Row(children: [
              const Expanded(child: Text('Conditions Générales', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.3))),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CgvScreen(isRequired: false))),
                child: const Text('Lire tout', style: TextStyle(fontSize: 12, color: EgcColors.primary)),
              ),
            ]),
            const Text('Pour effectuer cette action, vous devez accepter nos Conditions Générales.', style: TextStyle(fontSize: 12, color: EgcColors.ink3, height: 1.5)),
            const SizedBox(height: 12),
          ]),
        ),
        // Résumé CGV scrollable
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          _sumItem('📋', 'Modification de commande', 'Une seule modification possible après validation.'),
          _sumItem('💳', 'Paiement Mobile Money', 'Orange, MTN, Moov, Wave uniquement.'),
          _sumItem('📊', 'Catégories A à J', 'Plafond de 100 000 à 1 000 000 FCFA. Intérêt fixe 15 %.'),
          _sumItem('⚠️', 'Pénalités non-paiement', '50 % sur versements si retard de 2 semaines.'),
          _sumItem('🔒', 'Propriété des biens', 'Articles propriété EGC-SARLU jusqu\'au paiement total.'),
          _sumItem('⚖️', 'Droit ivoirien', 'Litiges soumis aux tribunaux d\'Abidjan.'),
          const SizedBox(height: 8),
        ])),
        // Zone acceptation
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: EgcColors.line))),
          child: SafeArea(child: Column(children: [
            GestureDetector(
              onTap: () => setState(() => _accepted = !_accepted),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20, height: 20, margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: _accepted ? EgcColors.primary : Colors.transparent,
                    border: Border.all(color: _accepted ? EgcColors.primary : EgcColors.line2, width: 1.5),
                    borderRadius: BorderRadius.circular(5)),
                  child: _accepted ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text(
                  'J\'ai lu et j\'accepte les Conditions Générales de Vente et d\'Utilisation à Crédit d\'EGC-SARLU.',
                  style: TextStyle(fontSize: 12, color: EgcColors.ink2, height: 1.5))),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: (_accepted && !_signing) ? _sign : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accepted ? EgcColors.ok : EgcColors.bg3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _signing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Signer et continuer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _accepted ? Colors.white : EgcColors.ink3)),
              )),
            const SizedBox(height: 6),
            TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(color: EgcColors.ink3, fontSize: 12))),
            const SizedBox(height: 4),
          ])),
        ),
      ]),
    );
  }

  Widget _sumItem(String icon, String title, String sub) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EgcColors.ink)),
        Text(sub, style: const TextStyle(fontSize: 11, color: EgcColors.ink3, height: 1.4)),
      ])),
    ]));
}
