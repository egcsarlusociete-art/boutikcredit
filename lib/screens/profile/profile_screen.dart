
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
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
            _menuItem(Icons.headset_mic_outlined, 'Support client 24h/24', 'WhatsApp & Email',
              () => launchUrl(Uri.parse('https://wa.me/2250152372300?text=Bonjour+EGC-SARLU'))),
            _menuItem(Icons.logout, 'Déconnexion', 'Fermer la session', () async {
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                title: const Text('Déconnexion'), content: const Text('Voulez-vous vous déconnecter ?'),
                actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Déconnexion'))],
              ));
              if (ok == true) await AuthService().signOut();
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
}
