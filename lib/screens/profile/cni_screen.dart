import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/theme.dart';

class CniScreen extends StatefulWidget {
  const CniScreen({super.key});
  @override
  State<CniScreen> createState() => _CniScreenState();
}

class _CniScreenState extends State<CniScreen> {
  String? _rectoB64;
  String? _versoB64;
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
    DocumentSnapshot snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!snap.exists) snap = await FirebaseFirestore.instance.collection('vendeurs').doc(uid).get();
    if (snap.exists) {
      final d = snap.data() as Map<String, dynamic>;
      setState(() {
        _rectoB64 = d['cniRectoB64'];
        _versoB64 = d['cniVersoB64'];
      });
    }
  }

  Future<void> _takePicture(bool isRecto) async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 40, maxWidth: 800);
    if (picked == null) return;
    setState(() => isRecto ? _loadingRecto = true : _loadingVerso = true);
    try {
      final bytes = await File(picked.path).readAsBytes();
      final b64 = base64Encode(bytes);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final uSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final coll = uSnap.exists ? 'users' : 'vendeurs';
      await FirebaseFirestore.instance.collection(coll).doc(uid).update({
        isRecto ? 'cniRectoB64' : 'cniVersoB64': b64,
        isRecto ? 'cniRecto' : 'cniVerso': true,
        'cniUpdatedAt': FieldValue.serverTimestamp(),
      });
      setState(() => isRecto ? _rectoB64 = b64 : _versoB64 = b64);
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
              Expanded(child: Text('Article 15 — Vérification identité', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EgcColors.primary))),
            ]),
            SizedBox(height: 6),
            Text('Photographiez recto et verso de votre CNI. Photos sécurisées, visibles uniquement par administration.', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
          ]),
        ),
        const SizedBox(height: 20),
        _CniCard(label: 'Recto', icon: Icons.credit_card, imageB64: _rectoB64, loading: _loadingRecto, onTake: () => _takePicture(true)),
        const SizedBox(height: 16),
        _CniCard(label: 'Verso', icon: Icons.credit_card_outlined, imageB64: _versoB64, loading: _loadingVerso, onTake: () => _takePicture(false)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (_rectoB64 != null && _versoB64 != null) ? EgcColors.okBg : EgcColors.goldBg,
            borderRadius: EgcRadius.mdBorder,
            border: Border.all(color: (_rectoB64 != null && _versoB64 != null) ? EgcColors.ok : EgcColors.gold),
          ),
          child: Row(children: [
            Icon((_rectoB64 != null && _versoB64 != null) ? Icons.check_circle_outline : Icons.hourglass_empty,
              color: (_rectoB64 != null && _versoB64 != null) ? EgcColors.ok : EgcColors.gold),
            const SizedBox(width: 10),
            Expanded(child: Text(
              (_rectoB64 != null && _versoB64 != null) ? 'CNI complète ✅' : 'En attente — photographiez les deux faces',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: (_rectoB64 != null && _versoB64 != null) ? EgcColors.ok : EgcColors.gold),
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
  final String? imageB64;
  final bool loading;
  final VoidCallback onTake;
  const _CniCard({required this.label, required this.icon, this.imageB64, required this.loading, required this.onTake});

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
            if (imageB64 != null) const Icon(Icons.check_circle, color: EgcColors.ok, size: 20),
          ]),
        ),
        if (loading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: EgcColors.primary))
        else if (imageB64 != null) ...[
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            child: Image.memory(base64Decode(imageB64!), width: double.infinity, height: 180, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextButton.icon(onPressed: onTake, icon: const Icon(Icons.camera_alt_outlined, size: 16), label: const Text('Reprendre')),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: onTake,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: Text('Photographier $label'),
            )),
          ),
      ]),
    );
  }
}
