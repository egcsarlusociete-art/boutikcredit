
import 'package:flutter/material.dart';
import '../../services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../models/credit_category.dart' as cc;
import '../../utils/helpers.dart';
import '../bonus/bonus_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Mon profil')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
        error: (e,_) => Center(child: Text('Erreur: $e')),
        data: (user) => ListView(children: [
          // Profile header
          Container(color: EgcColors.bg2, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 32, backgroundColor: EgcColors.primary,
              child: Text(user?.initials ?? 'C', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white))),
            const SizedBox(height: 12),
            Text(user?.name ?? '—', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.4)),
            const SizedBox(height: 2),
            Text(user?.email ?? '—', style: const TextStyle(fontSize: 13, color: EgcColors.ink3)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.pill, border: Border.all(color: EgcColors.primaryMid)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(user?.isSeller == true ? Icons.store : Icons.person, size: 12, color: EgcColors.primary),
                const SizedBox(width: 4),
                Text('Plan ${user?.isSeller == true ? 'Vendeur' : 'Client'} · ${user?.planStatus == 'active' ? 'Actif' : 'En attente'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EgcColors.primary)),
              ])),
            const SizedBox(height: 16),
            Row(children: [
              _stat(user?.totalOrders.toString() ?? '0', 'Commandes'),
              _div(), _stat(user?.totalReferrals.toString() ?? '0', 'Parrainages'),
              _div(), _stat(fmtPrice(user?.totalEarnings ?? 0), 'Gagnés'),
            ]),
          ])),
          const SizedBox(height: 8),
          // Menu
          Container(color: EgcColors.bg2, child: Column(children: [
            _menuItem(Icons.inventory_2_outlined, 'Mes commandes', 'Suivi en temps réel', () => context.go('/orders')),
            _menuItem(Icons.workspace_premium_outlined, 'Bonus & Cashback', 'Gérer mes gains', () => context.go('/bonus')),
            _menuItem(Icons.people_outline, 'Parrainage', 'Inviter des amis', () => context.push('/referral')),
            _menuItem(Icons.account_balance_wallet_outlined, 'Retrait', 'Transférer mes gains', () => context.push('/withdrawal')),
            if (user?.isSeller == true)
              _menuItem(Icons.store_outlined, 'Espace Vendeur', 'Gérer mes articles', () => context.push('/vendor'), highlight: true),
            if (user?.uid == '9D76f2HLPrNODPN8HtPDbzwG4wA3')
              _menuItem(Icons.admin_panel_settings_outlined, 'Espace Admin', 'Gérer articles, commandes, retraits', () => context.push('/admin'), highlight: true),
            _menuItem(Icons.swap_vert_outlined, 'Changer de catégorie', 'Modifier votre plafond de crédit — 1 000 FCFA', () => _showChangeCat(context, user)),
            _menuItem(Icons.description_outlined, 'Conditions Générales', 'CGV et modalités de crédit', () => context.push('/cgv')),
            _menuItem(Icons.headset_mic_outlined, 'Support client 24h/24', 'WhatsApp & Email', () {
              if (user == null) {
                launchUrl(Uri.parse('https://wa.me/2250152372300?text=Bonjour+EGC-SARLU'));
                return;
              }
              final cat = cc.kCategories.firstWhere((c) => c.id == (user.creditCat ?? 'A'), orElse: () => cc.kCategories.first);
              final msg = Uri.encodeComponent(
                'Bonjour EGC-SARLU,\n\n'
                '👤 *INFORMATIONS CLIENT*\n'
                '• Nom : ${user.name}\n'
                '• Email : ${user.email}\n'
                '• Téléphone : ${user.phone}\n'
                '• Ville : ${user.city}\n\n'
                '💳 *COMPTE*\n'
                '• Catégorie : Cat. ${user.creditCat ?? 'A'} — Plafond ${fmtPrice(cat.plafond)}\n'
                '• Plan : ${user.plan == 'seller' ? 'Vendeur' : 'Client'}\n'
                '• Statut : ${user.planStatus == 'active' ? 'Actif' : user.planStatus == 'pending' ? 'En attente' : 'Inactif'}\n'
                '• Code parrainage : ${user.referralCode}\n'
                '• Création : ${fmtDate(user.createdAt)}\n\n'
                '📋 *MON PROBLÈME*\n'
                '[Décrivez votre problème ici]'
              );
              launchUrl(Uri.parse('https://wa.me/2250152372300?text=${msg}'));
            }),
            _menuItem(Icons.delete_forever_outlined, 'Supprimer mon compte', 'Action irréversible', () async {
              final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
                title: const Text('Supprimer le compte'),
                content: const Text('Cette action est irréversible. Toutes vos données seront supprimées. Voulez-vous continuer ?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Supprimer', style: TextStyle(color: EgcColors.err))),
                ],
              ));
              if (ok == true) {
                try {
                  final uid = AuthService().uid;
                  if (uid != null) {
                    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                  }
                  await AuthService().signOut();
                  if (context.mounted) showSnack(context, 'Compte supprimé avec succès');
                } catch (e) {
                  if (context.mounted) showSnack(context, 'Erreur : reconnectez-vous et réessayez', isError: true);
                }
              }
            }, textColor: EgcColors.err),
            _menuItem(Icons.logout, 'Déconnexion', 'Fermer la session', () async {
              final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
                title: const Text('Déconnexion'), content: const Text('Voulez-vous vous déconnecter ?'),
                actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Déconnexion'))],
              ));
              if (ok == true) {
                await AuthService().signOut();
              }
            }, textColor: EgcColors.err),
          ])),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _stat(String v, String l) => Expanded(child: Column(children: [
    Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.3), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
    Text(l, style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
  ]));

  Widget _div() => Container(width: 1, height: 32, color: EgcColors.line, margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _menuItem(IconData icon, String title, String sub, VoidCallback onTap, {Color? textColor, bool highlight = false}) =>
    InkWell(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: EgcColors.line))),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: highlight ? EgcColors.primaryBg : EgcColors.bg3, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: highlight ? EgcColors.primary : textColor ?? EgcColors.ink2)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor ?? EgcColors.ink)),
          Text(sub, style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
        ])),
        Icon(Icons.chevron_right, size: 20, color: textColor ?? EgcColors.ink3),
      ])));

  void _showChangeCat(BuildContext context, user) {
    if (user == null) return;
    String selectedCat = user.creditCat ?? 'A';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: EgcRadius.lg)),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Changer de catégorie', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: EgcColors.ink)),
            const SizedBox(height: 4),
            const Text('Frais de changement : 1 000 FCFA', style: TextStyle(fontSize: 13, color: EgcColors.ink3)),
            const SizedBox(height: 16),
            // Catégorie actuelle
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.smBorder, border: Border.all(color: EgcColors.primaryMid)),
              child: Row(children: [
                const Text('📋 Catégorie actuelle : ', style: TextStyle(fontSize: 13, color: EgcColors.ink2)),
                Text('Cat. ${user.creditCat}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EgcColors.primary)),
              ])),
            const SizedBox(height: 16),
            const Text('Choisissez une nouvelle catégorie :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
            const SizedBox(height: 10),
            // Liste des catégories
            SizedBox(
              height: 200,
              child: ListView(children: cc.kCategories.where((c) => c.id != user.creditCat).map((cat) {
                final isSel = selectedCat == cat.id;
                return GestureDetector(
                  onTap: () => setS(() => selectedCat = cat.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSel ? EgcColors.primaryBg : EgcColors.bg2,
                      borderRadius: EgcRadius.smBorder,
                      border: Border.all(color: isSel ? EgcColors.primary : EgcColors.line, width: isSel ? 2 : 1.5),
                    ),
                    child: Row(children: [
                      Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: isSel ? EgcColors.primary : Colors.transparent, border: Border.all(color: isSel ? EgcColors.primary : EgcColors.line2, width: 1.5)),
                        child: isSel ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Catégorie ${cat.id} — Plafond ${fmtPrice(cat.plafond)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                        Text('Total : ${fmtPrice(cat.total)} · ${cat.dureeLabel}', style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                      ])),
                    ]),
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: EgcColors.goldBg, borderRadius: EgcRadius.smBorder, border: Border.all(color: EgcColors.gold.withOpacity(0.3))),
              child: const Text('⚠️ Le changement sera effectif après paiement des frais de 1 000 FCFA via Mobile Money. Notre équipe vous contactera dans les 24h.', style: TextStyle(fontSize: 12, color: EgcColors.gold, height: 1.5))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: selectedCat == user.creditCat ? null : () async {
                Navigator.pop(ctx);
                // Enregistrer la demande de changement
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;
                await FirebaseFirestore.instance.collection('cat_change_requests').add({
                  'userId': uid,
                  'userName': user.name,
                  'currentCat': user.creditCat,
                  'requestedCat': selectedCat,
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) showSnack(context, '✅ Demande envoyée ! Payez 1 000 FCFA et notre équipe traitera votre demande sous 24h');
              },
              child: Text('Demander le passage à Cat. $selectedCat — 1 000 FCFA'),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

}