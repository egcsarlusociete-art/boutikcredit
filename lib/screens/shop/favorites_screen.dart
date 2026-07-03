import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/article_model.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(title: const Text('Mes Favoris')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: EgcColors.primary));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('❤️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Aucun favori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EgcColors.ink)),
            const SizedBox(height: 4),
            const Text('Ajoutez des articles à vos favoris', style: TextStyle(fontSize: 13, color: EgcColors.ink3)),
          ]));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final favId = docs[i].id;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('articles').doc(d['articleId']).get(),
                builder: (ctx, artSnap) {
                  if (!artSnap.hasData || !artSnap.data!.exists) return const SizedBox.shrink();
                  final a = ArticleModel.fromFirestore(artSnap.data!);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: EgcColors.line)),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8),
                        child: a.hasImage ? Image.network(a.imageUrl!, width: 60, height: 60, fit: BoxFit.cover) : Container(width: 60, height: 60, color: EgcColors.bg3, child: const Center(child: Text('📦')))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EgcColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(a.shopName, style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                        Text(fmtPrice(a.price), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EgcColors.primary)),
                      ])),
                      Column(children: [
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('favorites').doc(favId).delete();
                            if (context.mounted) showSnack(context, 'Retiré des favoris');
                          },
                        ),
                        TextButton(
                          onPressed: () => context.push('/article/${a.id}'),
                          child: const Text('Voir', style: TextStyle(fontSize: 12)),
                        ),
                      ]),
                    ]),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
