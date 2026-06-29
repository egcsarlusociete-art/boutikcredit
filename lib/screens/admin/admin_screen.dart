
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/egc_text_field.dart';
import '../../widgets/status_pill.dart';
import '../../models/order_model.dart';

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
        bottom: TabBar(controller: _tabs, isScrollable: true, labelColor: EgcColors.primary, unselectedLabelColor: EgcColors.ink3,
          indicatorColor: EgcColors.primary, labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: 'Articles'), Tab(text: 'Images'), Tab(text: 'Vendeurs'), Tab(text: 'Commandes'), Tab(text: 'Retraits')]),
      ),
      body: TabBarView(controller: _tabs, children: [_articlesTab(), _imagesTab(), _vendeursTab(), _ordersTab(), _withdrawalsTab()]),
    );
  }

  // ── ARTICLES ──────────────────────────────────────────────────────
  Widget _articlesTab() => StreamBuilder(
    stream: _fs.allArticles(),
    builder: (ctx, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: EgcColors.primary));
      final arts = snap.data!;
      return ListView.separated(padding: const EdgeInsets.all(12), itemCount: arts.length, separatorBuilder: (_,__) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final a = arts[i];
          return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink), overflow: TextOverflow.ellipsis)),
                StatusPill(a.status, labels: kArticleStatus),
              ]),
              const SizedBox(height: 4),
              Text('${a.shopName} · ${kCategories[a.category]} · ${fmtPrice(a.price)}', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
              if (a.rdvDate != null) Text('RDV : ${a.rdvDate} ${a.rdvSlot ?? ''}', style: const TextStyle(fontSize: 11, color: EgcColors.blue)),
              const SizedBox(height: 10),
              Row(children: [
                if (a.status != 'published') _aBtn('Publier', EgcColors.ok, () => _fs.adminUpdateArticle(a.id, {'status': 'published'})),
                const SizedBox(width: 8),
                if (a.status != 'rejected') _aBtn('Refuser', EgcColors.err, () => _fs.adminUpdateArticle(a.id, {'status': 'rejected'})),
              ]),
            ]));
        });
    });

  // ── IMAGES ───────────────────────────────────────────────────────
  Widget _imagesTab() => StreamBuilder(
    stream: _fs.allArticles(),
    builder: (ctx, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: EgcColors.primary));
      final arts = snap.data!.where((a) => a.imageUrl == null).toList();
      return ListView.separated(padding: const EdgeInsets.all(12), itemCount: arts.length, separatorBuilder: (_,__) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final a = arts[i];
          final ctrl = TextEditingController();
          return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
              Text('${a.shopName} · ${fmtPrice(a.price)}', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
              const SizedBox(height: 10),
              EgcTextField(label: 'Lien image (Cloudinary, ImgBB...)', controller: ctrl, hint: 'https://...'),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.isEmpty) return;
                  await _fs.adminUpdateArticle(a.id, {'imageUrl': ctrl.text.trim(), 'status': 'published'});
                  if (ctx.mounted) showSnack(ctx, 'Image enregistrée et article publié ✓');
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                child: const Text('Enregistrer et Publier'),
              )),
            ]));
        });
    });

  // ── VENDEURS ─────────────────────────────────────────────────────
  Widget _vendeursTab() => StreamBuilder(
    stream: _fs.allVendeurs(),
    builder: (ctx, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: EgcColors.primary));
      return ListView.separated(padding: const EdgeInsets.all(12), itemCount: snap.data!.length, separatorBuilder: (_,__) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final v = snap.data![i];
          return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Row(children: [
              CircleAvatar(radius: 20, backgroundColor: EgcColors.primaryBg, child: Text(v.initials, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.primary))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                Text('${v.email} · ${v.city}', style: const TextStyle(fontSize: 11, color: EgcColors.ink3), overflow: TextOverflow.ellipsis),
                StatusPill(v.planStatus, labels: kPlanStatus),
              ])),
              if (v.planStatus != 'active') TextButton(
                onPressed: () => _fs.adminActivateUser(v.uid, 'vendeurs'),
                child: const Text('Activer', style: TextStyle(color: EgcColors.ok, fontWeight: FontWeight.w700))),
            ]));
        });
    });

  // ── COMMANDES ────────────────────────────────────────────────────
  Widget _ordersTab() => StreamBuilder(
    stream: _fs.allOrders(),
    builder: (ctx, snap) {
      if (snap.hasError) return Center(child: Text('Erreur: \${snap.error}', style: const TextStyle(color: EgcColors.err)));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: EgcColors.primary));
      final orders = snap.data!;
      if (orders.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('📭', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text('Aucune commande', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ]));
      return ListView.separated(padding: const EdgeInsets.all(12), itemCount: orders.length, separatorBuilder: (_,__) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final o = orders[i];
          return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('#${o.orderId.substring(0, 14)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                const Spacer(),
                StatusPill(o.status, labels: kOrderStatus),
              ]),
              const SizedBox(height: 4),
              Text('${o.delivery.name} · ${o.delivery.city} · ${fmtPrice(o.subtotal)}', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
              const SizedBox(height: 8),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                ...['processing','shipped','delivered','cancelled']
                  .where((s) => s != o.status)
                  .map((s) => Padding(padding: const EdgeInsets.only(right: 6),
                    child: _aBtn(kOrderStatus[s] ?? s, statusColor(s), () => _fs.adminUpdateOrderStatus(o.id, s)))),
              ])),
            ]));
        });
    });

  // ── RETRAITS ─────────────────────────────────────────────────────
  Widget _withdrawalsTab() => StreamBuilder(
    stream: _fs.allWithdrawals(),
    builder: (ctx, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: EgcColors.primary));
      return ListView.separated(padding: const EdgeInsets.all(12), itemCount: snap.data!.length, separatorBuilder: (_,__) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final w = snap.data![i];
          return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                  Text('${w.method.toUpperCase()} — ${w.account}  ·  ${fmtPrice(w.amount)}', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
                ])),
                StatusPill(w.status, labels: kWithdrawalStatus),
              ]),
              if (w.status == 'pending') ...[
                const SizedBox(height: 10),
                Row(children: [
                  _aBtn('Approuver', EgcColors.ok, () => _fs.adminApproveWithdrawal(w.id)),
                  const SizedBox(width: 8),
                  _aBtn('Refuser', EgcColors.err, () => _fs.adminRejectWithdrawal(w.id, w.userId, w.amount)),
                ]),
              ],
            ]));
        });
    });

  Widget _aBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: EgcRadius.pill, border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))));
}
