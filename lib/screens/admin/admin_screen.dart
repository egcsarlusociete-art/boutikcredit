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
  void initState() { super.initState(); _tabs = TabController(length: 6, vsync: this); }
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
            Tab(text: 'Vendeurs'), Tab(text: 'Commandes'), Tab(text: 'Retraits'), Tab(text: 'Changement Statut')
          ]),
      ),
      body: TabBarView(controller: _tabs, children: [
        _articlesTab(), _imagesTab(), _vendeursTab(), _ordersTab(), _withdrawalsTab(), _catRequestsTab()
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
                const Spacer(),
                _deleteBtn(() async {
                  final ok = await _confirmDelete(context, a.name);
                  if (ok == true) {
                    await FirebaseFirestore.instance.collection('articles').doc(a.id).delete();
                    if (context.mounted) showSnack(context, 'Article supprime');
                  }
                }),
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
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (v.planStatus != 'active')
                  _aBtn('Activer', EgcColors.ok, () async {
                    await FirebaseFirestore.instance.collection('vendeurs').doc(v.uid).update({
                      'planStatus': 'active', 'activatedAt': FieldValue.serverTimestamp()
                    });
                    if (context.mounted) showSnack(context, 'Vendeur active');
                  }),
                const SizedBox(height: 6),
                _deleteBtn(() async {
                  final ok = await _confirmDelete(context, v.name);
                  if (ok == true) {
                    await FirebaseFirestore.instance.collection('vendeurs').doc(v.uid).delete();
                    if (context.mounted) showSnack(context, 'Vendeur supprime');
                  }
                }),
              ]),
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
                _clientInfoBtn(context, o.userId, o.orderId, o.subtotal, o.status),
                const SizedBox(height: 8),
                _buildOrderActions(o),
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerRight,
                child: _deleteBtn(() async {
                  final ok = await _confirmDelete(context, '#' + o.orderId);
                  if (ok == true) {
                    await FirebaseFirestore.instance.collection('orders').doc(o.id).delete();
                    if (context.mounted) showSnack(context, 'Commande supprimee');
                  }
                })),
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
              const SizedBox(height: 6),
              // Bouton voir filleuls
              GestureDetector(
                onTap: () async {
                  final snap = await FirebaseFirestore.instance
                      .collection('referrals')
                      .where('referrerId', isEqualTo: w.userId)
                      .get();
                  if (!context.mounted) return;
                  showDialog(context: context, builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: EgcRadius.mdBorder),
                    title: Row(children: [
                      const Icon(Icons.people_outline, color: EgcColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Filleuls de ' + w.userName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                    ]),
                    content: snap.docs.isEmpty
                      ? const Text('Aucun filleul pour ce compte.', style: TextStyle(color: EgcColors.ink3))
                      : SizedBox(width: double.maxFinite, child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: snap.docs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final r = snap.docs[i].data();
                            final name = r['name'] ?? 'Inconnu';
                            final date = (r['createdAt'] as Timestamp?)?.toDate();
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(r['referredId'] ?? '').get(),
                              builder: (_, userSnap) {
                                String statut = 'En attente';
                                if (userSnap.hasData && userSnap.data!.exists) {
                                  final d = userSnap.data!.data() as Map<String, dynamic>?;
                                  statut = d?['planStatus'] == 'active' ? 'Actif' : 'En attente';
                                }
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(radius: 16, backgroundColor: EgcColors.primaryBg,
                                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: EgcColors.primary))),
                                  title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  subtitle: date != null ? Text(fmtDate(date), style: const TextStyle(fontSize: 11)) : null,
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statut == 'Actif' ? EgcColors.okBg : EgcColors.primaryBg,
                                      borderRadius: EgcRadius.pill),
                                    child: Text(statut, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                      color: statut == 'Actif' ? EgcColors.ok : EgcColors.primary))),
                                );
                              },
                            );
                          },
                        )),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(_), child: const Text('Fermer')),
                    ],
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.pill, border: Border.all(color: EgcColors.primaryMid)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.people_outline, size: 14, color: EgcColors.primary),
                    const SizedBox(width: 4),
                    Text('Filleuls (' + w.userName + ')', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EgcColors.primary)),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                if (w.status == 'pending') ...[
                  _aBtn('Approuver', EgcColors.ok, () async {
                    await _fs.adminApproveWithdrawal(w.id);
                    if (context.mounted) showSnack(context, 'Retrait approuve');
                  }),
                  const SizedBox(width: 6),
                  _aBtn('Refuser', EgcColors.err, () async {
                    await _fs.adminRejectWithdrawal(w.id, w.userId, w.amount);
                    if (context.mounted) showSnack(context, 'Retrait refuse');
                  }),
                ],
                const Spacer(),
                _deleteBtn(() async {
                  final ok = await _confirmDelete(context, 'retrait de ' + w.userName);
                  if (ok == true) {
                    await FirebaseFirestore.instance.collection('withdrawals').doc(w.id).delete();
                    if (context.mounted) showSnack(context, 'Retrait supprime');
                  }
                }),
              ]),
            ]),
          );
        });
    });

  // ── HELPERS ──────────────────────────────────────────────────────
  Widget _buildOrderActions(OrderModel o) {
    if (o.status == 'delivered') return Container(
      margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.okLine)),
      child: const Row(children: [Text('Livree et receptionnee'), ]));
    if (o.status == 'cancelled') return Container(
      margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Color(0xFFFEE2E2), borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.err)),
      child: const Row(children: [Text('Commande annulee')]));
    final steps = ['confirmed','processing','shipped','delivered'];
    final labels = {'confirmed':'Confirmee','processing':'En preparation','shipped':'En livraison','delivered':'Livree'};
    final curIdx = steps.indexOf(o.status);
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      ...steps.map((s) {
        final sIdx = steps.indexOf(s);
        if (sIdx <= curIdx) return Padding(padding: const EdgeInsets.only(right: 6),
          child: ElevatedButton(onPressed: null,
            style: ElevatedButton.styleFrom(backgroundColor: EgcColors.bg3, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: EgcRadius.smBorder)),
            child: Text(labels[s] ?? s, style: const TextStyle(fontSize: 11, color: EgcColors.ink3))));
        return Padding(padding: const EdgeInsets.only(right: 6), child: _aBtn(labels[s] ?? s, statusColor(s), () => _fs.adminUpdateOrderStatus(o.id, s)));
      }),
      _aBtn('Annuler', EgcColors.err, () => _fs.adminUpdateOrderStatus(o.id, 'cancelled')),
    ]));
  }

  Widget _clientInfoBtn(BuildContext ctx, String userId, String orderId, double subtotal, String status) {
    return GestureDetector(
      onTap: () async {
        try {
          var snap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          if (!snap.exists) snap = await FirebaseFirestore.instance.collection('vendeurs').doc(userId).get();
          if (!snap.exists || !ctx.mounted) return;
          final d = snap.data() as Map<String, dynamic>;
          final nom = d['name'] ?? '';
          final email = d['email'] ?? '';
          final tel = d['phone'] ?? '';
          final ville = d['city'] ?? '';
          final plan = d['plan'] == 'seller' ? 'Vendeur' : 'Client';
          final statut = d['planStatus'] == 'active' ? 'Actif' : 'En attente';
          final cat = d['creditCat'] ?? 'A';
          final refCode = d['referralCode'] ?? '';
          final plafonds = {'A':'100 000','B':'200 000','C':'300 000','D':'400 000','E':'500 000','F':'600 000','G':'700 000','H':'800 000','I':'900 000','J':'1 000 000'};
          final montant = fmtPrice(subtotal);
          final statusLabel = kOrderStatus[status] ?? status;
          if (!ctx.mounted) return;
          showDialog(context: ctx, builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: EgcRadius.mdBorder),
            title: const Row(children: [Icon(Icons.person_outline, color: EgcColors.primary), SizedBox(width: 8), Text('Infos Client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
            content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              _infoRow('👤 Nom', nom),
              _infoRow('📧 Email', email),
              _infoRow('📞 Téléphone', tel),
              _infoRow('🏙️ Ville', ville),
              const Divider(height: 20),
              _infoRow('💳 Plan', plan),
              _infoRow('Categorie', 'Cat. ' + cat + ' - ' + (plafonds[cat] ?? '?') + ' F CFA'),
              _infoRow('✅ Statut', statut),
              _infoRow('🔗 Code parrain', refCode),
              const Divider(height: 20),
              _infoRow('Commande', '#' + orderId),
              _infoRow('💰 Montant', montant),
              _infoRow('🚚 Statut', statusLabel),
            ])),
            actions: [
              TextButton(onPressed: () => Navigator.pop(_), child: const Text('Fermer')),
            ],
          ));
        } catch (e) {
          if (ctx.mounted) showSnack(ctx, 'Erreur: \$e', isError: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.pill, border: Border.all(color: EgcColors.primaryMid)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person_outline, size: 14, color: EgcColors.primary),
          SizedBox(width: 4),
          Text('Infos client', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EgcColors.primary)),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: EgcColors.ink3))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EgcColors.ink))),
    ]),
  );

  Widget _deleteBtn(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: EgcRadius.pill, border: Border.all(color: EgcColors.err)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.delete_outline, size: 14, color: EgcColors.err),
        SizedBox(width: 4),
        Text('Supprimer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EgcColors.err)),
      ]),
    ),
  );

  Future<bool?> _confirmDelete(BuildContext ctx, String name) => showDialog<bool>(
    context: ctx,
    builder: (_) => AlertDialog(
      title: const Text('Confirmer la suppression'),
      content: Text('Supprimer "$name" ? Cette action est irreversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(_, true),
          child: const Text('Supprimer', style: TextStyle(color: EgcColors.err))),
      ],
    ),
  );

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

  // ── DEMANDES CHANGEMENT CATEGORIE ────────────────────────────────
  Widget _catRequestsTab() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('cat_change_requests')
        .orderBy('createdAt', descending: true).snapshots(),
    builder: (ctx, snap) {
      if (snap.hasError) return _errWidget(snap.error);
      if (!snap.hasData) return _loadingWidget();
      final docs = snap.data!.docs;
      if (docs.isEmpty) return _emptyWidget('Aucune demande de changement');

      return ListView.separated(
        padding: const EdgeInsets.all(12), itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final d = docs[i].data() as Map<String, dynamic>;
          final docId = docs[i].id;
          final status = d['status'] ?? 'pending';
          final userId = d['userId'] ?? '';
          final userName = d['userName'] ?? '';
          final currentCat = d['currentCat'] ?? '';
          final requestedCat = d['requestedCat'] ?? '';
          final isPending = status == 'pending';

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EgcColors.bg2,
              borderRadius: EgcRadius.mdBorder,
              border: Border.all(color: isPending ? EgcColors.primaryMid : EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 18, backgroundColor: EgcColors.primaryBg,
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: EgcColors.primary))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                  Text('Cat. $currentCat → Cat. $requestedCat',
                    style: const TextStyle(fontSize: 12, color: EgcColors.primary, fontWeight: FontWeight.w700)),
                  Text(fmtDate((d['createdAt'] as Timestamp?)?.toDate()), style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? EgcColors.primaryBg : status == 'approved' ? EgcColors.okBg : const Color(0xFFFEE2E2),
                    borderRadius: EgcRadius.pill),
                  child: Text(isPending ? 'En attente' : status == 'approved' ? 'Approuvée' : 'Refusée',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: isPending ? EgcColors.primary : status == 'approved' ? EgcColors.ok : EgcColors.err))),
              ]),
              if (!isPending)
                Align(alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirmer'),
                          content: Text('Supprimer la demande de ' + userName + ' (Cat. ' + currentCat + ' → Cat. ' + requestedCat + ') ?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Annuler')),
                            TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Supprimer', style: TextStyle(color: EgcColors.err))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance.collection('cat_change_requests').doc(docId).delete();
                        if (context.mounted) showSnack(context, 'Demande supprimee');
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 16, color: EgcColors.err),
                    label: const Text('Supprimer', style: TextStyle(fontSize: 12, color: EgcColors.err)),
                  )),
              if (isPending)
                Row(children: [
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      final userSnap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
                      final coll = userSnap.exists ? 'users' : 'vendeurs';
                      await FirebaseFirestore.instance.collection(coll).doc(userId).update({
                        'creditCat': requestedCat, 'updatedAt': FieldValue.serverTimestamp()
                      });
                      await FirebaseFirestore.instance.collection('cat_change_requests').doc(docId).update({
                        'status': 'approved', 'approvedAt': FieldValue.serverTimestamp()
                      });
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'userId': userId,
                        'type': 'cat_change',
                        'title': 'Categorie mise a jour',
                        'message': 'Votre demande de passage a Cat. ' + requestedCat + ' a ete approuvee !',
                        'read': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) showSnack(context, 'Categorie mise a jour pour ' + userName);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: EgcColors.ok),
                    child: const Text('Valider'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('cat_change_requests').doc(docId).update({'status': 'rejected', 'rejectedAt': FieldValue.serverTimestamp()});
                      if (context.mounted) showSnack(context, 'Demande refusee');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: EgcColors.err),
                    child: const Text('Refuser'),
                  )),
                ]),
            ]),
          );
        });
    });
}
