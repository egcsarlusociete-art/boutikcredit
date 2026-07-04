import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/theme.dart';

class CniScreen extends StatefulWidget {
  const CniScreen({super.key});
  @override
  State<CniScreen> createState() => _CniScreenState();
}

class _CniScreenState extends State<CniScreen> {
  String? _rectoUrl;
  String? _versoUrl;
  bool _loadingRecto = false;
  bool _loadingVerso = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final uSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (uSnap.exists) {
      final d = uSnap.data() as Map<String, dynamic>;
      setState(() {
        _rectoUrl = d['cniRectoUrl'];
        _versoUrl = d['cniVersoUrl'];
      });
      return;
    }
    final vSnap = await FirebaseFirestore.instance.collection('vendeurs').doc(uid).get();
    if (vSnap.exists) {
      final d = vSnap.data() as Map<String, dynamic>;
      setState(() {
        _rectoUrl = d['cniRectoUrl'];
        _versoUrl = d['cniVersoUrl'];
      });
    }
  }

  Future<void> _takePicture(bool isRecto) async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked == null) return;

    setState(() => isRecto ? _loadingRecto = true : _loadingVerso = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final fileName = isRecto ? 'cni_recto_$uid.jpg' : 'cni_verso_$uid.jpg';
      final ref = FirebaseStorage.instance.ref().child('cni/$uid/$fileName');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      // Mettre à jour Firestore
      final uSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final coll = uSnap.exists ? 'users' : 'vendeurs';
      await FirebaseFirestore.instance.collection(coll).doc(uid).update({
        isRecto ? 'cniRectoUrl' : 'cniVersoUrl': url,
        isRecto ? 'cniRecto' : 'cniVerso': true,
        'cniUpdatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => isRecto ? _rectoUrl = url : _versoUrl = url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isRecto ? 'Recto enregistré ✅' : 'Verso enregistré ✅'), backgroundColor: EgcColors.ok));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: EgcColors.err));
    } finally {
      setState(() => isRecto ? _loadingRecto = false : _loadingVerso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Vérification CNI')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: EgcColors.primaryBg, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.primaryMid)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline, color: EgcColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Article 15 — Vérification d\'identité', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EgcColors.primary)),
            ]),
            SizedBox(height: 6),
            Text('Prenez en photo le recto et le verso de votre CNI. Les photos sont sécurisées et accessibles uniquement par l\'administration.', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
          ]),
        ),
        const SizedBox(height: 20),
        _CniCard(label: 'Recto de la CNI', icon: Icons.credit_card, imageUrl: _rectoUrl, loading: _loadingRecto, onTake: () => _takePicture(true)),
        const SizedBox(height: 16),
        _CniCard(label: 'Verso de la CNI', icon: Icons.credit_card_outlined, imageUrl: _versoUrl, loading: _loadingVerso, onTake: () => _takePicture(false)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (_rectoUrl != null && _versoUrl != null) ? EgcColors.okBg : EgcColors.goldBg,
            borderRadius: EgcRadius.mdBorder,
            border: Border.all(color: (_rectoUrl != null && _versoUrl != null) ? EgcColors.ok : EgcColors.gold),
          ),
          child: Row(children: [
            Icon((_rectoUrl != null && _versoUrl != null) ? Icons.check_circle_outline : Icons.hourglass_empty,
              color: (_rectoUrl != null && _versoUrl != null) ? EgcColors.ok : EgcColors.gold),
            const SizedBox(width: 10),
            Expanded(child: Text(
              (_rectoUrl != null && _versoUrl != null)
                ? 'CNI complète — Vérification effectuée ✅'
                : 'En attente — Veuillez photographier les deux faces de votre CNI',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: (_rectoUrl != null && _versoUrl != null) ? EgcColors.ok : EgcColors.gold),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _CniCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? imageUrl;
  final bool loading;
  final VoidCallback onTake;

  const _CniCard({required this.label, required this.icon, this.imageUrl, required this.loading, required this.onTake});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(icon, color: EgcColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EgcColors.ink)),
            const Spacer(),
            if (imageUrl != null) const Icon(Icons.check_circle, color: EgcColors.ok, size: 20),
          ]),
        ),
        if (loading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: EgcColors.primary))
        else if (imageUrl != null) ...[
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            child: Image.network(imageUrl!, width: double.infinity, height: 180, fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: EgcColors.primary))),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextButton.icon(onPressed: onTake, icon: const Icon(Icons.camera_alt_outlined, size: 16), label: const Text('Reprendre la photo')),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: onTake,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: Text('Photographier le $label'),
            )),
          ),
      ]),
    );
  }
}
