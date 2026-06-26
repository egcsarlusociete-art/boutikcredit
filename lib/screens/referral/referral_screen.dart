
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../bonus/bonus_screen.dart';

final referralsProvider = StreamProvider((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return FirestoreService().userReferrals(uid);
});

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    final refAsync  = ref.watch(referralsProvider);
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Parrainage'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context))),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
        error: (e,_) => const Center(child: Text('Erreur')),
        data: (user) {
          final link = 'https://egcsarlu-app-b2ba4.web.app/?ref=${user?.uid ?? ''}';
          final referrals = refAsync.valueOrNull ?? [];
          return ListView(padding: const EdgeInsets.all(16), children: [
            // Hero
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: EgcColors.primary, borderRadius: EgcRadius.lgBorder),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Gagnez 1 000 F CFA par filleul', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                const SizedBox(height: 6),
                const Text('Chaque ami inscrit via votre lien vous rapporte un bonus immédiat.', style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5)),
                const SizedBox(height: 16),
                Row(children: [
                  _stat('${referrals.length}', 'Filleuls'),
                  const SizedBox(width: 24),
                  _stat(fmtPrice(referrals.length * 1000), 'Gagnés'),
                ]),
              ])),
            const SizedBox(height: 16),
            // Lien
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Votre lien de parrainage', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                const SizedBox(height: 10),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: EgcColors.bg3, borderRadius: EgcRadius.smBorder),
                  child: Row(children: [
                    Expanded(child: Text(link, style: const TextStyle(fontSize: 12, color: EgcColors.ink2), overflow: TextOverflow.ellipsis)),
                    GestureDetector(
                      onTap: () { Clipboard.setData(ClipboardData(text: link)); showSnack(context, 'Lien copié ✓'); },
                      child: const Text('Copier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EgcColors.primary))),
                  ])),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => Share.share('Rejoignez EGC-SARLU !\nMarketplace avec cashback & livraison gratuite.\n$link'),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Partager'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), minimumSize: const Size(0, 44)),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => Share.share(link),
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Autre app'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  )),
                ]),
              ])),
            const SizedBox(height: 16),
            // Liste filleuls
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Mes filleuls', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                const SizedBox(height: 10),
                if (referrals.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucun filleul pour l\'instant', style: TextStyle(color: EgcColors.ink3)))),
                ...referrals.map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    CircleAvatar(radius: 18, backgroundColor: EgcColors.primaryBg,
                      child: Text(r.name.isNotEmpty ? r.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.primary))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EgcColors.ink)),
                      Text(fmtDate(r.createdAt), style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.pill),
                      child: const Text('+1 000 F CFA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EgcColors.ok))),
                  ]))),
              ])),
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }
  Widget _stat(String v, String l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
    Text(l, style: const TextStyle(fontSize: 11, color: Colors.white60)),
  ]);
}
