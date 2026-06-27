
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/providers.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';



class BonusScreen extends ConsumerWidget {
  const BonusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    final histAsync = ref.watch(bonusHistoryProvider);

    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Bonus & Cashback')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
        error: (e, _) => Center(child: Text('Erreur')),
        data: (user) => ListView(padding: const EdgeInsets.all(16), children: [
          // Balance card
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: EgcColors.ok, borderRadius: EgcRadius.lgBorder),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Solde disponible', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              const SizedBox(height: 6),
              Text(fmtPrice(user?.bonus ?? 0), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              const SizedBox(height: 14),
              Row(children: [
                _stat('Total gagné', fmtPrice(user?.totalEarnings ?? 0)),
                const SizedBox(width: 20),
                _stat('Cashbacks', fmtPrice(user?.cashbacks ?? 0)),
              ]),
            ])),
          const SizedBox(height: 12),
          // Quick actions
          Row(children: [
            Expanded(child: _actionCard('🔗', 'Parrainer', 'Gagner 1 000 F', () => context.push('/referral'))),
            const SizedBox(width: 10),
            Expanded(child: _actionCard('💸', 'Retirer', 'Transférer mes gains', () => context.push('/withdrawal'))),
          ]),
          const SizedBox(height: 16),
          // Comment gagner
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Comment gagner du bonus', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
              const SizedBox(height: 12),
              _howRow('🛒', 'Achat validé', 'Cashback automatique', 'Variable'),
              _howRow('🔗', 'Parrainage accepté', 'Par ami inscrit', '+1 000 F'),
              _howRow('🎁', 'Bonus bienvenue', 'A l inscription', '+500 F'),
            ])),
          const SizedBox(height: 16),
          // Historique
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Historique', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
              const SizedBox(height: 10),
              histAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
                error: (_, __) => const Text('Erreur chargement'),
                data: (hist) => hist.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune transaction', style: TextStyle(color: EgcColors.ink3))))
                  : Column(children: hist.map((h) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Container(width: 38, height: 38, decoration: BoxDecoration(color: h.isPositive ? EgcColors.okBg : EgcColors.errBg, borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(h.emoji, style: const TextStyle(fontSize: 18)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(h.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EgcColors.ink), overflow: TextOverflow.ellipsis),
                        Text(fmtDate(h.createdAt), style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                      ])),
                      Text('${h.isPositive ? '+' : ''}${fmtPrice(h.amount)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: h.isPositive ? EgcColors.ok : EgcColors.err)),
                    ]))).toList()),
              ),
            ])),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _stat(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
    Text(l, style: const TextStyle(fontSize: 11, color: Colors.white60)),
  ]);

  Widget _actionCard(String icon, String title, String sub, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 24)), const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
        Text(sub, style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
      ])));

  Widget _howRow(String icon, String title, String sub, String amount) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EgcColors.ink)),
        Text(sub, style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.pill),
        child: Text(amount, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EgcColors.ok))),
    ]));
}
