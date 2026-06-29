import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../services/providers.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/egc_text_field.dart';
import '../../widgets/status_pill.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../models/article_model.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _fs = FirestoreService();

  @override
  void initState() { super.initState(); _tabs = TabController(length: 5, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(
        title: const Text('Administration'),
        bottom: TabBar(
          controller: _tabs, isScrollable: true,
          labelColor: EgcColors.primary, unselectedLabelColor: EgcColors.ink3,
          indicatorColor: EgcColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Articles'), Tab(text: 'Images'),
            Tab(text: 'Vendeurs'), Tab(text: 'Commandes'), Tab(text: 'Retraits')
          ]),
      ),
      body: TabBarView(controller: _tabs, children: [
        _articlesTab(), _imagesTab(), _vendeursTab(), _ordersTab(), _withdrawalsTab()
      ]),
    );
  }

  // ── ARTICLES ──────────────────────────────────────────────────────
  Widget _articlesTab() => StreamBuilder<List<ArticleModel>>(
    stream: _fs.allArticles(),
    builder: (ctx, snap) {
      if (snap.hasError) return _errWidget(snap.error);
      if (!snap.hasData) return _loadingWidget();
      final articles = snap.data!;
      if (articles.isEmpty) return _emptyWidget('Aucun article');
      return ListView.separated(
        padding: const EdgeInsets.all(12), itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final a = articles[i];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink))),
                StatusPill(a.status, labels: kArticleStatus),
              ]),
              const SizedBox(height: 4),
              Text('${a.shopName} · ${kCategories[a.category] ?? a.category} · ${fmtPrice(a.price)}',
                style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
              if (a.rdvDate != null) Text('RDV : ${a.rdvDate} ${a.rdvSlot ?? ''}',
                style: const TextStyle(fontSize: 11, color: EgcColors.blue)),
              const SizedBox(height: 8),
              Row(children: [
                if (a.status != 'published') _aBtn('Publier', EgcColors.ok, () => _fs.adminUpdateArticle(a.id, {'status': 'published'})),
                const SizedBox(width: 6),
                if (a.status != 'rejected') _aBtn('Refuser', EgcColors.err, () => _fs.adminUpdateArticle(a.id, {'status': 'rejected'})),
              ]),
            ]),
          );
        });
    });

  // ── IMAGES ──────────────────────────────────────────────────────
  Widget _imagesTab() => StreamBuilder<List<ArticleModel>>(
    stream: _fs.allArticles(),
    builder: (ctx, snap) {
      if (snap.hasError) return _errWidget(snap.error);
      if (!snap.hasData) return _loadingWidget();
      final articles = snap.data!.where((a) => a.imageUrl == null || a.imageUrl!.isEmpty).toList();
      if (articles.isEmpty) return _emptyWidget('Tous les articles ont une image ✅');
      return ListView.separated(
        padding: const EdgeInsets.all(12), itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final a = articles[i];
          final ctrl = TextEditingController();
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text('${a.shopName} · ${fmtPrice(a.price)}', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
              const SizedBox(height: 8),
              EgcTextField(label: 'URL image', hint: 'https://...', controller: ctrl),
              const SizedBox(height: 8),
              _aBtn('Enregistrer image', EgcColors.primary, () async {
                if (ctrl.text.trim().isNotEmpty) {
                  await _fs.adminUpdateArticle(a.id, {'imageUrl': ctrl.text.trim(), 'status': 'published'});
                  if (context.mounted) showSnack(context, '✅ Image ajoutée');
                }
              }),
            ]),
          );
        });
    });

  // ── VENDEURS ──────────────────────────────────────────────────────
  Widget _vendeursTab() => StreamBuilder<List<UserModel>>(
    stream: _fs.allVendeurs(),
    builder: (ctx, snap) {
      if (snap.hasError) return _errWidget(snap.error);
      if (!snap.hasData) return _loadingWidget();
      final vendeurs = snap.data!;
      if (vendeurs.isEmpty) return _emptyWidget('Aucun vendeur');
      return ListView.separated(
        padding: const EdgeInsets.all(12), itemCount: vendeurs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final v = vendeurs[i];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Row(children: [
              CircleAvatar(radius: 20, backgroundColor: EgcColors.primaryMid,
                child: Text(v.name.isNotEmpty ? v.name[0].toUpperCase() : 'V',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: EgcColors.primary))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                Text('${v.email} · ${v.city}', style: const TextStyle(fontSize: 11, color: EgcColors.ink3), overflow: TextOverflow.ellipsis),
                StatusPill(v.planStatus, labels: {'pending': 'En attente', 'active': 'Actif', 'suspended': 'Suspendu'}),
              ])),
              if (v.planStatus != 'active')
                _aBtn('Activer', EgcColors.ok, () async {
                  await FirebaseFirestore.instance.collection('vendeurs').doc(v.uid).update({
                    'planStatus': 'active', 'activatedAt': FieldValue.serverTimestamp()
                  });
                  if (context.mounted) showSnack(context, '✅ Vendeur activé');
                }),
            ]),
          );
        });
    });

  // ── COMMANDES ──────────────────────────────────────────────────────
  Widget _ordersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) return _errWidget(snap.error);
        if (!snap.hasData) return _loadingWidget();
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _emptyWidget('Aucune commande');
        final orders = docs.map((d) => OrderModel.fromFirestore(d)).toList();
        orders.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        return ListView.separated(
          padding: const EdgeInsets.all(12), itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final o = orders[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('#${o.orderId.length > 14 ? o.orderId.substring(0, 14) : o.orderId}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                  const Spacer(),
                  StatusPill(o.status, labels: kOrderStatus),
                ]),
                const SizedBox(height: 4),
                Text('${o.delivery.name} · ${o.delivery.city} · ${fmtPrice(o.subtotal)}',
                  style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
                Text(fmtDate(o.createdAt), style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                const SizedBox(height: 6),
                // Bouton infos client
                GestureDetector(
                  onTap: () async {
                    // Chercher infos client dans users et vendeurs
                    try {
                      DocumentSnapshot? userDoc;
                      var snap = await FirebaseFirestore.instance.collection('users').doc(o.userId).get();
                      if (snap.exists) {
                        userDoc = snap;
                      } else {
                        snap = await FirebaseFirestore.instance.collection('vendeurs').doc(o.userId).get();
                        if (snap.exists) userDoc = snap;
                      }
                      if (userDoc != null && context.mounted) {
                        final d = userDoc.data() as Map<String, dynamic>;
                        final cat = d['creditCat'] ?? 'A';
                        final plafonds = {'A':'100 000','B':'200 000','C':'300 000','D':'400 000','E':'500 000','F':'600 000','G':'700 000','H':'800 000','I':'900 000','J':'1 000 000'};
                        final msg = Uri.encodeComponent(
                          'Bonjour EGC-SARLU,

'
                          '👤 *INFORMATIONS CLIENT*
'
                          '• Nom : \${d['name'] ?? ''}
'
                          '• Email : \${d['email'] ?? ''}
'
                          '• Téléphone : \${d['phone'] ?? ''}
'
                          '• Ville : \${d['city'] ?? ''}

'
                          '💳 *COMPTE*
'
                          '• Catégorie : Cat. \$cat — Plafond \${plafonds[cat] ?? '?'} F CFA
'
                          '• Plan : \${d['plan'] == 'seller' ? 'Vendeur' : 'Client'}
'
                          '• Statut : \${d['planStatus'] == 'active' ? 'Actif' : 'En attente'}
'
                          '• Code parrainage : \${d['referralCode'] ?? ''}

'
                          '📦 *COMMANDE*
'
                          '• Ref : #\${o.orderId}
'
                          '• Montant : \${fmtPrice(o.subtotal)}
'
                          '• Statut : \${kOrderStatus[o.status] ?? o.status}
'
                        );
                        await launchUrl(Uri.parse('https://wa.me/2250152372300?text=\$msg'));
                      }
                    } catch (e) {
                      if (context.mounted) showSnack(context, 'Erreur: \$e', isError: true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.pill, border: Border.all(color: EgcColors.primaryMid)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_outline, size: 14, color: EgcColors.primary),
                      SizedBox(width: 4),
                      Text('Infos client', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EgcColors.primary)),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                // Boutons statut
              if (o.status == 'delivered') ...[
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.okLine)),
                  child: const Row(children: [
                    Text('🎉', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(child: Text('Commande livrée et réceptionnée', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EgcColors.ok))),
                  ]),
                ),
              ] else if (o.status != 'cancelled') ...[
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                  // Boutons étapes précédentes grisés
                  ...['confirmed', 'processing', 'shipped', 'delivered'].map((s) {
                    final steps = ['confirmed', 'processing', 'shipped', 'delivered'];
                    final currentIdx = steps.indexOf(o.status);
                    final sIdx = steps.indexOf(s);
                    final isPast = sIdx < currentIdx;
                    final isCurrent = s == o.status;
                    final labels = {'confirmed': 'Confirmée', 'processing': 'En préparation', 'shipped': 'En livraison', 'delivered': 'Livrée'};
                    if (isPast || isCurrent) {
                      return Padding(padding: const EdgeInsets.only(right: 6),
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EgcColors.bg3,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: EgcRadius.smBorder)),
                          child: Text(labels[s] ?? s, style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
                        ));
                    }
                    if (s == 'cancelled') return const SizedBox.shrink();
                    return Padding(padding: const EdgeInsets.only(right: 6),
                      child: _aBtn(labels[s] ?? s, statusColor(s), () => _fs.adminUpdateOrderStatus(o.id, s)));
                  }).toList(),
                  // Bouton annuler toujours disponible
                  _aBtn('Annuler', EgcColors.err, () => _fs.adminUpdateOrderStatus(o.id, 'cancelled')),
                ])),
              ] else ...[
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.err)),
                  child: const Row(children: [
                    Text('❌', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(child: Text('Commande annulée', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EgcColors.err))),
                  ]),
                ),
              ],
              ]),
            );
          });
      });
  }

  // ── RETRAITS ──────────────────────────────────────────────────────
  Widget _withdrawalsTab() => StreamBuilder<List<WithdrawalModel>>(
    stream: _fs.allWithdrawals(),
    builder: (ctx, snap) {
      if (snap.hasError) return _errWidget(snap.error);
      if (!snap.hasData) return _loadingWidget();
      final withdrawals = snap.data!;
      if (withdrawals.isEmpty) return _emptyWidget('Aucun retrait');
      return ListView.separated(
        padding: const EdgeInsets.all(12), itemCount: withdrawals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final w = withdrawals[i];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(w.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink))),
                StatusPill(w.status, labels: {'pending': 'En attente', 'approved': 'Approuvé', 'rejected': 'Refusé'}),
              ]),
              Text('${w.method.toUpperCase()} — ${w.account}  ·  ${fmtPrice(w.amount)}',
                style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
              const SizedBox(height: 8),
              if (w.status == 'pending') Row(children: [
                _aBtn('Approuver', EgcColors.ok, () async {
                  await _fs.adminApproveWithdrawal(w.id);
                  if (context.mounted) showSnack(context, '✅ Retrait approuvé');
                }),
                const SizedBox(width: 6),
                _aBtn('Refuser', EgcColors.err, () async {
                  await _fs.adminRejectWithdrawal(w.id, w.userId, w.amount);
                  if (context.mounted) showSnack(context, 'Retrait refusé');
                }),
              ]),
            ]),
          );
        });
    });

  // ── HELPERS ──────────────────────────────────────────────────────
  Widget _loadingWidget() => const Center(child: CircularProgressIndicator(color: EgcColors.primary));
  
  Widget _errWidget(Object? error) => Center(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('❌', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text('Erreur : $error', style: const TextStyle(color: EgcColors.err), textAlign: TextAlign.center),
    ]),
  ));

  Widget _emptyWidget(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('📭', style: TextStyle(fontSize: 48)),
    const SizedBox(height: 12),
    Text(msg, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EgcColors.ink)),
  ]));

  Widget _aBtn(String label, Color color, VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: EgcRadius.smBorder)),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
  );
}
