
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/status_pill.dart';


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
            const SizedBox(height: 16),

            // Commandes concernant mes articles
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final myArticleIds = arts.map((a) => a.id).toSet();
                // Filtrer commandes contenant mes articles
                final myOrders = snap.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final items = (data['items'] as List?) ?? [];
                  return items.any((item) => myArticleIds.contains(item['articleId']));
                }).toList();
                final pending = myOrders.where((d) => (d.data() as Map)['status'] == 'confirmed').length;
                final processing = myOrders.where((d) => (d.data() as Map)['status'] == 'processing').length;
                final delivered = myOrders.where((d) => (d.data() as Map)['status'] == 'delivered').length;
                // ignore: unused_local_variable
                final cancelled = myOrders.where((d) => (d.data() as Map)['status'] == 'cancelled').length;

                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // KPIs commandes
                  GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
                    children: [
                      _kpi('🛍️', '${myOrders.length}', 'Total commandes'),
                      _kpi('⏳', '$pending', 'En attente'),
                      _kpi('📦', '$processing', 'En préparation'),
                      _kpi('✅', '$delivered', 'Livrées'),
                    ]),
                  const SizedBox(height: 14),

                  // Graphique ventes 6 derniers mois
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('📊 Ventes des 6 derniers mois', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EgcColors.ink)),
                      const SizedBox(height: 16),
                      Builder(builder: (_) {
                        final now = DateTime.now();
                        final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
                        final labels = months.map((m) => ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'][m.month-1]).toList();
                        final totals = months.map((m) => myOrders.where((doc) {
                          final d = doc.data() as Map;
                          final ts = d['createdAt'] as Timestamp?;
                          if (ts == null) return false;
                          final dt = ts.toDate();
                          return dt.year == m.year && dt.month == m.month && d['status'] != 'cancelled';
                        }).fold(0.0, (sum, doc) {
                          final its = ((doc.data() as Map)['items'] as List?) ?? [];
                          return sum + its.where((it) => myArticleIds.contains(it['articleId'])).fold(0.0, (s, it) => s + ((it['price']??0)*(it['qty']??1)).toDouble());
                        })).toList();
                        final maxVal = totals.isEmpty ? 1.0 : totals.reduce((a,b) => a>b?a:b);
                        return SizedBox(height: 100, child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(6, (i) {
                            final ratio = maxVal > 0 ? totals[i]/maxVal : 0.0;
                            final isCurrent = months[i].month == now.month;
                            return Expanded(child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                if (totals[i] > 0) Text(totals[i]>=1000 ? '${(totals[i]/1000).toStringAsFixed(0)}k' : totals[i].toStringAsFixed(0), style: const TextStyle(fontSize: 8, color: EgcColors.ink3)),
                                const SizedBox(height: 2),
                                Container(height: 70*ratio+4, decoration: BoxDecoration(color: isCurrent?EgcColors.primary:EgcColors.primaryMid, borderRadius: BorderRadius.circular(4))),
                                const SizedBox(height: 4),
                                Text(labels[i], style: TextStyle(fontSize: 9, color: isCurrent?EgcColors.primary:EgcColors.ink3, fontWeight: isCurrent?FontWeight.w800:FontWeight.w400)),
                              ]),
                            ));
                          }),
                        ));
                      }),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  // Liste commandes récentes (sans infos client)
                  if (myOrders.isNotEmpty) Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Commandes récentes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                      const SizedBox(height: 10),
                      ...myOrders.take(5).map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final items = (data['items'] as List?) ?? [];
                        final myItems = items.where((item) => myArticleIds.contains(item['articleId'])).toList();
                        final status = data['status'] ?? '';
                        final city = (data['delivery'] as Map?)?['city'] ?? 'N/A';
                        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: EgcColors.bg, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text('${myItems.length} article(s) commandé(s)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink))),
                              StatusPill(status, labels: kOrderStatus),
                            ]),
                            const SizedBox(height: 4),
                            ...myItems.take(3).map((item) => Text('• ${item['name'] ?? ''} × ${item['qty'] ?? 1}',
                              style: const TextStyle(fontSize: 12, color: EgcColors.ink2))),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: EgcColors.ink3),
                              const SizedBox(width: 4),
                              Text('Livraison vers : $city', style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                              const Spacer(),
                              if (createdAt != null) Text(fmtDate(createdAt), style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                            ]),
                          ]),
                        );
                      }),
                    ]),
                  ),
                ]);
              },
            ),
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
