import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/theme.dart';
import '../../widgets/common.dart';

class CniScreen extends StatefulWidget {
  const CniScreen({super.key});
  @override
  State<CniScreen> createState() => _CniScreenState();
}

class _CniScreenState extends State<CniScreen> {
  String? _rectoPath;
  String? _versoPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rectoPath = prefs.getString('cni_recto');
      _versoPath = prefs.getString('cni_verso');
    });
  }

  Future<void> _takePicture(bool isRecto) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (isRecto) {
      await prefs.setString('cni_recto', picked.path);
      setState(() => _rectoPath = picked.path);
    } else {
      await prefs.setString('cni_verso', picked.path);
      setState(() => _versoPath = picked.path);
    }
    if (mounted) showSnack(context, isRecto ? 'Recto enregistré ✅' : 'Verso enregistré ✅');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Vérification CNI')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Info banner
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
            Text('Prenez en photo le recto et le verso de votre CNI. Les photos sont stockées uniquement sur votre téléphone.', style: TextStyle(fontSize: 12, color: EgcColors.ink3)),
          ]),
        ),
        const SizedBox(height: 20),

        // Recto
        _CniCard(
          label: 'Recto de la CNI',
          icon: Icons.credit_card,
          imagePath: _rectoPath,
          onTake: () => _takePicture(true),
          onRetake: () => _takePicture(true),
        ),
        const SizedBox(height: 16),

        // Verso
        _CniCard(
          label: 'Verso de la CNI',
          icon: Icons.credit_card_outlined,
          imagePath: _versoPath,
          onTake: () => _takePicture(false),
          onRetake: () => _takePicture(false),
        ),
        const SizedBox(height: 24),

        // Statut
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (_rectoPath != null && _versoPath != null) ? EgcColors.okBg : EgcColors.goldBg,
            borderRadius: EgcRadius.mdBorder,
            border: Border.all(color: (_rectoPath != null && _versoPath != null) ? EgcColors.ok : EgcColors.gold),
          ),
          child: Row(children: [
            Icon(
              (_rectoPath != null && _versoPath != null) ? Icons.check_circle_outline : Icons.hourglass_empty,
              color: (_rectoPath != null && _versoPath != null) ? EgcColors.ok : EgcColors.gold,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(
              (_rectoPath != null && _versoPath != null)
                  ? 'CNI complète — Vérification effectuée ✅'
                  : 'En attente — Veuillez photographier les deux faces de votre CNI',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: (_rectoPath != null && _versoPath != null) ? EgcColors.ok : EgcColors.gold,
              ),
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
  final String? imagePath;
  final VoidCallback onTake;
  final VoidCallback onRetake;

  const _CniCard({required this.label, required this.icon, this.imagePath, required this.onTake, required this.onRetake});

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
            if (imagePath != null) const Icon(Icons.check_circle, color: EgcColors.ok, size: 20),
          ]),
        ),
        if (imagePath != null) ...[
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            child: Image.file(File(imagePath!), width: double.infinity, height: 180, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextButton.icon(
              onPressed: onRetake,
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('Reprendre la photo'),
            ),
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
