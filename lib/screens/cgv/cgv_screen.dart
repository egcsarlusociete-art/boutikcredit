import '../../models/credit_category.dart' as cc;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';


class CgvScreen extends ConsumerStatefulWidget {
  final bool isRequired; // true = première connexion, false = consultation
  const CgvScreen({super.key, this.isRequired = false});
  @override
  ConsumerState<CgvScreen> createState() => _CgvScreenState();
}

class _CgvScreenState extends ConsumerState<CgvScreen> {
  final _scroll = ScrollController();
  bool _hasScrolledToEnd = false;
  bool _accepted = false;
  bool _signing = false;
  double _scrollProgress = 0;
  bool _alreadySigned = false;
  DateTime? _signedAt;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _checkIfAlreadySigned();
  }

  Future<void> _checkIfAlreadySigned() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      var snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snap.exists) snap = await FirebaseFirestore.instance.collection('vendeurs').doc(uid).get();
      if (snap.exists && snap.data()?['cgvAccepted'] == true) {
        final ts = snap.data()?['cgvSignedAt'];
        setState(() {
          _alreadySigned = true;
          if (ts != null) _signedAt = (ts as dynamic).toDate();
        });
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final cur = _scroll.offset;
    setState(() {
      _scrollProgress = max > 0 ? (cur / max).clamp(0.0, 1.0) : 0;
      if (cur >= max * 0.92) _hasScrolledToEnd = true;
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  Future<void> _sign() async {
    if (!_accepted) {
      showSnack(context, 'Veuillez cocher la case pour accepter les CGV', isError: true);
      return;
    }
    setState(() => _signing = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'cgvAccepted': true,
        'cgvSignedAt': FieldValue.serverTimestamp(),
        'cgvVersion': '1.0',
      }).catchError((_) async {
        await FirebaseFirestore.instance.collection('vendeurs').doc(uid).update({
          'cgvAccepted': true,
          'cgvSignedAt': FieldValue.serverTimestamp(),
          'cgvVersion': '1.0',
        });
      });
      if (mounted) {
        showSnack(context, 'CGV signées électroniquement ✓');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.bg2,
      appBar: AppBar(
        title: const Text('Conditions Générales'),
        leading: widget.isRequired
          ? null
          : IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text(
              '${(_scrollProgress * 100).toInt()}% lu',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: _hasScrolledToEnd ? EgcColors.ok : EgcColors.ink3),
            )),
          ),
        ],
      ),
      body: Column(children: [
        // Barre de progression lecture
        LinearProgressIndicator(
          value: _scrollProgress,
          backgroundColor: EgcColors.bg3,
          valueColor: AlwaysStoppedAnimation<Color>(
            _hasScrolledToEnd ? EgcColors.ok : EgcColors.primary),
          minHeight: 3,
        ),
        // Bannière si obligatoire
        if (widget.isRequired)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: EgcColors.primaryBg,
            child: const Text(
              '📋 Veuillez lire et signer les CGV pour accéder à l\'application.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        // Contenu CGV
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            children: [
              _header(),
              _article('1', 'Modification de commande',
                'L\'utilisateur a la possibilité de modifier sa commande une seule fois après validation, notamment en remplaçant un article par un autre. Cette modification est définitive : aucune autre modification ou remplacement ne sera possible par la suite.',
                warning: 'Modification définitive — aucune autre modification possible après coup.'),
              _article('2', 'Création du compte et choix de catégorie',
                'Lors de la création de son compte, l\'utilisateur doit choisir une catégorie de compte. Celle-ci détermine le plafond maximal de la valeur totale des articles qu\'il peut commander.'),
              _article('3', 'Frais de création de compte',
                'La création d\'un compte sur la plateforme est soumise au paiement d\'un abonnement annuel :',
                extra: _feesWidget()),
              _article('4', 'Modalités de paiement',
                'Tous les paiements se font exclusivement via Mobile Money (Orange Money, MTN MoMo, Moov Money, Wave). Les détails et instructions de paiement sont indiqués dans l\'application. Aucun paiement en espèces ou par virement bancaire n\'est accepté.'),
              _article('5', 'Changement de catégorie',
                'Le passage d\'une catégorie à une autre est possible et sera facturé 1 000 FCFA. La demande doit être formulée via l\'application. Le changement prend effet après validation par l\'équipe EGC-SARLU.',
                info: 'Frais de changement de catégorie : 1 000 FCFA.'),
              _article('6', 'Catégories de comptes et tableau des plafonds',
                'Les catégories sont définies selon le plafond de budget. Chaque catégorie inclut un intérêt fixe de 15 % sur le plafond. La durée de remboursement est définie par groupe de catégories.',
                extra: _categoryTable()),
              _article('7', 'Pénalités en cas de non-paiement',
                'En cas de non-respect des échéances constaté pendant deux (2) semaines consécutives, la société se réserve le droit de procéder à la récupération des articles commandés. Les paiements déjà versés seront remboursés après déduction d\'une pénalité de 50 %. Aucune autre réclamation ne sera acceptée.',
                warning: 'Pénalité de 50 % sur les versements effectués en cas de récupération des articles.'),
              _article('8', 'Assurance optionnelle',
                'L\'utilisateur peut souscrire à une assurance optionnelle couvrant les risques de décès ou de perte d\'emploi. En cas de décès, la dette restante est soldée automatiquement. Les conditions et tarifs sont précisés dans l\'application.',
                info: 'Assurance recommandée pour les catégories C et au-delà.'),
              _article('9', 'Rééchelonnement de dette',
                'En cas de difficultés avérées et justifiées, l\'utilisateur pourra demander une seule fois par an un rééchelonnement de sa dette. Cette demande sera étudiée au cas par cas dans un délai de 5 jours ouvrables. EGC-SARLU se réserve le droit d\'accepter ou de refuser sans obligation de motiver.'),
              _article('10', 'Propriété des biens',
                'Les articles commandés restent la propriété exclusive de la société jusqu\'au paiement intégral du montant total (capital + intérêts). L\'utilisateur ne peut ni les revendre, ni les céder, ni les mettre en gage avant le remboursement complet.',
                warning: 'Les articles restent propriété d\'EGC-SARLU jusqu\'au paiement intégral.'),
              _article('11', 'Livraison',
                'La livraison des articles est effectuée dans un délai raisonnable après validation de la commande. Les frais de livraison sont à la charge de l\'utilisateur et indiqués avant la validation. L\'utilisateur doit être présent ou mandater une personne pour réceptionner la livraison.'),
              _article('12', 'Garantie des articles',
                'Les articles bénéficient d\'une garantie constructeur ou commerciale selon le vendeur. En cas de défaut, l\'utilisateur doit contacter le service client dans les 7 jours suivant la réception. Passé ce délai, aucune réclamation relative à la conformité ne sera acceptée.'),
              _article('13', 'Engagement de l\'utilisateur',
                'L\'utilisateur s\'engage à avoir pris connaissance intégralement des présentes CGV, à les accepter sans réserve, à fournir des informations exactes et à respecter l\'ensemble des obligations financières stipulées. La signature électronique dans l\'application vaut engagement contractuel.'),
              _article('14', 'Droit applicable et litiges',
                'Les présentes conditions sont soumises au droit ivoirien. En cas de litige, les parties rechercheront en premier lieu une solution amiable sous 30 jours. À défaut, tout différend sera soumis aux tribunaux compétents d\'Abidjan, Côte d\'Ivoire.',
                info: 'Droit ivoirien applicable — Tribunaux d\'Abidjan compétents.'),
              const SizedBox(height: 24),
            ],
          ),
        ),
        // Zone de signature
        _signatureZone(),
      ]),
    );
  }

  // ── WIDGETS ────────────────────────────────────────────────────────

  Widget _header() => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: EgcColors.primary, borderRadius: EgcRadius.lgBorder),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('EGC-SARLU', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
      const SizedBox(height: 4),
      const Text('Conditions Générales de Vente\net d\'Utilisation à Crédit', style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4)),
      const SizedBox(height: 12),
      Row(children: [
        _hdChip('Version 1.0'),
        const SizedBox(width: 8),
        _hdChip('Abidjan, Côte d\'Ivoire'),
      ]),
    ]),
  );

  Widget _hdChip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: EgcRadius.pill),
    child: Text(t, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
  );

  Widget _article(String num, String title, String body, {String? warning, String? info, Widget? extra}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder,
        border: Border.all(color: EgcColors.line, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Titre
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(color: EgcColors.bg3,
            borderRadius: const BorderRadius.only(topLeft: EgcRadius.md, topRight: EgcRadius.md)),
          child: Row(children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(color: EgcColors.primary, borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text(num, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)))),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink))),
          ]),
        ),
        // Corps
        Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(body, style: const TextStyle(fontSize: 13, color: EgcColors.ink2, height: 1.7)),
          if (extra != null) ...[const SizedBox(height: 12), extra],
          if (warning != null) ...[const SizedBox(height: 10), _notice(warning, isWarning: true)],
          if (info != null) ...[const SizedBox(height: 10), _notice(info, isWarning: false)],
        ])),
      ]),
    );

  Widget _notice(String text, {required bool isWarning}) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: isWarning ? EgcColors.primaryBg : EgcColors.okBg,
      borderRadius: EgcRadius.smBorder,
      border: Border.all(color: isWarning ? EgcColors.primaryMid : EgcColors.okLine)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(isWarning ? '⚠️' : 'ℹ️', style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: isWarning ? const Color(0xFF92400E) : EgcColors.ok, height: 1.5, fontWeight: FontWeight.w600))),
    ]),
  );

  Widget _feesWidget() => Row(children: [
    Expanded(child: _feeCard('Client', '3 500 FCFA', 'Valable 1 an\nBoutique, commandes,\ncashback, parrainage')),
    const SizedBox(width: 10),
    Expanded(child: _feeCard('Marchand', '5 500 FCFA', 'Valable 1 an\nEspace vendeur,\n1 000 articles max')),
  ]);

  Widget _feeCard(String type, String price, String desc) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.smBorder,
      border: Border.all(color: EgcColors.primaryMid)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EgcColors.ink3)),
      const SizedBox(height: 4),
      Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: EgcColors.primary, letterSpacing: -0.4)),
      const SizedBox(height: 4),
      Text(desc, style: const TextStyle(fontSize: 10, color: EgcColors.ink3, height: 1.5)),
    ]),
  );

  Widget _categoryTable() => Column(children: [
    Container(
      decoration: BoxDecoration(borderRadius: EgcRadius.smBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
      child: ClipRRect(
        borderRadius: EgcRadius.smBorder,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(horizontalInside: BorderSide(color: EgcColors.line, width: 1)),
            children: [
              // En-tête
              TableRow(
                decoration: const BoxDecoration(color: EgcColors.primary),
                children: ['Cat.', 'Plafond', 'Intérêts', 'Total dû', 'Durée', '/Jour', '/Semaine']
                  .map((h) => Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(h, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.right))).toList()
              ),
              // Lignes
              ...List.generate(cc.kCategories.length, (i) {
                final cat = cc.kCategories[i];
                final bg = i.isEven ? EgcColors.bg2 : EgcColors.primaryBg;
                return TableRow(decoration: BoxDecoration(color: bg), children: [
                  _tcell(cat.id, bold: true),
                  _tcell(fmtPrice(cat.plafond)),
                  _tcell(fmtPrice(cat.interets)),
                  _tcell(fmtPrice(cat.total), color: EgcColors.primary, bold: true),
                  _tcell(cat.dureeLabel),
                  _tcell(fmtPrice(cat.paiementJour), color: EgcColors.ok, bold: true),
                  _tcell(fmtPrice(cat.paiementSemaine)),
                ]);
              }),
            ],
          ),
        ),
      ),
    ),
    const SizedBox(height: 8),
    const Text('* Paiements journaliers et hebdomadaires indicatifs. Intérêt fixe de 15 % sur le plafond.',
      style: TextStyle(fontSize: 10, color: EgcColors.ink3, height: 1.4)),
  ]);

  Widget _tcell(String t, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: Text(t, style: TextStyle(fontSize: 10, fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: color ?? EgcColors.ink2, height: 1.3), textAlign: TextAlign.right));

  Widget _signatureZone() {
    if (_alreadySigned) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EgcColors.okBg,
          borderRadius: EgcRadius.mdBorder,
          border: Border.all(color: EgcColors.okLine, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.verified, color: EgcColors.ok, size: 22),
            SizedBox(width: 8),
            Text('CGV déjà acceptées', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: EgcColors.ok)),
          ]),
          const SizedBox(height: 8),
          Text(
            _signedAt != null
              ? 'Vous avez signé les CGV le ${fmtDate(_signedAt)} à ${_signedAt!.hour.toString().padLeft(2,'0')}h${_signedAt!.minute.toString().padLeft(2,'0')}.'
              : 'Vous avez déjà accepté les Conditions Générales.',
            style: const TextStyle(fontSize: 13, color: EgcColors.ok, height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text('Vous pouvez consulter les conditions à tout moment depuis cette page.', style: TextStyle(fontSize: 12, color: EgcColors.ink3, height: 1.5)),
        ]),
      );
    }
    return Container(
    decoration: const BoxDecoration(
      color: EgcColors.bg2,
      border: Border(top: BorderSide(color: EgcColors.line, width: 1.5))),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Message si pas encore lu tout
      if (!_hasScrolledToEnd)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            const Text('📖', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Faites défiler jusqu\'à la fin pour pouvoir signer.',
              style: const TextStyle(fontSize: 11, color: EgcColors.ink3, fontWeight: FontWeight.w500),
            )),
            Text('${(_scrollProgress * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EgcColors.primary)),
          ]),
        ),
      // Checkbox acceptation
      GestureDetector(
        onTap: _hasScrolledToEnd ? () => setState(() => _accepted = !_accepted) : null,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20, height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: _accepted ? EgcColors.primary : Colors.transparent,
              border: Border.all(color: _accepted ? EgcColors.primary : (_hasScrolledToEnd ? EgcColors.line2 : EgcColors.bg3), width: 1.5),
              borderRadius: BorderRadius.circular(5)),
            child: _accepted ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'J\'ai lu, compris et j\'accepte les Conditions Générales de Vente et d\'Utilisation à Crédit d\'EGC-SARLU, incluant les modalités de remboursement et les pénalités applicables.',
            style: TextStyle(fontSize: 12, color: _hasScrolledToEnd ? EgcColors.ink2 : EgcColors.ink3, height: 1.5),
          )),
        ]),
      ),
      const SizedBox(height: 12),
      // Bouton signer
      SizedBox(
        width: double.infinity, height: 48,
        child: ElevatedButton(
          onPressed: (_accepted && !_signing) ? _sign : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accepted ? EgcColors.ok : EgcColors.bg3,
            shape: RoundedRectangleBorder(borderRadius: EgcRadius.mdBorder),
          ),
          child: _signing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.draw_outlined, size: 18, color: _accepted ? Colors.white : EgcColors.ink3),
                const SizedBox(width: 8),
                Text('Signer électroniquement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _accepted ? Colors.white : EgcColors.ink3)),
              ]),
        ),
      ),
      const SizedBox(height: 6),
      Center(child: Text(
        'La signature est horodatée et enregistrée de façon sécurisée dans Firebase.',
        style: const TextStyle(fontSize: 10, color: EgcColors.ink3),
        textAlign: TextAlign.center,
      )),
      const SizedBox(height: 8),
    ])),
  );
}
}
