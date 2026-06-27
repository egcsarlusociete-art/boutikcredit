
import 'package:flutter/material.dart';
import '../../services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/status_pill.dart';
import '../bonus/bonus_screen.dart';


class VendorHomeScreen extends ConsumerWidget {
  const VendorHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    final artsAsync = ref.watch(vendorArticlesProvider);
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Espace Vendeur'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context))),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
        error: (_,__) => const Center(child: Text('Erreur')),
        data: (user) {
          final arts = artsAsync.valueOrNull ?? [];
          final published = arts.where((a) => a.status == 'published').length;
          final pending   = arts.where((a) => a.status == 'pending').length;
          return ListView(padding: const EdgeInsets.all(16), children: [
            // Statut abonnement
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
              color: user?.planStatus == 'active' ? EgcColors.okBg : EgcColors.goldBg,
              borderRadius: EgcRadius.mdBorder,
              border: Border.all(color: user?.planStatus == 'active' ? EgcColors.okLine : EgcColors.goldBg, width: 1.5)),
              child: Row(children: [
                Text(user?.planStatus == 'active' ? '✅' : '⏳', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.planStatus == 'active' ? 'Abonnement actif' : 'En attente d\'activation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: user?.planStatus == 'active' ? EgcColors.ok : EgcColors.gold)),
                  Text(user?.planStatus == 'active' ? 'Expire : ${user?.planExpiry?.substring(0,10) ?? '—'}' : 'Paiement de 5 500 F CFA requis',
                    style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
                ])),
              ])),
            const SizedBox(height: 14),
            // KPIs
            GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
              children: [
                _kpi('📦', '$published', 'Articles publiés'),
                _kpi('⏳', '$pending', 'En attente'),
                _kpi('🛒', '${arts.length}', 'Total articles'),
                _kpi('👁', '${arts.fold(0, (s, a) => s + a.views)}', 'Vues totales'),
              ]),
            const SizedBox(height: 14),
            // Actions
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => context.push('/vendor/add-article'),
                icon: const Icon(Icons.add, size: 18), label: const Text('Nouvel article'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: () => context.push('/vendor/articles'),
                icon: const Icon(Icons.list_alt, size: 18), label: const Text('Mes articles'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)))),
            ]),
            const SizedBox(height: 16),
            // Derniers articles
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Derniers articles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                const SizedBox(height: 10),
                if (arts.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucun article soumis', style: TextStyle(color: EgcColors.ink3)))),
                ...arts.take(5).map((a) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: EgcColors.bg3, borderRadius: BorderRadius.circular(8)),
                      child: a.hasImage ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(a.imageUrl!, fit: BoxFit.cover)) : const Center(child: Text('📦'))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EgcColors.ink), overflow: TextOverflow.ellipsis),
                      Text(fmtPrice(a.price), style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
                    ])),
                    StatusPill(a.status, labels: kArticleStatus),
                  ]))),
              ])),
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }
  Widget _kpi(String icon, String val, String label) => Container(padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 24)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: EgcColors.ink, letterSpacing: -0.4)),
        Text(label, style: const TextStyle(fontSize: 10, color: EgcColors.ink3)),
      ]),
    ]));
}
