import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/providers.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    final referralsAsync = ref.watch(referralsProvider);

    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Parrainage')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
        error: (e, _) => const Center(child: Text('Erreur')),
        data: (user) {
          if (user == null) return const Center(child: Text('Non connecté'));
          final code = user.referralCode;
          final link = 'https://boutikcredit-egcsarlu.web.app/?ref=$code';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EgcColors.primary,
                  borderRadius: EgcRadius.mdBorder,
                ),
                child: Column(children: [
                  const Text('🎁', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  const Text('Parrainez vos proches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('Gagnez 500 F CFA par filleul inscrit', style: TextStyle(fontSize: 13, color: Colors.white70)),
                ]),
              ),

              const SizedBox(height: 20),

              // QR Code
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EgcColors.bg2,
                  borderRadius: EgcRadius.mdBorder,
                  border: Border.all(color: EgcColors.line, width: 1.5),
                ),
                child: Column(children: [
                  const Text('Mon QR Code personnel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                  const SizedBox(height: 4),
                  const Text('Vos filleuls scannent ce code pour s\'inscrire', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
                  const SizedBox(height: 16),
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: EgcRadius.mdBorder,
                      border: Border.all(color: EgcColors.line, width: 1.5),
                    ),
                    child: QrImageView(
                      data: link,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Code texte
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: EgcColors.primaryBg,
                      borderRadius: EgcRadius.pill,
                      border: Border.all(color: EgcColors.primaryMid),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.tag, size: 16, color: EgcColors.primary),
                      const SizedBox(width: 6),
                      Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: EgcColors.primary, letterSpacing: 2)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Boutons partage
                  Row(children: [
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () => Share.share(
                        'Rejoignez BoutikCredit et commandez à crédit sans apport !\n'
                        'Utilisez mon code : $code\n'
                        'Lien : $link'
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Partager'),
                      style: ElevatedButton.styleFrom(backgroundColor: EgcColors.primary, minimumSize: const Size(double.infinity, 46)),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () {
                        // Copier le lien
                        showSnack(context, '✅ Lien copié !');
                      },
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: const Text('Copier'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
                    )),
                  ]),
                ]),
              ),

              const SizedBox(height: 16),

              // Statistiques
              Row(children: [
                Expanded(child: _statCard('👥', referralsAsync.when(
                  data: (r) => '${r.length}',
                  loading: () => '...',
                  error: (_, __) => '0',
                ), 'Filleuls')),
                const SizedBox(width: 12),
                Expanded(child: _statCard('💰', fmtPrice(referralsAsync.when(
                  data: (r) => r.length * 500.0,
                  loading: () => 0.0,
                  error: (_, __) => 0.0,
                )), 'Gains parrainage')),
              ]),

              const SizedBox(height: 16),

              // Liste filleuls
              referralsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
                error: (_, __) => const SizedBox.shrink(),
                data: (referrals) {
                  if (referrals.isEmpty) return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line)),
                    child: const Center(child: Column(children: [
                      Text('👥', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text('Aucun filleul pour l\'instant', style: TextStyle(fontWeight: FontWeight.w700, color: EgcColors.ink)),
                      SizedBox(height: 4),
                      Text('Partagez votre QR Code pour commencer', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
                    ])),
                  );
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Mes filleuls', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                    const SizedBox(height: 8),
                    ...referrals.map((r) => FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(r.referredId).get().then((s) => s.exists ? s : FirebaseFirestore.instance.collection('vendeurs').doc(r.referredId).get()),
                      builder: (ctx, snap) {
                        String statut = 'En attente';
                        Color statutColor = EgcColors.primary;
                        Color statutBg = EgcColors.primaryBg;
                        if (snap.hasData && snap.data!.exists) {
                          final ps = (snap.data!.data() as Map<String, dynamic>?)?['planStatus'] ?? 'pending';
                          if (ps == 'active') { statut = 'Validé ✓'; statutColor = EgcColors.ok; statutBg = EgcColors.okBg; }
                          else if (ps == 'suspended') { statut = 'Refusé'; statutColor = EgcColors.err; statutBg = const Color(0xFFFEE2E2); }
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line)),
                          child: Row(children: [
                            CircleAvatar(radius: 20, backgroundColor: EgcColors.primaryMid,
                              child: Text(r.name.isNotEmpty ? r.name[0].toUpperCase() : 'U',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: EgcColors.primary))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink)),
                              Text(fmtDate(r.createdAt), style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                              const SizedBox(height: 3),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: statutBg, borderRadius: EgcRadius.pill),
                                child: Text(statut, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statutColor))),
                            ])),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: EgcColors.okBg, borderRadius: EgcRadius.pill),
                              child: const Text('+500 F', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EgcColors.ok))),
                          ]),
                        );
                      },
                    )),
                  ]);
                },
              ),

              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 28)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: EgcColors.ink)),
      Text(label, style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
    ]),
  );
}
