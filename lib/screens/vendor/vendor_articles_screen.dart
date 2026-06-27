
import 'package:flutter/material.dart';
import '../../services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/status_pill.dart';
import 'vendor_home_screen.dart';

class VendorArticlesScreen extends ConsumerWidget {
  const VendorArticlesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artsAsync = ref.watch(vendorArticlesProvider);
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Mes articles'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context))),
      body: artsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
        error: (_,__) => const Center(child: Text('Erreur')),
        data: (arts) {
          if (arts.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('📦', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Aucun article', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: arts.length,
            separatorBuilder: (_,__) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final a = arts[i];
              return Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line, width: 1.5)),
                child: Row(children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: EgcColors.bg3, borderRadius: BorderRadius.circular(10)),
                    child: a.hasImage ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(a.imageUrl!, fit: BoxFit.cover)) : const Center(child: Text('📦', style: TextStyle(fontSize: 28)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${kCategories[a.category] ?? a.category} · ${fmtPrice(a.price)}', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
                    const SizedBox(height: 4),
                    Row(children: [
                      StatusPill(a.status, labels: kArticleStatus),
                      const SizedBox(width: 8),
                      Text('👁 ${a.views}', style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                    ]),
                  ])),
                  if (!a.hasImage)
                    const Icon(Icons.image_not_supported_outlined, color: EgcColors.ink3, size: 18),
                ]));
            },
          );
        },
      ),
    );
  }
}
